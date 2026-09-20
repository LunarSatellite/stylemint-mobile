import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../smoke/fake_api_client.dart';

/// The associate client book is reached from Settings and nowhere else.
///
/// Settings itself is opened only from the vendor menu, the vendor profile
/// and the creator menu, so this entry is not open to every signed in
/// account - the comment beside it used to say it was. That is the right
/// population rather than a gap to close: an associate is vendor team staff,
/// which is exactly who can get to Settings, and the backend gates the book
/// on team membership plus a live assignment anyway. So the fix was the
/// sentence, and what this pins is the tile it describes.
void main() {
  Widget app() {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: RouteNames.associateClientBook,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('the client book'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('Settings opens the client book', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final tile = find.text('Client book (store associates)');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tile, findsOneWidget);

    await tester.ensureVisible(tile);
    await tester.pump();
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('the client book'), findsOneWidget);
  });
}
