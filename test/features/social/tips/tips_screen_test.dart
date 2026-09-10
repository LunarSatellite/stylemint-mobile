import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/repositories/tips_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/notifiers/tips_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/screens/tips_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _FakeTipsRepository implements TipsRepository {
  final List<String> historyTypes = [];

  @override
  Future<Either<NetworkExceptions, List<Tip>>> getTipHistory({
    required String type,
  }) async {
    historyTypes.add(type);
    return right(const []);
  }

  @override
  Future<Either<NetworkExceptions, TipBalance>> getBalance() async => right(
    const TipBalance(
      availableBalance: Money(amount: 0, currency: 'NPR'),
      totalReceived: Money(amount: 0, currency: 'NPR'),
      totalSent: Money(amount: 0, currency: 'NPR'),
      pendingBalance: Money(amount: 0, currency: 'NPR'),
    ),
  );

  @override
  Future<Either<NetworkExceptions, Tip>> sendTip({
    required String creatorProfileId,
    required Money amount,
    required String paymentIntentId,
    String? reelId,
  }) => throw UnimplementedError();
}

Widget _app(_FakeTipsRepository repository) {
  return ProviderScope(
    overrides: [
      tipsNotifierProvider.overrideWith(
        (ref) => TipsNotifier(repository),
      ),
      tipBalanceNotifierProvider.overrideWith(
        (ref) => TipBalanceNotifier(repository),
      ),
    ],
    child: const MaterialApp(home: TipsScreen()),
  );
}

void main() {
  testWidgets('swiping to Received loads received history', (tester) async {
    final repository = _FakeTipsRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    expect(repository.historyTypes, contains('sent'));
    expect(find.text('No sent tips yet'), findsOneWidget);

    await tester.drag(find.byType(TabBarView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(repository.historyTypes.last, 'received');
    expect(find.text('No received tips yet'), findsOneWidget);
  });

  testWidgets('Send Tip explains that no payment is available', (tester) async {
    final repository = _FakeTipsRepository();
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send Tip'));
    await tester.pumpAndSettle();

    expect(find.text('Tip payments are coming soon'), findsOneWidget);
    expect(find.textContaining('No charge has been made'), findsOneWidget);
  });
}
