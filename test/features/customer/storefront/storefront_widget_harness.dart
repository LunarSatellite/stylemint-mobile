import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// Pumps [storefrontRoute] at [initialLocation] inside [scope] on a
/// [width] × [height] screen, with stub screens for the places a storefront
/// links to.
Future<void> pumpStorefrontApp(
  WidgetTester tester, {
  required String initialLocation,
  required GoRoute storefrontRoute,
  required ProviderScope Function(Widget app) scope,
  double width = 390,
  double height = 1600,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, height)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      storefrontRoute,
      GoRoute(
        path: RouteNames.reelDetail,
        builder: (_, state) => Text('reel ${state.pathParameters['reelId']}'),
      ),
      GoRoute(
        path: RouteNames.productDetail,
        builder: (_, state) =>
            Text('product ${state.pathParameters['productId']}'),
      ),
      GoRoute(
        path: RouteNames.collection,
        builder: (_, state) =>
            Text('collection ${state.pathParameters['slug']}'),
      ),
      GoRoute(path: RouteNames.home, builder: (_, _) => const Text('home')),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    scope(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await settleStorefront(tester);
}

/// Lets loads, post-frame layout and short animations finish. (Skeleton
/// shimmer never settles, so pumpAndSettle can't be used.)
Future<void> settleStorefront(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Taps the storefront tab labelled [label].
Future<void> tapStorefrontTab(WidgetTester tester, String label) async {
  final tab = find.descendant(
    of: find.byType(TabBar),
    matching: find.text(label),
  );
  await tester.ensureVisible(tab);
  await tester.pump();
  await tester.tap(tab);
  await settleStorefront(tester);
}

Finder storefrontTab(String label) =>
    find.descendant(of: find.byType(TabBar), matching: find.text(label));
