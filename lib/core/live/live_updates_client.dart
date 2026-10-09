import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:stylemint_mobile_frontend/core/config/api_config.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';

/// One connection to the hub, as [LiveUpdatesClient] needs it. The SignalR
/// implementation is [SignalRLiveHub]; tests use a fake.
abstract interface class LiveHub {
  Future<void> start();
  Future<void> stop();

  /// The server's `live` method, with its single argument.
  void onLive(void Function(Object? argument) handler);

  /// The transport dropped and came back by itself.
  void onReconnected(void Function() handler);

  /// The connection ended for good (automatic reconnect gave up, or the
  /// server closed it).
  void onClosed(void Function() handler);
}

typedef LiveHubFactory =
    LiveHub Function(String url, Future<String> Function() accessToken);

/// Realtime order and delivery updates over SignalR
/// (`/hubs/notifications`, server method `live` — see the realtime
/// contract).
///
/// Every `live` event becomes a [LiveSignal] on [LiveRefreshBus], the same
/// bus foreground pushes feed, so both paths refresh the same screens the
/// same way. Every (re)connect publishes [LiveSignal.reconnected]: events
/// sent while the app was not listening are not replayed, so whatever is
/// open re-reads.
///
/// Best-effort by design: when the hub is unreachable, or the server never
/// sends `live`, nothing breaks — pushes and the screens' own polling keep
/// everything current. A failed connection retries with backoff for as long
/// as the app wants it.
class LiveUpdatesClient {
  LiveUpdatesClient({
    required LiveRefreshBus bus,
    required Future<String?> Function() accessToken,
    String baseUrl = ApiConfig.baseUrl,
    LiveHubFactory? hubFactory,
    this.retryDelays = defaultRetryDelays,
  }) : _bus = bus,
       _accessToken = accessToken,
       _url = '${_normaliseBase(baseUrl)}/hubs/notifications',
       _hubFactory = hubFactory ?? SignalRLiveHub.new;

  /// Waits between attempts after a failed start or a closed connection.
  static const defaultRetryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  final LiveRefreshBus _bus;
  final Future<String?> Function() _accessToken;
  final String _url;
  final LiveHubFactory _hubFactory;
  final List<Duration> retryDelays;

  LiveHub? _hub;
  String? _connectedToken;
  bool _wanted = false;
  bool _starting = false;
  int _attempt = 0;
  Timer? _retry;

  bool get isConnected => _hub != null;

  /// Connects (signed in, app in the foreground). Idempotent.
  Future<void> connect() async {
    _wanted = true;
    _retry?.cancel();
    if (_hub != null || _starting) return;
    _starting = true;
    try {
      final token = await _accessToken();
      if (!_wanted) return;
      if (token == null || token.isEmpty) return;

      final hub = _hubFactory(_url, () async => (await _accessToken()) ?? '')
        ..onLive(_onLive)
        ..onReconnected(() => _bus.publish(const LiveSignal.reconnected()));
      hub.onClosed(() {
        if (!identical(_hub, hub)) return;
        _hub = null;
        _connectedToken = null;
        _scheduleRetry();
      });

      try {
        await hub.start();
      } on Object {
        _scheduleRetry();
        return;
      }
      if (!_wanted) {
        await _stopQuietly(hub);
        return;
      }
      _hub = hub;
      _connectedToken = token;
      _attempt = 0;
      _bus.publish(const LiveSignal.reconnected());
    } finally {
      _starting = false;
    }
  }

  /// Disconnects (signed out, app backgrounded). No retry until [connect].
  Future<void> disconnect() async {
    _wanted = false;
    _retry?.cancel();
    _retry = null;
    _attempt = 0;
    final hub = _hub;
    _hub = null;
    _connectedToken = null;
    if (hub != null) await _stopQuietly(hub);
  }

  /// The session's tokens were saved (sign-in or refresh): reconnect when
  /// the connection was opened with a different access token.
  Future<void> tokenChanged() async {
    if (!_wanted) return;
    final token = await _accessToken();
    if (_hub != null && token == _connectedToken) return;
    final hub = _hub;
    _hub = null;
    _connectedToken = null;
    if (hub != null) await _stopQuietly(hub);
    await connect();
  }

  Future<void> dispose() => disconnect();

  void _onLive(Object? argument) {
    final signal = LiveSignal.fromLiveEvent(argument);
    if (signal != null) _bus.publish(signal);
  }

  void _scheduleRetry() {
    if (!_wanted || retryDelays.isEmpty) return;
    final delay = retryDelays[math.min(_attempt, retryDelays.length - 1)];
    _attempt++;
    _retry?.cancel();
    _retry = Timer(delay, () => unawaited(connect()));
  }

  static Future<void> _stopQuietly(LiveHub hub) async {
    try {
      await hub.stop();
    } on Object {
      // Already closed.
    }
  }

  static String _normaliseBase(String url) {
    var base = url.trim();
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    if (base.endsWith('/api')) base = base.substring(0, base.length - 4);
    return base;
  }
}

/// [LiveHub] over `signalr_netcore`, the same transport and auth as the
/// messaging hub: WebSockets, the access token as `?access_token=`, and the
/// library's automatic reconnect for short drops.
class SignalRLiveHub implements LiveHub {
  SignalRLiveHub(String url, Future<String> Function() accessToken)
    : _connection = HubConnectionBuilder()
          .withUrl(
            url,
            options: HttpConnectionOptions(
              accessTokenFactory: accessToken,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect(retryDelays: [0, 2000, 5000, 10000, 30000])
          .build();

  final HubConnection _connection;

  @override
  Future<void> start() => _connection.start() ?? Future<void>.value();

  @override
  Future<void> stop() => _connection.stop();

  @override
  void onLive(void Function(Object? argument) handler) => _connection.on(
    'live',
    (arguments) =>
        handler(arguments == null || arguments.isEmpty ? null : arguments[0]),
  );

  @override
  void onReconnected(void Function() handler) =>
      _connection.onreconnected(({connectionId}) => handler());

  @override
  void onClosed(void Function() handler) =>
      _connection.onclose(({error}) => handler());
}

final liveUpdatesClientProvider = Provider<LiveUpdatesClient>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  final client = LiveUpdatesClient(
    bus: ref.watch(liveRefreshBusProvider),
    accessToken: () => tokens.accessToken,
  );
  ref.onDispose(() => unawaited(client.dispose()));
  return client;
});
