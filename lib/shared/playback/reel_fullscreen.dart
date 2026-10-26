import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The orientations the app runs in everywhere except a full-screen reel:
/// portrait only (owner decision, 2026-09-15). `main()` locks to these at
/// start-up and a full-screen reel restores exactly these on its way out, so
/// the two can never drift apart.
const List<DeviceOrientation> appOrientations = [DeviceOrientation.portraitUp];

/// What a full-screen reel may rotate to when its video is wider than tall.
const List<DeviceOrientation> landscapeReelOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

/// Whether a reel is being watched full screen: only the video, no captions,
/// tags, buttons, bottom bar or status bar (owner request, 2026-10-26).
///
/// Full screen happens in place rather than on a route of its own. Most reels
/// play in an embedded platform player whose WebView lives beneath the feed
/// (see `EmbedPlayerLayer`); moving it to another route would reload it and
/// restart the video. So the reel stays exactly where it is, with the same
/// player, and everything around it steps aside while this is true: the
/// reel's own overlay, the feed's paging, Home's switch and stories strip, the
/// reel page's back button and the shell's bottom bar and tab swiping.
///
/// The system UI goes immersive while it lasts. Nothing else in the app sets
/// a system UI mode, so leaving restores Flutter's default — manual, with
/// every overlay shown — and [appOrientations].
///
/// Exactly one reel owns full screen at a time; only its owner (or nobody in
/// particular, for [exit] without an owner) can end it.
class ReelFullscreenNotifier extends Notifier<bool> {
  Object? _owner;
  bool _allowLandscape = false;
  AppLifecycleListener? _lifecycle;
  bool _disposed = false;

  @override
  bool build() {
    ref.onDispose(() {
      _disposed = true;
      final wasActive = _owner != null;
      _owner = null;
      _lifecycle?.dispose();
      _lifecycle = null;
      if (wasActive) unawaited(_restoreSystemUi());
    });
    return false;
  }

  /// Whether [owner] is the reel on full screen now.
  bool isOwnedBy(Object owner) => identical(_owner, owner);

  /// Takes [owner]'s reel full screen. [allowLandscape] lets the phone rotate
  /// while it lasts — for a video wider than it is tall.
  void enter(Object owner, {required bool allowLandscape}) {
    if (_disposed) return;
    _owner = owner;
    _allowLandscape = allowLandscape;
    // Android can bring the bars back while the app is in the background;
    // coming back to a full-screen reel hides them again.
    _lifecycle ??= AppLifecycleListener(
      onResume: () {
        if (_owner != null) unawaited(_applySystemUi());
      },
    );
    unawaited(_applySystemUi());
    state = true;
  }

  /// Leaves full screen. With an [owner], only when that reel owns it.
  void exit([Object? owner]) {
    if (_disposed || _owner == null) return;
    if (owner != null && !identical(owner, _owner)) return;
    _owner = null;
    _allowLandscape = false;
    _lifecycle?.dispose();
    _lifecycle = null;
    unawaited(_restoreSystemUi());
    state = false;
  }

  Future<void> _applySystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(
      _allowLandscape ? landscapeReelOrientations : appOrientations,
    );
  }

  static Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    await SystemChrome.setPreferredOrientations(appOrientations);
  }
}

/// See [ReelFullscreenNotifier].
final reelFullscreenProvider = NotifierProvider<ReelFullscreenNotifier, bool>(
  ReelFullscreenNotifier.new,
);
