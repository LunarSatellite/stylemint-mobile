import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/inbound_share.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/inbound_share_listener.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/app_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'search_input_test_support.dart';

final Uint8List _bytes = Uint8List.fromList(const [4, 3, 2, 1]);

/// The listener routes; the screen it routes to is tested on its own. This
/// stub stands in for it so the assertion is about arrival, not rendering.
GoRouter _router() => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => const Scaffold(body: Text('home')),
    ),
    GoRoute(
      path: RouteNames.searchScreenshot,
      builder: (_, state) => Scaffold(
        body: Text('screenshot:${(state.extra as Uint8List?)?.join(',')}'),
      ),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester, {
  required FakeInboundShareSource source,
  required GoRouter router,
}) async {
  addTearDown(router.dispose);
  addTearDown(source.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inboundShareSourceProvider.overrideWithValue(source),
        appRouterProvider.overrideWithValue(router),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            InboundShareListener(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a share that launched the app opens screenshot search', (
    tester,
  ) async {
    final source = FakeInboundShareSource(
      launchShare: InboundShare(bytes: _bytes),
    );
    await _pump(tester, source: source, router: _router());

    expect(find.text('screenshot:4,3,2,1'), findsOneWidget);
  });

  testWidgets('a cold-start share is taken once, not re-opened forever', (
    tester,
  ) async {
    final source = FakeInboundShareSource(
      launchShare: InboundShare(bytes: _bytes),
    );
    await _pump(tester, source: source, router: _router());
    await tester.pumpAndSettle();

    expect(source.takeCalls, 1);
    expect(find.text('screenshot:4,3,2,1'), findsOneWidget);
  });

  testWidgets('a share into a running app opens the same route', (
    tester,
  ) async {
    final source = FakeInboundShareSource();
    await _pump(tester, source: source, router: _router());
    expect(find.text('home'), findsOneWidget);

    source.share(_bytes);
    await tester.pumpAndSettle();

    // Same route, same extra shape as the cold start and as the Discover
    // button: one screenshot path.
    expect(find.text('screenshot:4,3,2,1'), findsOneWidget);
  });

  testWidgets('no share means no navigation at all', (tester) async {
    final source = FakeInboundShareSource();
    await _pump(tester, source: source, router: _router());

    expect(find.text('home'), findsOneWidget);
    expect(find.textContaining('screenshot:'), findsNothing);
  });
}
