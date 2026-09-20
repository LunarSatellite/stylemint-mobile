import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/refill_plan_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/refill_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/replenishment_rules_dto.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The refill endpoints, answered from memory and recording every call.
///
/// Hand-written rather than stubbed because most of what these tests assert is
/// what the screen *did not* call: no prepare on open, no confirm without a
/// tap, no rule save with a value outside its range.
class FakeRefillPlanDataSource implements RefillPlanDataSource {
  /// What `GET current` answers. **Null is a 204** — the customer's own rules
  /// saying there is no basket.
  RefillPlanDto? currentPlan;

  /// What a `POST` prepare answers. Null is again a 204.
  RefillPlanDto? preparedPlan = fixturePlan;

  ReplenishmentPreferenceDto preferenceValue = preparingPreference;

  /// Set to throw from the next call, to exercise the failure branches.
  bool failEverything = false;

  int currentCalls = 0;
  int prepareCalls = 0;
  int preferenceCalls = 0;
  final List<String> confirmedPlanIds = <String>[];
  final List<String> dismissedPlanIds = <String>[];
  final List<ReplenishmentRulesRequest> savedRules =
      <ReplenishmentRulesRequest>[];
  final List<DateTime?> pauses = <DateTime?>[];

  @override
  Future<RefillPlanDto?> current() async {
    currentCalls++;
    if (failEverything) throw StateError('offline in test');
    return currentPlan;
  }

  @override
  Future<RefillPlanDto?> prepare({required String idempotencyKey}) async {
    prepareCalls++;
    if (failEverything) throw StateError('offline in test');
    return preparedPlan;
  }

  @override
  Future<RefillPlanHandoffDto> confirm({
    required String planId,
    required String idempotencyKey,
  }) async {
    if (failEverything) throw StateError('offline in test');
    confirmedPlanIds.add(planId);
    return fixtureHandoff;
  }

  @override
  Future<void> dismiss({
    required String planId,
    required String idempotencyKey,
  }) async {
    if (failEverything) throw StateError('offline in test');
    dismissedPlanIds.add(planId);
  }

  @override
  Future<ReplenishmentPreferenceDto> preference() async {
    preferenceCalls++;
    if (failEverything) throw StateError('offline in test');
    return preferenceValue;
  }

  /// Answers the way the backend does: with the *stored* rule set, so a test
  /// can tell a round trip from an echo of what was typed.
  @override
  Future<ReplenishmentPreferenceDto> setRules(
    ReplenishmentRulesRequest rules, {
    required String idempotencyKey,
  }) async {
    if (failEverything) throw StateError('offline in test');
    savedRules.add(rules);
    return preferenceValue = preferenceValue.copyWith(
      automationLevel: rules.automationLevel.wire,
      steadiness: rules.steadiness.wire,
      leadTimeDays: rules.leadTimeDays,
      minDaysBetweenPlans: rules.minDaysBetweenPlans,
      maxPlanAmount: rules.maxPlanAmount,
      maxPlanCurrency: rules.maxPlanAmount == null
          ? null
          : rules.maxPlanCurrency,
      allowSubstitutions: rules.allowSubstitutions,
      updatedUtc: DateTime.utc(2026, 9, 19, savedRules.length),
    );
  }

  @override
  Future<ReplenishmentPreferenceDto> setPause(
    DateTime? pausedUntilUtc, {
    required String idempotencyKey,
  }) async {
    if (failEverything) throw StateError('offline in test');
    pauses.add(pausedUntilUtc);
    return preferenceValue = preferenceValue.copyWith(
      pausedUntilUtc: pausedUntilUtc,
      paused: pausedUntilUtc != null,
      updatedUtc: DateTime.utc(2026, 9, 19, 12, pauses.length),
    );
  }
}

/// A customer who asked for a basket to be prepared, is opted in and is not
/// inside a pause. Substitutions are off, which is the default.
final ReplenishmentPreferenceDto preparingPreference =
    ReplenishmentPreferenceDto(
      enabled: true,
      updatedUtc: DateTime.utc(2026, 9, 18),
      automationLevel: 'prepareBasket',
      leadTimeDays: 10,
      minDaysBetweenPlans: 14,
    );

/// One plan carrying all four line outcomes that matter:
///
/// * `ready` — in the basket, at the price they last paid;
/// * `priceChanged` — in the basket, and **both** prices are facts;
/// * `notVerified` — left out, and its current price is null;
/// * `outOfStock` — left out, with the server's own reason.
///
/// Every line carries a `thumbnailUrl`, so a test can prove the screen
/// ignores them rather than proving it against a payload that had none.
final RefillPlanDto fixturePlan = RefillPlanDto(
  planId: 'plan-1',
  state: 'prepared',
  preparedUtc: DateTime.utc(2026, 9, 19, 6),
  expiresUtc: DateTime.utc(2026, 9, 21, 6),
  currency: 'NPR',
  includedSubtotal: 1420,
  includedLineCount: 2,
  headline:
      'A refill basket you can change or ignore — 2 item(s) ready to '
      'review.',
  caveat:
      'These are estimates from what you have bought before — we cannot see '
      'what you still have at home.',
  lines: [
    RefillPlanLineDto(
      productId: 'p-ready',
      productVariantId: 'v-ready',
      productName: 'Aloe Face Wash',
      variantLabel: '200 ml',
      thumbnailUrl: 'https://cdn.example/aloe.jpg',
      quantity: 2,
      lastPaidPrice: 450,
      lastPaidCurrency: 'NPR',
      currentPrice: 450,
      currentCurrency: 'NPR',
      check: 'ready',
      included: true,
      lastPurchasedUtc: DateTime.utc(2026, 8, 20),
      typicalIntervalDays: 30,
      daysUntilExpected: 4,
      reason: 'Based on your typical 30-day restock cycle',
    ),
    RefillPlanLineDto(
      productId: 'p-changed',
      productVariantId: 'v-changed',
      productName: 'Cotton Socks',
      variantLabel: 'Medium',
      thumbnailUrl: 'https://cdn.example/socks.jpg',
      quantity: 1,
      lastPaidPrice: 300,
      lastPaidCurrency: 'NPR',
      currentPrice: 520,
      currentCurrency: 'NPR',
      check: 'priceChanged',
      included: true,
      lastPurchasedUtc: DateTime.utc(2026, 8, 25),
      typicalIntervalDays: 21,
      daysUntilExpected: 1,
      reason: 'Based on your typical 21-day restock cycle',
    ),
    RefillPlanLineDto(
      productId: 'p-unchecked',
      productVariantId: 'v-unchecked',
      productName: 'Bamboo Toothbrush',
      thumbnailUrl: 'https://cdn.example/brush.jpg',
      quantity: 3,
      lastPaidPrice: 180,
      lastPaidCurrency: 'NPR',
      // Null on purpose: the platform could not read this one.
      check: 'notVerified',
      included: false,
      excludedReason:
          "We could not check this item's price and stock just now, so we "
          'left it out.',
      lastPurchasedUtc: DateTime.utc(2026, 7, 30),
      typicalIntervalDays: 60,
      daysUntilExpected: 6,
      reason: 'Based on your typical 60-day restock cycle',
    ),
    RefillPlanLineDto(
      productId: 'p-oos',
      productVariantId: 'v-oos',
      productName: 'Green Tea Pack',
      thumbnailUrl: 'https://cdn.example/tea.jpg',
      quantity: 2,
      lastPaidPrice: 240,
      lastPaidCurrency: 'NPR',
      currentPrice: 240,
      currentCurrency: 'NPR',
      check: 'outOfStock',
      included: false,
      excludedReason: 'There is not enough in stock for your usual quantity.',
      lastPurchasedUtc: DateTime.utc(2026, 8, 12),
      typicalIntervalDays: 45,
      daysUntilExpected: 8,
      reason: 'Based on your typical 45-day restock cycle',
      alternatives: const [
        RefillAlternativeDto(
          productVariantId: 'v-oos-alt',
          sku: 'TEA-100G',
          price: 140,
          currency: 'NPR',
        ),
      ],
    ),
  ],
  deliveryGroups: const [
    RefillPlanGroupDto(
      vendorAccountId: 'vendor-1',
      vendorName: 'Himalaya Essentials',
      lineCount: 2,
      subtotal: 1420,
      currency: 'NPR',
    ),
  ],
);

/// The approval's reply, with the boundary stated in the payload itself.
final RefillPlanHandoffDto fixtureHandoff = RefillPlanHandoffDto(
  planId: 'plan-1',
  confirmedUtc: DateTime.utc(2026, 9, 19, 7),
  currency: 'NPR',
  subtotal: 1420,
  note:
      'Approved. Nothing has been ordered, reserved or charged — these items '
      'are ready for your cart.',
  lines: const [
    RefillHandoffLineDto(
      productId: 'p-ready',
      productVariantId: 'v-ready',
      quantity: 2,
    ),
    RefillHandoffLineDto(
      productId: 'p-changed',
      productVariantId: 'v-changed',
      quantity: 1,
    ),
  ],
);

/// Every run of digits the payload actually contains, plus the digits of each
/// money figure as the app formats it.
///
/// Nothing else may appear on the screen. The four fabrications this codebase
/// has already shipped to customers all began as a figure no payload held.
Set<String> figuresTheServerSent(RefillPlanDto plan) {
  final digits = RegExp(r'\d+');
  final allowed = <String>{};

  void add(String text) =>
      allowed.addAll(digits.allMatches(text).map((m) => m.group(0)!));

  void addMoney(double amount, String currency) =>
      add(formatMoney(Money(amount: amount, currency: currency)));

  add(plan.headline);
  add(plan.caveat);
  add('${plan.includedLineCount}');
  addMoney(plan.includedSubtotal, plan.currency);

  for (final line in plan.lines) {
    add(line.productName);
    add(line.variantLabel ?? '');
    add(line.reason);
    add(line.excludedReason ?? '');
    add('${line.quantity}');
    add('${line.daysUntilExpected}');
    add('${line.typicalIntervalDays}');
    addMoney(line.lastPaidPrice, line.lastPaidCurrency);
    if (line.currentPrice != null) {
      addMoney(
        line.currentPrice!,
        line.currentCurrency ?? line.lastPaidCurrency,
      );
    }
    for (final alternative in line.alternatives) {
      add(alternative.sku);
      addMoney(alternative.price, alternative.currency);
    }
  }

  for (final group in plan.deliveryGroups) {
    add(group.vendorName);
    add('${group.lineCount}');
    addMoney(group.subtotal, group.currency);
  }

  return allowed;
}

/// Every string the widget tree actually draws.
List<String> renderedText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];

/// A phone-width view tall enough that a lazy [ListView] builds the whole
/// screen.
///
/// These tests assert on what the screen *says* — every line, every total,
/// the confirm copy — and a viewport-height view would let a rule quietly
/// stop being rendered while the test still passed because the widget was
/// simply never built. The 320dp layout tests deliberately use the real
/// phone height instead.
void setTallPhoneView(WidgetTester tester, {double width = 390}) {
  tester.view
    ..physicalSize = Size(width, 4000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A control is accessible when a screen reader can *find* it by its spoken
/// label and it will actually respond to a tap. Both halves are asserted,
/// because a label on a disabled control is no more use than no label at all.
void expectLabelledAndTappable(
  WidgetTester tester,
  Key key,
  String spokenLabel,
) {
  expect(
    find.bySemanticsLabel(spokenLabel),
    findsOneWidget,
    reason: 'no control announces itself as "$spokenLabel"',
  );
  final button = tester.widget(find.byKey(key));
  final onPressed = (button as dynamic).onPressed;
  expect(onPressed, isNotNull, reason: '$key offers no tap action');
}
