import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/screens/try_on_paywall_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/shared/providers.dart';
import 'package:fpdart/fpdart.dart';

import 'try_on_fakes.dart';

void main() {
  late FakeTryOnRepository repo;
  late List<Uri> launched;

  Future<void> pump(WidgetTester tester) async {
    launched = [];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tryOnRepositoryProvider.overrideWithValue(repo),
          tryOnAccountKeyProvider.overrideWithValue('acct-1'),
          tryOnPaymentLauncherProvider.overrideWithValue((uri) async {
            launched.add(uri);
          }),
        ],
        child: const MaterialApp(home: TryOnPaywallScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => repo = FakeTryOnRepository());

  testWidgets('shows plans, trial and disclaimer', (tester) async {
    await pump(tester);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.textContaining('30 days'), findsOneWidget);
    expect(find.textContaining('199'), findsWidgets);
    expect(find.text('Start 7-day free trial'), findsOneWidget);
    expect(find.byKey(const Key('try-on-disclaimer')), findsOneWidget);
  });

  testWidgets('no trial button when the trial is used', (tester) async {
    repo.access = right(accessOf(trial: false));
    await pump(tester);
    expect(find.byKey(const Key('try-on-trial')), findsNothing);
  });

  testWidgets('subscribe hands off to the provider page, then confirms', (
    tester,
  ) async {
    await pump(tester);
    await tester.ensureVisible(find.byKey(const Key('try-on-subscribe')));
    await tester.tap(find.byKey(const Key('try-on-subscribe')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('subscribe:p1:3'));
    expect(launched.single.toString(), 'https://pay.example/esewa');

    // Back from the browser without the lifecycle event: manual confirm.
    await tester.ensureVisible(find.byKey(const Key('try-on-confirm')));
    await tester.tap(find.byKey(const Key('try-on-confirm')));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('confirm:s1'));
    expect(find.text('Virtual try-on unlocked'), findsOneWidget);
  });

  testWidgets('disabled service says so', (tester) async {
    repo.access = right(accessOf(enabled: false));
    await pump(tester);
    expect(
      find.text('Virtual try-on is not available right now.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('try-on-subscribe')), findsNothing);
  });
}
