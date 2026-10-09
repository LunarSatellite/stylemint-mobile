import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';

/// Keeps the screen under it current without a pull-to-refresh.
///
/// Two triggers, one [onRefresh]:
///  * a [LiveSignal] in one of [scopes] (a push, a SignalR `live` event, or
///    the live channel reconnecting) that [accepts] lets through, debounced
///    by [debounce] so a burst of events is one re-read;
///  * every [interval] while it is non-null — the backstop for when push
///    and the live channel are both down. Null stops polling (the order is
///    finished, nothing will change).
///
/// Polling runs only while the app is in the foreground and this screen is
/// in view: it stops when the app is backgrounded or the screen is covered
/// (or its tab left) and, on return, re-reads at once and starts again. It
/// always stops when this widget is disposed.
///
/// [onRefresh] must re-read silently — keep what is on screen and swap in
/// the new data — since it runs while the user is looking. A refresh never
/// overlaps another: one that arrives meanwhile runs once afterwards.
class LiveRefresh extends ConsumerStatefulWidget {
  const LiveRefresh({
    required this.scopes,
    required this.onRefresh,
    required this.child,
    this.interval,
    this.accepts,
    this.debounce = const Duration(milliseconds: 300),
    super.key,
  });

  final Set<LiveScope> scopes;
  final Future<void> Function() onRefresh;
  final Widget child;
  final Duration? interval;
  final bool Function(LiveSignal signal)? accepts;
  final Duration debounce;

  @override
  ConsumerState<LiveRefresh> createState() => LiveRefreshState();
}

@visibleForTesting
class LiveRefreshState extends ConsumerState<LiveRefresh>
    with WidgetsBindingObserver {
  StreamSubscription<LiveSignal>? _signals;
  Timer? _poll;
  Timer? _debounce;
  bool _foreground = true;
  bool _visible = true;
  bool _running = false;
  bool _again = false;

  /// Whether the poll timer is running. For tests.
  bool get isPolling => _poll?.isActive ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _signals = ref.read(liveRefreshBusProvider).signals.listen(_onSignal);
    _restartPolling();
  }

  /// Hidden screens do not poll: an inactive tab of a shell, or a route
  /// covered by another, has its tickers muted. Coming back into view
  /// re-reads at once.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    // After the frame: a refresh writes providers, which must not happen
    // while the tree is building.
    if (visible) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_refresh()),
      );
    }
    _restartPolling();
  }

  @override
  void didUpdateWidget(covariant LiveRefresh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.interval != widget.interval) _restartPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_foreground) return;
        _foreground = true;
        // Whatever changed while away, show it now — then keep polling.
        unawaited(_refresh());
        _restartPolling();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
        _stopPolling();
      case AppLifecycleState.inactive:
        // Transient (a system sheet, the app switcher): keep going.
        break;
    }
  }

  void _onSignal(LiveSignal signal) {
    if (!signal.concerns(widget.scopes)) return;
    if (!(widget.accepts?.call(signal) ?? true)) return;
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => unawaited(_refresh()));
  }

  void _restartPolling() {
    _stopPolling();
    final every = widget.interval;
    if (every == null || !_foreground || !_visible) return;
    _poll = Timer.periodic(every, (_) => unawaited(_refresh()));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      await widget.onRefresh();
    } on Object {
      // Silent: the data on screen stays; the next trigger tries again.
    } finally {
      _running = false;
    }
    if (_again && mounted) {
      _again = false;
      await _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_signals?.cancel());
    _debounce?.cancel();
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
