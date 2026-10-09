import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/live_refresh.dart';

const _orderUpdated = LiveSignal(
  type: 'order.updated',
  scopes: [LiveScope.buyerOrders, LiveScope.vendorOrders],
  orderId: 'o-1',
);

void main() {
  late int refreshes;
  late LiveRefreshBus bus;

  setUp(() {
    refreshes = 0;
    bus = LiveRefreshBus();
  });

  tearDown(() => bus.dispose());

  Widget host({
    Duration? interval,
    Set<LiveScope> scopes = const {LiveScope.buyerOrders},
    bool Function(LiveSignal)? accepts,
    bool show = true,
  }) => ProviderScope(
    overrides: [liveRefreshBusProvider.overrideWithValue(bus)],
    child: MaterialApp(
      home: show
          ? LiveRefresh(
              scopes: scopes,
              interval: interval,
              accepts: accepts,
              onRefresh: () async => refreshes++,
              child: const SizedBox(),
            )
          : const SizedBox(),
    ),
  );

  LiveRefreshState state(WidgetTester tester) =>
      tester.state<LiveRefreshState>(find.byType(LiveRefresh));

  void publish(LiveSignal signal) => bus.publish(signal);

  group('polling', () {
    testWidgets('re-reads every interval while shown', (tester) async {
      await tester.pumpWidget(host(interval: const Duration(seconds: 10)));
      expect(state(tester).isPolling, isTrue);

      await tester.pump(const Duration(seconds: 10));
      expect(refreshes, 1);
      await tester.pump(const Duration(seconds: 10));
      expect(refreshes, 2);
    });

    testWidgets('no interval (a finished order): no polling', (tester) async {
      await tester.pumpWidget(host());
      expect(state(tester).isPolling, isFalse);
      await tester.pump(const Duration(minutes: 1));
      expect(refreshes, 0);
    });

    testWidgets('stops when the order turns terminal', (tester) async {
      await tester.pumpWidget(host(interval: const Duration(seconds: 5)));
      await tester.pump(const Duration(seconds: 5));
      expect(refreshes, 1);

      await tester.pumpWidget(host());
      expect(state(tester).isPolling, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(refreshes, 1);
    });

    testWidgets('pauses in the background; resuming re-reads at once', (
      tester,
    ) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await tester.pumpWidget(host(interval: const Duration(seconds: 10)));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(state(tester).isPolling, isFalse);
      await tester.pump(const Duration(seconds: 30));
      expect(refreshes, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(refreshes, 1);
      expect(state(tester).isPolling, isTrue);
      await tester.pump(const Duration(seconds: 10));
      expect(refreshes, 2);
    });

    testWidgets('stops when the screen is disposed', (tester) async {
      await tester.pumpWidget(host(interval: const Duration(seconds: 10)));
      await tester.pumpWidget(host(show: false));
      await tester.pump(const Duration(seconds: 30));
      expect(refreshes, 0);
    });

    testWidgets('does not poll while covered by another route', (
      tester,
    ) async {
      await tester.pumpWidget(host(interval: const Duration(seconds: 10)));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(builder: (_) => const Scaffold()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(refreshes, 0);

      navigator.pop();
      await tester.pumpAndSettle();
      expect(refreshes, 1, reason: 'back in view: re-read at once');
    });
  });

  group('signals', () {
    testWidgets('a burst in scope is one debounced re-read', (tester) async {
      await tester.pumpWidget(host());
      publish(_orderUpdated);
      publish(_orderUpdated);
      publish(_orderUpdated);
      await tester.pump(const Duration(milliseconds: 100));
      expect(refreshes, 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(refreshes, 1);
    });

    testWidgets('other scopes are ignored', (tester) async {
      await tester.pumpWidget(host(scopes: const {LiveScope.courierOffers}));
      publish(_orderUpdated);
      await tester.pump(const Duration(seconds: 1));
      expect(refreshes, 0);
    });

    testWidgets('a signal about another order is ignored', (tester) async {
      await tester.pumpWidget(host(accepts: (s) => s.orderId == 'o-2'));
      publish(_orderUpdated);
      await tester.pump(const Duration(seconds: 1));
      expect(refreshes, 0);
    });

    testWidgets('a reconnect re-reads', (tester) async {
      await tester.pumpWidget(host());
      publish(const LiveSignal.reconnected());
      await tester.pump(const Duration(seconds: 1));
      expect(refreshes, 1);
    });
  });
}
