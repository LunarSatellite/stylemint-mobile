import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/replenishment_rules_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/replenishment_rules_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/replenishment_rules_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';

import '../../../orders_test_harness.dart';
import 'refill_plan_test_doubles.dart';

/// The rules the customer sets, and the two things the screen refuses to do:
/// offer an automation level that does not exist, and let a value outside a
/// rule's range leave the device.
void main() {
  late FakeRefillPlanDataSource data;

  setUp(() {
    data = FakeRefillPlanDataSource()..preferenceValue = preparingPreference;
  });

  Widget app({bool personalizationAllowed = true, double textScale = 1}) =>
      ProviderScope(
        overrides: [
          refillPlanDataSourceProvider.overrideWithValue(data),
          personalizationAllowedProvider.overrideWith(
            (ref) async => personalizationAllowed,
          ),
        ],
        child: ordersTestApp(
          const ReplenishmentRulesScreen(),
          textScale: textScale,
          wrapInScaffold: false,
        ),
      );

  group('every rule the backend accepts is settable', () {
    testWidgets('all seven controls are on the screen', (tester) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      for (final key in const [
        // automation level — both values, and only both
        ValueKey('rule-automation-remindOnly'),
        ValueKey('rule-automation-prepareBasket'),
        // steadiness — all three
        ValueKey('rule-steadiness-any'),
        ValueKey('rule-steadiness-steady'),
        ValueKey('rule-steadiness-verySteady'),
        // lead time, frequency, spending limit, substitutions
        ValueKey('rule-lead-time'),
        ValueKey('rule-frequency'),
        ValueKey('rule-limit-amount'),
        ValueKey('rule-limit-currency'),
        ValueKey('rule-substitutions'),
        // and the pause
        ValueKey('rule-pause-7'),
      ]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key is missing');
      }
    });

    testWidgets('a changed rule set round-trips through the backend', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Change every rule away from its loaded value.
      await tester.tap(
        find.byKey(const ValueKey('rule-automation-remindOnly')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('rule-steadiness-verySteady')),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('rule-lead-time')),
        const Offset(-400, 0),
      );
      await tester.pump();
      await tester.drag(
        find.byKey(const ValueKey('rule-frequency')),
        const Offset(400, 0),
      );
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('rule-limit-amount')),
        '5000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('rule-limit-currency')),
        'npr',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('rule-substitutions')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('rule-save')));
      await tester.pumpAndSettle();

      expect(data.savedRules, hasLength(1));
      final sent = data.savedRules.single;
      expect(sent.automationLevel, ReplenishmentAutomationLevel.remindOnly);
      expect(sent.steadiness, ReplenishmentSteadiness.verySteady);
      expect(sent.leadTimeDays, ReplenishmentRulesRequest.minLeadTimeDays);
      expect(
        sent.minDaysBetweenPlans,
        ReplenishmentRulesRequest.maxFrequencyDays,
      );
      expect(sent.maxPlanAmount, 5000);
      expect(sent.maxPlanCurrency, 'NPR');
      expect(sent.allowSubstitutions, isTrue);

      // What the screen shows afterwards is what the backend stored.
      expect(data.preferenceValue.steadiness, 'verySteady');
      expect(data.preferenceValue.maxPlanAmount, 5000);
      expect(data.preferenceValue.allowSubstitutions, isTrue);
    });

    testWidgets('clearing the amount clears the currency with it', (
      tester,
    ) async {
      data.preferenceValue = preparingPreference.copyWith(
        maxPlanAmount: 5000,
        maxPlanCurrency: 'NPR',
      );
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('rule-limit-amount')),
        '',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('rule-save')));
      await tester.pumpAndSettle();

      expect(data.savedRules.single.maxPlanAmount, isNull);
      expect(data.savedRules.single.maxPlanCurrency, isNull);
    });

    testWidgets('the pause is set and lifted, and says it lifts itself', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.textContaining('lifts itself'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rule-pause-7')));
      await tester.pumpAndSettle();

      expect(data.pauses, hasLength(1));
      expect(data.pauses.single, isNotNull);
      expect(data.pauses.single!.isAfter(DateTime.now().toUtc()), isTrue);

      // And it can be ended early, which is a null instant.
      await tester.tap(find.byKey(const ValueKey('rule-resume')));
      await tester.pumpAndSettle();
      expect(data.pauses, [isNotNull, isNull]);
    });
  });

  group('there is no third automation level', () {
    testWidgets('exactly two are offered, and the copy says so', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(ReplenishmentAutomationLevel.values, hasLength(2));
      expect(find.text('Just remind me'), findsOneWidget);
      expect(find.text('Prepare a basket I can review'), findsOneWidget);
      expect(
        find.textContaining('There are two settings and there is no third'),
        findsOneWidget,
      );

      final rendered = renderedText(tester).join(' ').toLowerCase();
      for (final banned in [
        'order it for me',
        'order automatically',
        'auto-order',
        'automatic ordering',
        'buy it for me',
      ]) {
        expect(
          rendered.contains(banned),
          isFalse,
          reason: 'the screen offered "$banned"',
        );
      }
    });
  });

  group('steadiness is not a confidence figure', () {
    testWidgets('no score, threshold or percentage is shown', (tester) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final rendered = renderedText(tester).join(' ').toLowerCase();
      for (final banned in [
        'confidence',
        'score',
        'threshold',
        'probability',
        'certainty',
        '%',
        '0.4',
        '0.6',
        '0.8',
      ]) {
        expect(
          rendered.contains(banned),
          isFalse,
          reason: 'the screen said "$banned"',
        );
      }
    });
  });

  group('substitutions default to off', () {
    testWidgets('a customer who has said nothing has the switch off', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(preparingPreference.allowSubstitutions, isFalse);
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('rule-substitutions')),
      );
      expect(toggle.value, isFalse);
    });
  });

  group('a value outside its range is refused client-side', () {
    test('the request itself refuses a lead time outside 1-30', () {
      final base = preparingPreference.toRequest();
      expect(base.validationError, isNull);
      expect(base.copyWith(leadTimeDays: 0).validationError, isNotNull);
      expect(base.copyWith(leadTimeDays: 31).validationError, isNotNull);
      expect(base.copyWith(leadTimeDays: 1).validationError, isNull);
      expect(base.copyWith(leadTimeDays: 30).validationError, isNull);
      expect(base.copyWith(minDaysBetweenPlans: 0).validationError, isNotNull);
      expect(base.copyWith(minDaysBetweenPlans: 91).validationError, isNotNull);
      expect(base.copyWith(maxPlanAmount: 100.0).validationError, isNotNull);
    });

    test('the notifier never sends an out-of-range value', () async {
      final fake = FakeRefillPlanDataSource();
      final notifier = ReplenishmentRulesNotifier(fake);
      await Future<void>.delayed(Duration.zero);

      final saved = await notifier.save(
        preparingPreference.toRequest().copyWith(leadTimeDays: 45),
      );

      expect(saved, isFalse);
      expect(fake.savedRules, isEmpty, reason: 'an illegal value left the app');
      final state = notifier.state as ReplenishmentRulesLoaded;
      expect(state.error, contains('between 1 and 30 days'));
      notifier.dispose();
    });

    testWidgets('the slider itself cannot leave the range', (tester) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const ValueKey('rule-lead-time')),
      );
      expect(slider.min, ReplenishmentRulesRequest.minLeadTimeDays.toDouble());
      expect(slider.max, ReplenishmentRulesRequest.maxLeadTimeDays.toDouble());

      // Dragged hard past either end, the saved value stays inside the range.
      await tester.drag(
        find.byKey(const ValueKey('rule-lead-time')),
        const Offset(-2000, 0),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('rule-save')));
      await tester.pumpAndSettle();
      expect(
        data.savedRules.single.leadTimeDays,
        inInclusiveRange(
          ReplenishmentRulesRequest.minLeadTimeDays,
          ReplenishmentRulesRequest.maxLeadTimeDays,
        ),
      );
    });
  });

  group('consent', () {
    testWidgets('a refused customer sees no controls and nothing is read', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app(personalizationAllowed: false));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('rule-save')), findsNothing);
      expect(find.byType(Slider), findsNothing);
      expect(data.preferenceCalls, 0);
    });
  });

  group('layout and semantics', () {
    testWidgets('does not overflow at 320dp with text scale 1.3', (
      tester,
    ) async {
      setPhoneView(tester, width: 320);
      await tester.pumpWidget(app(textScale: 1.3));
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);
    });

    testWidgets('every control is labelled and offers an action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Every choice announces its own name and what it means, and every
      // button announces what pressing it does.
      for (final key in const [
        ValueKey('rule-automation-remindOnly'),
        ValueKey('rule-automation-prepareBasket'),
        ValueKey('rule-steadiness-any'),
        ValueKey('rule-steadiness-steady'),
        ValueKey('rule-steadiness-verySteady'),
      ]) {
        final node = tester.getSemantics(find.byKey(key));
        expect(node.label, isNotEmpty, reason: '$key has no label');
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$key offers no tap action',
        );
        // A choice says whether it is the one in force, so a screen-reader
        // user is never left guessing which rule is currently set.
        final shouldBeSelected =
            key == const ValueKey('rule-automation-prepareBasket') ||
            key == const ValueKey('rule-steadiness-any');
        expect(
          node.getSemanticsData().flagsCollection.isSelected,
          shouldBeSelected ? Tristate.isTrue : Tristate.isFalse,
          reason: '$key announces the wrong selected state',
        );
      }
      expectLabelledAndTappable(
        tester,
        const ValueKey('rule-save'),
        'Save these rules',
      );
      expectLabelledAndTappable(
        tester,
        const ValueKey('rule-pause-7'),
        'Pause restock for 7 days',
      );

      // Each slider is named, announces its value in whole days rather than
      // as a raw number, and can be nudged by a screen reader.
      for (final (key, name, spokenValue) in const [
        (ValueKey('rule-lead-time'), 'Lead time', '10 days ahead'),
        (
          ValueKey('rule-frequency'),
          'Days between baskets',
          'At most once every 14 days',
        ),
      ]) {
        expect(
          find.bySemanticsLabel(name),
          findsOneWidget,
          reason: '$key is not named to a screen reader',
        );
        // The current value is stated in whole days, in words, above the
        // control — never left as a bare position on a track.
        expect(
          find.text(spokenValue),
          findsOneWidget,
          reason: '$key does not state "$spokenValue"',
        );
        final node = tester.getSemantics(find.byKey(key));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.increase) ||
              node.getSemanticsData().hasAction(SemanticsAction.decrease),
          isTrue,
          reason: '$key cannot be nudged by a screen reader',
        );
        expect(
          tester.widget<Slider>(find.byKey(key)).onChanged,
          isNotNull,
          reason: '$key cannot be adjusted',
        );
      }

      handle.dispose();
    });
  });
}
