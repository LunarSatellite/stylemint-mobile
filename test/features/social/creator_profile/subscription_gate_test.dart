import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/datasources/subscription_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/account_subscription_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/subscription_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/repositories/subscription_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/providers/subscription_providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/upgrade_subscription_screen.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/providers.dart';

/// Returns fixed plans and a fixed current subscription; records any upgrade,
/// which must never happen from this screen while the gate is on.
class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required this.mine});

  final AccountSubscriptionDto? mine;
  int upgrades = 0;

  @override
  SubscriptionRemoteDataSource get remote => throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, List<SubscriptionPlanDto>>>
  listPlans() async => right(_plans);

  @override
  Future<Either<NetworkExceptions, AccountSubscriptionDto?>> getMine() async =>
      right(mine);

  @override
  Future<Either<NetworkExceptions, AccountSubscriptionDto>> upgrade({
    required String planId,
  }) async {
    upgrades++;
    return right(_subscription);
  }
}

final _plans = [
  SubscriptionPlanDto(
    id: 'plan-basic-monthly',
    tier: 1,
    cadence: 1,
    priceAmount: 499,
    priceCurrency: 'NPR',
    name: 'Basic',
    marketingTag: null,
    maxCampaigns: 3,
    maxProducts: 20,
    orderManagement: false,
    sortOrder: 1,
  ),
  SubscriptionPlanDto(
    id: 'plan-pro-monthly',
    tier: 2,
    cadence: 1,
    priceAmount: 1499,
    priceCurrency: 'NPR',
    name: 'Pro',
    marketingTag: 'Most popular',
    maxCampaigns: -1,
    maxProducts: -1,
    orderManagement: true,
    sortOrder: 2,
  ),
];

final _subscription = AccountSubscriptionDto(
  id: 'sub-1',
  accountId: 'acc-1',
  planId: 'plan-pro-monthly',
  tier: 2,
  cadence: 1,
  pricePaidAmount: 1499,
  pricePaidCurrency: 'NPR',
  startedUtc: DateTime.utc(2026, 5, 4),
  cancelledUtc: null,
  status: 1,
);

const _blocked = DigitalGoodsPolicy.blockedBy(StoreBillingRule.googlePlay);
const _allowed = DigitalGoodsPolicy.allowed();

Future<_FakeSubscriptionRepository> _pump(
  WidgetTester tester, {
  required DigitalGoodsPolicy policy,
  AccountSubscriptionDto? mine,
}) async {
  final repository = _FakeSubscriptionRepository(mine: mine);
  // 440 wide, not 390: the plan card overflows by 16px at 390 on `main`,
  // which is a pre-existing layout bug and not what these tests are about.
  await tester.binding.setSurfaceSize(const Size(440, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        digitalGoodsPolicyProvider.overrideWithValue(policy),
        subscriptionRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: UpgradeSubscriptionScreen()),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
  return repository;
}

void main() {
  group('with digital goods blocked', () {
    testWidgets('no plan list, no plan price and no subscribe CTA', (
      tester,
    ) async {
      await _pump(tester, policy: _blocked, mine: _subscription);

      expect(find.text('Proceed'), findsNothing);
      expect(find.text('Billed Monthly'), findsNothing);
      expect(find.text('Billed Yearly'), findsNothing);
      // A plan's name or marketing tag would be the offer. The plan cards
      // draw theirs through RichText, so the finder has to look inside.
      expect(
        find.textContaining('Basic Plan', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Most popular', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('an existing subscriber still sees what they own', (
      tester,
    ) async {
      await _pump(tester, policy: _blocked, mine: _subscription);

      expect(find.text('My Subscription'), findsOneWidget);
      expect(find.text('Tier 2'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('NPR 1499.00'), findsOneWidget);
      expect(find.textContaining('managed outside this app'), findsOneWidget);
    });

    testWidgets('someone with no subscription is told there is nothing', (
      tester,
    ) async {
      await _pump(tester, policy: _blocked);

      expect(find.textContaining('not available in this app'), findsOneWidget);
      expect(find.text('Proceed'), findsNothing);
    });

    testWidgets('the read-only view never calls upgrade', (tester) async {
      final repository = await _pump(
        tester,
        policy: _blocked,
        mine: _subscription,
      );

      expect(repository.upgrades, 0);
    });
  });

  group('with digital goods allowed', () {
    testWidgets('the plan list and the CTA are intact', (tester) async {
      await _pump(tester, policy: _allowed, mine: _subscription);

      expect(find.text('Upgrade Subscription Plan'), findsOneWidget);
      expect(find.text('Proceed'), findsOneWidget);
      expect(find.text('Billed Monthly'), findsOneWidget);
      expect(
        find.textContaining('Basic Plan', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Pro Plan (Most popular)', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
