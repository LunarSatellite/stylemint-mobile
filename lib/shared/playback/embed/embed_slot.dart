import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_startup_metrics.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';

/// What an embed slot's player is doing, as reported by its host page.
enum EmbedPlayerState {
  idle,
  loading,
  ready,
  cued,
  buffering,
  playing,
  paused,
  ended,
  failed,
}

/// A reel an embed slot can be asked to play.
final class EmbedRequest {
  EmbedRequest(this.source)
    : key = '${source.platform.name}:${source.externalId}';

  final EmbedSource source;

  /// Identifies the video across rebuilds and feed pages.
  final String key;
}

/// Runs the WebView behind an [EmbedSlot]. An interface so slot and pool
/// logic can be tested without a platform view.
abstract interface class EmbedSlotDriver {
  /// Loads the host page with [origin] as its base URL.
  Future<void> loadHost(String origin);

  Future<void> runJavaScript(String source);
}

/// One WebView-backed player that is reused for many reels.
///
/// Every assignment gets a new token, and the host page tags each event with
/// the token of the assignment it belongs to, so late events from a reel the
/// slot has moved on from are dropped. Commands sent before the host page has
/// loaded are queued and replayed once it has.
///
/// The slot times each reel's start-up into [metrics], and retries a TikTok
/// start that stalls (see [startTimeout]).
class EmbedSlot extends ChangeNotifier {
  EmbedSlot(
    this.index, {
    this.readyTimeout = const Duration(seconds: 12),
    this.startTimeout = const Duration(milliseconds: 2500),
    EmbedStartupMetrics? metrics,
  }) : metrics = metrics ?? EmbedStartupMetrics();

  final int index;

  /// How long a reel may take to report its player ready before the slot
  /// treats the embed as failed.
  final Duration readyTimeout;

  /// How long a TikTok reel may be asked to play, once its player is ready,
  /// before its video time must have moved (the host page's `progress`
  /// event). Otherwise the start is retried, once, muted. A player that
  /// reports paused before any frame is retried at once.
  final Duration startTimeout;

  /// Where start-up timings are recorded.
  final EmbedStartupMetrics metrics;

  EmbedSlotDriver? _driver;
  String? _hostOrigin;
  bool _hostReady = false;
  final List<String> _pending = [];
  Timer? _readyTimer;
  Timer? _startTimer;
  bool _disposed = false;

  int _token = 0;
  EmbedRequest? _request;
  EmbedPlayerState _state = EmbedPlayerState.idle;
  bool _wantsPlay = false;
  bool _muted = false;
  bool _preroll = false;
  bool _hasStarted = false;
  int? _durationSeconds;
  String? _errorCode;
  int _generation = 0;

  // Start-up trace of the current assignment.
  Duration? _assignedAt;
  Duration? _readyAt;
  Duration? _playRequestedAt;
  bool _warmAtPlay = false;
  bool _prerolled = false;
  bool _progressed = false;
  bool _traced = false;
  bool _startRetried = false;
  String? _startRetryReason;

  /// Recency stamp the pool uses to recycle the least recently used slot.
  int lastUsed = 0;

  EmbedRequest? get request => _request;
  String? get key => _request?.key;

  /// Origin the host page is loaded (or loading) under. Null until the slot
  /// is first assigned.
  String? get hostOrigin => _hostOrigin;
  EmbedPlayerState get state => _state;
  bool get wantsPlay => _wantsPlay;

  /// True while the player is muted, e.g. after a platform blocked playback
  /// with sound.
  bool get muted => _muted;

  /// True while the reel waits off screen pre-rolling: loaded muted and held
  /// on its first moving frames, so it shows video the moment it is on screen.
  bool get prerolls => _preroll;

  /// True once the current reel has shown moving frames. A TikTok reel only
  /// counts frames it showed while asked to play, so its poster covers the
  /// player's start screen until then.
  bool get hasStarted => _hasStarted;

  /// Length reported by the player, when it reports one.
  int? get durationSeconds => _durationSeconds;

  /// Platform error behind [EmbedPlayerState.failed], e.g. `yt_150` or
  /// `timeout`.
  String? get errorCode => _errorCode;

  /// Bumped when the WebView's renderer died and the view must be rebuilt.
  int get generation => _generation;

  void attach(EmbedSlotDriver driver) {
    _driver = driver;
    final origin = _hostOrigin;
    if (origin == null || _hostReady) return;
    if (_request != null) {
      _pending
        ..clear()
        ..add(_assignScript());
    }
    unawaited(driver.loadHost(origin));
  }

  void detach(EmbedSlotDriver driver) {
    if (!identical(_driver, driver)) return;
    _driver = null;
    _hostReady = false;
  }

  /// Loads [request] into this slot, replacing whatever it held. A reel that
  /// won't [play] yet can [preroll] (see [prerolls]).
  void assign(
    EmbedRequest request, {
    required String origin,
    required bool play,
    required bool muted,
    bool preroll = false,
  }) {
    _request = request;
    _token++;
    _wantsPlay = play;
    _muted = muted;
    _preroll = preroll && !play;
    _hasStarted = false;
    _durationSeconds = null;
    _errorCode = null;
    _state = EmbedPlayerState.loading;
    _startTrace(play: play);
    _pending.clear();
    if (_hostOrigin != origin) {
      _hostOrigin = origin;
      _hostReady = false;
      _pending.add(_assignScript());
      final driver = _driver;
      if (driver != null) unawaited(driver.loadHost(origin));
    } else {
      _run(_assignScript());
    }
    _armReadyTimer();
    notifyListeners();
  }

  void play() {
    if (_request == null || _wantsPlay) return;
    _wantsPlay = true;
    _preroll = false;
    if (!_traced && _playRequestedAt == null) {
      _playRequestedAt = metrics.now();
      _warmAtPlay = _readyAt != null;
    }
    _run('smPlayer.play()');
    _armStartWatchdog();
  }

  /// Stops playback. [byViewer] marks a pause the viewer asked for on the reel
  /// on screen: the host page then puts a YouTube player back in its cued
  /// state at the current time rather than pausing it, because a paused
  /// YouTube player shows its own suggestions panel, which nobody can tap
  /// here. [play] resumes from that time. Other platforms pause either way.
  void pause({bool byViewer = false}) {
    if (_request == null || !_wantsPlay) return;
    _wantsPlay = false;
    _startTimer?.cancel();
    // A reel left before it started is timed afresh when it is back.
    if (!_traced) _playRequestedAt = null;
    if (!_progressed) _startRetried = false;
    _run(byViewer ? 'smPlayer.pause(true)' : 'smPlayer.pause()');
  }

  void setMuted(bool muted) {
    if (_request == null || _muted == muted) return;
    _muted = muted;
    _run('smPlayer.setMuted($muted)');
    notifyListeners();
  }

  /// Asks the host page to open connections to [origins] ahead of a player
  /// that will need them. Best effort: dropped when the slot has no host page,
  /// or when a new reel is assigned before the page has loaded.
  void warm(List<String> origins) {
    if (_hostOrigin == null || origins.isEmpty) return;
    _run('smPlayer.warm(${jsonEncode(origins)})');
  }

  /// Empties the slot and frees the platform player it held.
  void release() {
    if (_request == null) return;
    _request = null;
    _token++;
    _wantsPlay = false;
    _preroll = false;
    _hasStarted = false;
    _errorCode = null;
    _readyTimer?.cancel();
    _startTimer?.cancel();
    _traced = true;
    _pending.clear();
    _state = EmbedPlayerState.idle;
    if (_hostReady) _run('smPlayer.stop($_token)');
    notifyListeners();
  }

  /// Called when the WebView finished loading a page at [origin].
  void hostLoaded(String? origin) {
    final expected = _hostOrigin;
    if (_hostReady || expected == null || origin == null) return;
    if (_normalizeOrigin(origin) != _normalizeOrigin(expected)) return;
    final driver = _driver;
    if (driver == null) return;
    _hostReady = true;
    final queued = List<String>.of(_pending);
    _pending.clear();
    for (final script in queued) {
      unawaited(driver.runJavaScript(script));
    }
  }

  /// The WebView's renderer process died (usually the OS reclaiming memory).
  /// The view is rebuilt and the current reel reloaded into it.
  void rendererGone() {
    _driver = null;
    _hostReady = false;
    _generation++;
    _readyAt = null;
    _progressed = false;
    _startTimer?.cancel();
    if (_request != null) {
      _state = EmbedPlayerState.loading;
      _armReadyTimer();
    }
    notifyListeners();
  }

  void handleEvent(Map<String, dynamic> event) {
    final type = event['type'];
    if (type is! String) return;
    if (type == 'host_loaded') {
      final origin = event['origin'];
      hostLoaded(origin is String ? origin : null);
      return;
    }
    final token = event['token'];
    if (_request == null || token is! num || token.toInt() != _token) return;
    if (embedTrace) {
      debugPrint(
        '[embed-event] slot$index $key $type'
        '${event['code'] == null ? '' : ' ${event['code']}'} '
        'want=$_wantsPlay started=$_hasStarted state=${_state.name}',
      );
    }

    switch (type) {
      case 'ready':
        _readyTimer?.cancel();
        _readyAt ??= metrics.now();
        if (_state == EmbedPlayerState.loading) {
          _setState(EmbedPlayerState.ready);
        }
        _armStartWatchdog();
      case 'init':
        // TikTok's player is initialising: still loading, the poster stays.
        break;
      case 'cued':
        // Asked to play, a cue is stale: from a viewer pause (see [pause])
        // resumed before its cue was reported, or from the reel before.
        // Keeps the state, and [hasStarted], of the reel that plays on.
        if (_wantsPlay) break;
        _readyTimer?.cancel();
        _setState(EmbedPlayerState.cued);
      case 'progress':
        // The video time moved while asked to play: the start succeeded.
        _startTimer?.cancel();
        _progressed = true;
      case 'prerolled':
        // First frames fetched and held off screen; not shown, not started.
        _readyTimer?.cancel();
        _prerolled = true;
      case 'buffering':
        _readyTimer?.cancel();
        _setState(EmbedPlayerState.buffering);
      case 'playing':
        _readyTimer?.cancel();
        if (_wantsPlay) {
          _recordStartup();
        } else {
          _prerolled = true;
        }
        final firstFrame = !_hasStarted;
        _hasStarted = true;
        if (_state == EmbedPlayerState.playing && firstFrame) {
          notifyListeners();
        } else {
          _setState(EmbedPlayerState.playing);
        }
      case 'paused':
        // Asked to play but paused before any frame: TikTok's player is
        // sitting on its start screen. Start it again muted, at once.
        if (_wantsPlay && !_hasStarted) _retryStart('paused');
        _setState(EmbedPlayerState.paused);
      case 'ended':
        _setState(EmbedPlayerState.ended);
      case 'error':
        _readyTimer?.cancel();
        _startTimer?.cancel();
        _errorCode = '${event['code']}';
        _state = EmbedPlayerState.failed;
        notifyListeners();
      case 'autoplayBlocked':
        if (!_muted) {
          _muted = true;
          notifyListeners();
        }
      case 'muted':
        final value = event['value'];
        if (value is bool && value != _muted) {
          _muted = value;
          notifyListeners();
        }
      case 'duration':
        final seconds = event['seconds'];
        if (seconds is num && seconds > 0) {
          _durationSeconds = seconds.round();
          notifyListeners();
        }
    }
  }

  String _assignScript() {
    final source = _request!.source;
    return 'smPlayer.assign($_token,'
        '${jsonEncode(source.platform.name)},'
        '${jsonEncode(source.externalId)},'
        '${jsonEncode(source.permalink)},'
        '$_wantsPlay,$_muted,$_preroll)';
  }

  void _run(String script) {
    final driver = _driver;
    if (_hostReady && driver != null) {
      unawaited(driver.runJavaScript(script));
    } else {
      _pending.add(script);
    }
  }

  void _armReadyTimer() {
    _readyTimer?.cancel();
    final token = _token;
    _readyTimer = Timer(readyTimeout, () {
      if (_disposed || token != _token) return;
      if (_state != EmbedPlayerState.loading) return;
      _errorCode = 'timeout';
      _setState(EmbedPlayerState.failed);
    });
  }

  void _startTrace({required bool play}) {
    _startTimer?.cancel();
    final now = metrics.now();
    _assignedAt = now;
    _readyAt = null;
    _playRequestedAt = play ? now : null;
    _warmAtPlay = false;
    _prerolled = false;
    _progressed = false;
    _traced = false;
    _startRetried = false;
    _startRetryReason = null;
  }

  /// TikTok's player can sit on its start screen instead of playing; the
  /// other platforms report blocked playback themselves.
  bool get _watchesStart => _request?.source.platform == SocialPlatform.tiktok;

  /// Times the start from the later of the play request and the player being
  /// ready: a player still loading is covered by [readyTimeout].
  void _armStartWatchdog() {
    _startTimer?.cancel();
    if (!_watchesStart ||
        !_wantsPlay ||
        _progressed ||
        _startRetried ||
        _readyAt == null) {
      return;
    }
    final token = _token;
    _startTimer = Timer(startTimeout, () {
      if (_disposed || token != _token) return;
      _retryStart('timeout');
    });
  }

  void _retryStart(String reason) {
    _startTimer?.cancel();
    final key = this.key;
    if (key == null ||
        !_watchesStart ||
        !_wantsPlay ||
        _progressed ||
        _startRetried) {
      return;
    }
    _startRetried = true;
    _startRetryReason = reason;
    final since = _playRequestedAt ?? _assignedAt;
    metrics.recordStartRetry(
      key,
      reason,
      since == null ? Duration.zero : metrics.now() - since,
    );
    _run('smPlayer.retryStart()');
  }

  void _recordStartup() {
    final key = this.key;
    final assignedAt = _assignedAt;
    final playAt = _playRequestedAt;
    if (_traced || key == null || assignedAt == null || playAt == null) return;
    _traced = true;
    final now = metrics.now();
    final readyAt = _readyAt;
    metrics.record(
      EmbedStartupSample(
        key: key,
        warm: _warmAtPlay,
        prerolled: _prerolled,
        assignToReady: readyAt == null ? null : readyAt - assignedAt,
        assignToFirstFrame: now - assignedAt,
        playToFirstFrame: now - playAt,
        startRetry: _startRetryReason,
      ),
    );
  }

  void _setState(EmbedPlayerState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  static String _normalizeOrigin(String origin) {
    var value = origin.trim().toLowerCase();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _readyTimer?.cancel();
    _startTimer?.cancel();
    super.dispose();
  }
}
