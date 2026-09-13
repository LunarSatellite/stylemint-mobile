import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_origins.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';

/// A few embed players reused across a scrolling reel feed.
///
/// The feed describes what it wants — the reel on screen and its neighbours —
/// and the pool maps that onto slots. The on-screen reel plays, neighbours are
/// cued in the background so a swipe starts at once, and the least recently
/// used slot is recycled when a new reel needs one. At most one reel plays.
class EmbedPlayerPool extends ChangeNotifier {
  EmbedPlayerPool({
    int slotCount = 2,
    Future<EmbedOrigins>? origins,
    this.readyTimeout = const Duration(seconds: 12),
  }) {
    setCapacity(slotCount);
    unawaited(
      (origins ?? EmbedOrigins.resolve()).then((value) {
        if (_disposed) return;
        _origins = value;
        _sync();
        notifyListeners();
      }),
    );
  }

  static const maxSlots = 3;

  /// Failures worth one automatic retry: transient load problems, not a
  /// video that is private or has embedding turned off.
  static const _retryableErrors = {
    'timeout',
    'yt_api_load_failed',
    'fb_sdk_load_failed',
  };

  final Duration readyTimeout;
  final List<EmbedSlot> _slots = [];
  final Set<String> _retried = {};
  EmbedOrigins? _origins;
  EmbedRequest? _active;
  List<EmbedRequest> _neighbours = const [];
  int _capacity = 1;
  int _clock = 0;
  bool _hostActive = true;
  bool _userPaused = false;
  bool _sessionMuted = false;
  bool _disposed = false;

  List<EmbedSlot> get slots => List.unmodifiable(_slots);

  /// Key of the reel on screen, if it is an embedded one.
  String? get activeKey => _active?.key;

  EmbedSlot? get activeSlot {
    final key = activeKey;
    return key == null ? null : slotFor(key);
  }

  /// The viewer paused the on-screen reel.
  bool get userPaused => _userPaused;

  /// Whether the on-screen reel is playing without sound.
  bool get muted => activeSlot?.muted ?? _sessionMuted;

  EmbedSlot? slotFor(String key) {
    for (final slot in _slots) {
      if (slot.key == key) return slot;
    }
    return null;
  }

  /// True when [key]'s embed failed and will not be retried, so the reel
  /// should hand off to its platform instead.
  bool hasGivenUp(String key) {
    final slot = slotFor(key);
    if (slot == null || slot.state != EmbedPlayerState.failed) return false;
    return !_canRetry(key, slot);
  }

  /// Sets how many slots may hold reels, up to [maxSlots]. Slots are created
  /// on demand and never destroyed; lowering the capacity frees players.
  void setCapacity(int count) {
    final target = count.clamp(1, maxSlots);
    while (_slots.length < target) {
      _slots.add(
        EmbedSlot(_slots.length, readyTimeout: readyTimeout)
          ..addListener(_onSlotChanged),
      );
    }
    _capacity = target;
    _sync();
    notifyListeners();
  }

  /// [active] is the reel on screen (null when it is not embedded).
  /// [neighbours] are the reels to cue next, most likely first.
  void setWindow({
    required EmbedRequest? active,
    List<EmbedRequest> neighbours = const [],
  }) {
    if (active?.key != _active?.key) _userPaused = false;
    _active = active;
    _neighbours = [
      for (final n in neighbours)
        if (n.key != active?.key) n,
    ];
    _sync();
    notifyListeners();
  }

  /// Whether the surface showing the reels is visible and the app is in the
  /// foreground. Nothing plays while it is not.
  void setHostActive(bool active) {
    if (_hostActive == active) return;
    _hostActive = active;
    _sync();
    notifyListeners();
  }

  void togglePause() {
    if (_active == null) return;
    _userPaused = !_userPaused;
    _sync();
    notifyListeners();
  }

  /// Turns sound off or on for every reel for the rest of the session.
  void setMuted(bool muted) {
    _sessionMuted = muted;
    for (final slot in _slots) {
      slot.setMuted(muted);
    }
    notifyListeners();
  }

  /// Frees every player except the on-screen one and stops cueing
  /// neighbours. Called when the OS reports memory pressure.
  void trim() => setCapacity(1);

  void _sync() {
    final origins = _origins;
    if (origins == null || _disposed) return;

    final active = _active;
    final play = _hostActive && !_userPaused;
    final wanted = _neighbours.take(math.max(0, _capacity - 1)).toList();
    final keep = <String>{
      if (active != null) active.key,
      for (final n in wanted) n.key,
    };

    // Pause first so two reels never overlap, even for a frame.
    for (final slot in _slots) {
      if (slot.key != null && slot.key != active?.key) slot.pause();
    }

    var inUse = _slots.where((s) => s.key != null).length;
    for (final slot in _slots) {
      if (inUse <= _capacity) break;
      if (slot.key != null && !keep.contains(slot.key)) {
        slot.release();
        inUse--;
      }
    }

    if (active != null) {
      final existing = slotFor(active.key);
      final slot = existing ?? _takeSlot(keep) ?? _takeSlot({active.key});
      if (slot != null) {
        slot.lastUsed = ++_clock;
        if (existing == null) {
          _assign(slot, active, origins, play: play);
        } else if (existing.state == EmbedPlayerState.failed &&
            _canRetry(active.key, existing)) {
          _retried.add(active.key);
          _assign(existing, active, origins, play: play);
        } else if (play) {
          existing.play();
        } else {
          existing.pause();
        }
      }
    }

    for (final neighbour in wanted) {
      if (slotFor(neighbour.key) != null) continue;
      final slot = _takeSlot(keep);
      if (slot == null) break;
      slot.lastUsed = ++_clock;
      _assign(slot, neighbour, origins, play: false);
    }
  }

  /// A free slot while under capacity, otherwise the least recently used
  /// slot whose reel is not in [keep].
  EmbedSlot? _takeSlot(Set<String> keep) {
    final inUse = _slots.where((s) => s.key != null).length;
    EmbedSlot? best;
    for (final slot in _slots) {
      final key = slot.key;
      if (key != null && keep.contains(key)) continue;
      if (key == null && inUse >= _capacity) continue;
      if (best == null) {
        best = slot;
      } else if (best.key != null && key == null) {
        best = slot;
      } else if ((best.key == null) == (key == null) &&
          slot.lastUsed < best.lastUsed) {
        best = slot;
      }
    }
    return best;
  }

  void _assign(
    EmbedSlot slot,
    EmbedRequest request,
    EmbedOrigins origins, {
    required bool play,
  }) {
    slot.assign(
      request,
      origin: origins.forPlatform(request.source.platform),
      play: play,
      muted: _sessionMuted,
    );
  }

  bool _canRetry(String key, EmbedSlot slot) =>
      _retryableErrors.contains(slot.errorCode) && !_retried.contains(key);

  void _onSlotChanged() {
    if (_disposed) return;
    final active = _active;
    final slot = active == null ? null : slotFor(active.key);
    if (active != null &&
        slot != null &&
        slot.state == EmbedPlayerState.failed &&
        _canRetry(active.key, slot)) {
      // Deferred: reassigning notifies the slot's listeners, and this runs
      // inside that notification.
      scheduleMicrotask(_sync);
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final slot in _slots) {
      slot
        ..removeListener(_onSlotChanged)
        ..dispose();
    }
    super.dispose();
  }
}
