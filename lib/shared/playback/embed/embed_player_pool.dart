import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_origins.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_startup_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_warmup.dart';

/// A few embed players reused across a scrolling reel feed.
///
/// The feed describes what it wants — the reel on screen, its neighbours and
/// the reels a little further ahead — and the pool maps that onto slots. The
/// on-screen reel plays; neighbours are loaded in the background (the next
/// one pre-rolled) so a swipe only tells an already-loaded player to play;
/// and the least recently used slot is recycled when a new reel needs one.
/// At most one reel plays. With two slots that is the reel on screen and the
/// next one: the previous reel is dropped.
class EmbedPlayerPool extends ChangeNotifier {
  EmbedPlayerPool({
    int slotCount = 2,
    Future<EmbedOrigins>? origins,
    this.readyTimeout = const Duration(seconds: 12),
    this.startTimeout = const Duration(milliseconds: 2500),
    EmbedStartupMetrics? metrics,
  }) : startupMetrics = metrics ?? EmbedStartupMetrics() {
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

  /// Failures worth one automatic retry with a new player: transient load
  /// and playback problems (TikTok 2001 server error, 3001 playback error),
  /// not a video that is private, gone (TikTok 1001) or has embedding off.
  static const _retryableErrors = {
    'timeout',
    'yt_api_load_failed',
    'fb_sdk_load_failed',
    'tt_2001',
    'tt_3001',
  };

  final Duration readyTimeout;

  /// See [EmbedSlot.startTimeout].
  final Duration startTimeout;

  /// Start-up timings of the reels this pool played.
  final EmbedStartupMetrics startupMetrics;

  final List<EmbedSlot> _slots = [];
  final Set<String> _retried = {};
  EmbedOrigins? _origins;
  EmbedRequest? _active;
  List<EmbedRequest> _neighbours = const [];
  List<EmbedRequest> _upcoming = const [];
  Duration? _lastTikTokWarm;
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
        EmbedSlot(
          _slots.length,
          readyTimeout: readyTimeout,
          startTimeout: startTimeout,
          metrics: startupMetrics,
        )..addListener(_onSlotChanged),
      );
    }
    _capacity = target;
    _sync();
    notifyListeners();
  }

  /// [active] is the reel on screen (null when it is not embedded).
  /// [neighbours] are the reels to load next, most likely first.
  /// [upcoming] are reels a little further ahead: they get no player, but
  /// their platform's connections are warmed (see [EmbedWarmup]).
  void setWindow({
    required EmbedRequest? active,
    List<EmbedRequest> neighbours = const [],
    List<EmbedRequest> upcoming = const [],
  }) {
    if (active?.key != _active?.key) _userPaused = false;
    _active = active;
    _neighbours = [
      for (final n in neighbours)
        if (n.key != active?.key) n,
    ];
    _upcoming = upcoming;
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
    // Slots left after the reel on screen, which only takes one when it is
    // embedded: beside a native reel a two-slot pool loads both neighbours.
    final budget = _capacity - (active == null ? 0 : 1);
    final wanted = _neighbours.take(math.max(0, budget)).toList();
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
      final origin = origins.forPlatform(active.source.platform);
      final existing = slotFor(active.key);
      final slot =
          existing ??
          _takeSlot(keep, origin: origin) ??
          _takeSlot({active.key}, origin: origin);
      if (slot != null) {
        slot.lastUsed = ++_clock;
        if (existing == null) {
          _assign(slot, active, origins, play: play);
        } else if (existing.state == EmbedPlayerState.failed &&
            _canRetry(active.key, existing)) {
          _retried.add(active.key);
          _assign(existing, active, origins, play: play);
        } else if (play) {
          // Already loaded (pre-loaded as a neighbour): no new player, only
          // a play command.
          existing.play();
        } else {
          // The viewer's own pause holds a YouTube reel on its cued
          // thumbnail (see EmbedSlot.pause); a hidden feed just pauses.
          existing.pause(byViewer: _userPaused && _hostActive);
        }
      }
    }

    for (final neighbour in wanted) {
      if (slotFor(neighbour.key) != null) continue;
      final slot = _takeSlot(
        keep,
        origin: origins.forPlatform(neighbour.source.platform),
      );
      if (slot == null) break;
      slot.lastUsed = ++_clock;
      // Only the most likely next reel pre-rolls, and never in the
      // background: one extra muted decode, not one per neighbour.
      _assign(
        slot,
        neighbour,
        origins,
        play: false,
        preroll: _hostActive && identical(neighbour, wanted.first),
      );
    }

    _warmAhead(origins);
  }

  /// A free slot while under capacity, otherwise the least recently used
  /// slot whose reel is not in [keep]. Among equals, a slot whose host page
  /// is already on [origin] wins: it needs no page load.
  EmbedSlot? _takeSlot(Set<String> keep, {String? origin}) {
    final inUse = _slots.where((s) => s.key != null).length;
    EmbedSlot? best;
    for (final slot in _slots) {
      final key = slot.key;
      if (key != null && keep.contains(key)) continue;
      if (key == null && inUse >= _capacity) continue;
      if (best == null || _isBetterSlot(slot, best, origin)) best = slot;
    }
    return best;
  }

  static bool _isBetterSlot(EmbedSlot a, EmbedSlot b, String? origin) {
    final aFree = a.key == null;
    if (aFree != (b.key == null)) return aFree;
    final aOnOrigin = origin != null && a.hostOrigin == origin;
    final bOnOrigin = origin != null && b.hostOrigin == origin;
    if (aOnOrigin != bOnOrigin) return aOnOrigin;
    return a.lastUsed < b.lastUsed;
  }

  /// Opens connections to TikTok's player hosts while a TikTok reel is on
  /// screen or up to two pages away, at most once per [EmbedWarmup.interval].
  /// Runs on a host page on the TikTok origin when there is one, since a
  /// browser may keep connections apart per page.
  void _warmAhead(EmbedOrigins origins) {
    if (!_hostActive) return;
    final ahead = <EmbedRequest>[
      ?_active,
      ..._neighbours,
      ..._upcoming,
    ];
    if (!ahead.any((r) => r.source.platform == SocialPlatform.tiktok)) return;
    final now = startupMetrics.now();
    final last = _lastTikTokWarm;
    if (last != null && now - last < EmbedWarmup.interval) return;
    final tikTokOrigin = origins.forPlatform(SocialPlatform.tiktok);
    EmbedSlot? host;
    for (final slot in _slots) {
      final origin = slot.hostOrigin;
      if (origin == null) continue;
      if (origin == tikTokOrigin) {
        host = slot;
        break;
      }
      host ??= slot;
    }
    if (host == null) return;
    _lastTikTokWarm = now;
    host.warm(EmbedWarmup.tikTokOrigins);
  }

  void _assign(
    EmbedSlot slot,
    EmbedRequest request,
    EmbedOrigins origins, {
    required bool play,
    bool preroll = false,
  }) {
    slot.assign(
      request,
      origin: origins.forPlatform(request.source.platform),
      play: play,
      muted: _sessionMuted,
      preroll: preroll,
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
