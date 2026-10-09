import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/core/live/live_updates_client.dart';

/// Stands in for the SignalR connection.
class _FakeHub implements LiveHub {
  _FakeHub(this.url, this.token, {this.fail = false});

  final String url;
  final Future<String> Function() token;
  final bool fail;
  bool started = false;
  bool stopped = false;
  void Function(Object?)? live;
  void Function()? reconnected;
  void Function()? closed;

  @override
  Future<void> start() async {
    if (fail) throw StateError('hub unreachable');
    started = true;
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  void onLive(void Function(Object? argument) handler) => live = handler;

  @override
  void onReconnected(void Function() handler) => reconnected = handler;

  @override
  void onClosed(void Function() handler) => closed = handler;
}

void main() {
  late LiveRefreshBus bus;
  late List<LiveSignal> signals;
  late List<_FakeHub> hubs;
  late String? token;
  late bool failNext;

  setUp(() {
    bus = LiveRefreshBus();
    signals = [];
    bus.signals.listen(signals.add);
    hubs = [];
    token = 'token-1';
    failNext = false;
  });

  tearDown(() => bus.dispose());

  LiveUpdatesClient client() => LiveUpdatesClient(
    bus: bus,
    accessToken: () async => token,
    baseUrl: 'https://stylemint.example/api/',
    hubFactory: (url, accessToken) {
      final hub = _FakeHub(url, accessToken, fail: failNext);
      hubs.add(hub);
      return hub;
    },
    retryDelays: const [Duration(seconds: 2), Duration(seconds: 5)],
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('connects to /hubs/notifications with the current token', () async {
    final live = client();
    await live.connect();

    expect(hubs.single.url, 'https://stylemint.example/hubs/notifications');
    expect(await hubs.single.token(), 'token-1');
    expect(live.isConnected, isTrue);
  });

  test('a connect re-reads open screens; so does a reconnect', () async {
    final live = client();
    await live.connect();
    await settle();
    expect(signals.single.type, LiveSignal.reconnectedType);

    hubs.single.reconnected!();
    await settle();
    expect(signals, hasLength(2));
    expect(signals.last.type, LiveSignal.reconnectedType);
  });

  test('a live event becomes the same signal a push would', () async {
    final live = client();
    await live.connect();
    await settle();
    signals.clear();

    hubs.single.live!({
      'type': 'order.updated',
      'data': {'orderId': 'o-1', 'state': 'Delivered', 'extra': true},
    });
    await settle();
    expect(signals.single.type, 'order.updated');
    expect(signals.single.orderId, 'o-1');
    expect(signals.single.concerns({LiveScope.vendorOrders}), isTrue);
  });

  test('unknown types and garbage are ignored', () async {
    final live = client();
    await live.connect();
    await settle();
    signals.clear();

    hubs.single.live!({'type': 'something.new', 'data': <String, Object>{}});
    hubs.single.live!(null);
    hubs.single.live!('order.updated');
    await settle();
    expect(signals, isEmpty);
  });

  test('no token: no connection', () async {
    token = null;
    final live = client();
    await live.connect();
    expect(hubs, isEmpty);
    expect(live.isConnected, isFalse);
  });

  // testWidgets for its fake clock: timers advance with pump.
  testWidgets('an unreachable hub retries with backoff', (tester) async {
    failNext = true;
    final live = client();
    unawaited(live.connect());
    await tester.pump();
    expect(hubs, hasLength(1));
    expect(live.isConnected, isFalse);

    failNext = false;
    await tester.pump(const Duration(seconds: 1));
    expect(hubs, hasLength(1), reason: 'waits out the backoff');
    await tester.pump(const Duration(seconds: 1));
    expect(hubs, hasLength(2));
    expect(live.isConnected, isTrue);
    await live.disconnect();
  });

  testWidgets('disconnect stops it and nothing retries', (tester) async {
    final live = client();
    unawaited(live.connect());
    await tester.pump();
    unawaited(live.disconnect());
    await tester.pump();
    expect(hubs.single.stopped, isTrue);

    hubs.single.closed!();
    await tester.pump(const Duration(minutes: 5));
    expect(hubs, hasLength(1));
  });

  testWidgets('a closed connection comes back', (tester) async {
    final live = client();
    unawaited(live.connect());
    await tester.pump();

    hubs.single.closed!();
    expect(live.isConnected, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(hubs, hasLength(2));
    expect(live.isConnected, isTrue);
    await live.disconnect();
  });

  test('a new access token reconnects with it', () async {
    final live = client();
    await live.connect();

    await live.tokenChanged();
    expect(hubs, hasLength(1), reason: 'same token: nothing to do');

    token = 'token-2';
    await live.tokenChanged();
    expect(hubs.first.stopped, isTrue);
    expect(hubs, hasLength(2));
    expect(await hubs.last.token(), 'token-2');
  });
}
