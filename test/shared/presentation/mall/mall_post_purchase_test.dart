import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'mall_harness.dart';

const _steps = [
  MallTimelineStep(
    title: 'Order placed',
    state: MallStepState.done,
    timestamp: '11 Sep, 09:04',
    detail: 'Paid with eSewa',
  ),
  MallTimelineStep(
    title: 'Out for delivery with a courier whose name runs long',
    state: MallStepState.current,
    timestamp: '14 Sep, 07:30',
  ),
  MallTimelineStep(title: 'Delivered', state: MallStepState.upcoming),
];

void main() {
  group('MallStatusPill', () {
    testMallLayouts('wraps rather than truncating', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallStatusPill(
          label: 'Out for delivery with a courier whose name runs long',
          tone: MallStatusTone.progress,
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
    });

    testWidgets('every tone draws a glyph, so colour is never the only cue', (
      tester,
    ) async {
      for (final tone in MallStatusTone.values) {
        await pumpMall(tester, MallStatusPill(label: 'State', tone: tone));
        expect(
          find.descendant(
            of: find.byType(MallStatusPill),
            matching: find.byType(Icon),
          ),
          findsOneWidget,
          reason: '$tone must carry a mark as well as a colour',
        );
      }
    });

    testWidgets('distinct tones do not share a glyph', (tester) async {
      final glyphs = <MallStatusTone, IconData>{};
      for (final tone in MallStatusTone.values) {
        glyphs[tone] = mallStatusStyle(tone).icon;
      }
      // success and progress share the accent; they must not share the mark.
      expect(
        glyphs[MallStatusTone.success],
        isNot(glyphs[MallStatusTone.progress]),
      );
      expect(
        glyphs[MallStatusTone.danger],
        isNot(glyphs[MallStatusTone.caution]),
      );
    });
  });

  group('MallStatusSummary', () {
    testMallLayouts('renders the state, the promise and the stamp', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallStatusSummary(
          eyebrow: 'Order #NK2026-00015',
          title: 'Out for delivery',
          tone: MallStatusTone.progress,
          detail: 'Estimated delivery Sep 14, 2026',
          footnote: 'Placed 09:04 Sep 11, 2026',
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Out for delivery'), findsOneWidget);
      expect(find.text('Estimated delivery Sep 14, 2026'), findsOneWidget);
    });

    testWidgets('speaks as one node naming the state in words', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(
        tester,
        const MallStatusSummary(
          title: 'Cancelled',
          tone: MallStatusTone.danger,
          detail: 'Your money is coming back.',
        ),
      );
      expect(
        find.bySemanticsLabel('Cancelled. Your money is coming back.'),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('MallTimeline', () {
    testMallLayouts('lays out mixed step states without overflow', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallTimeline(steps: _steps, semanticLabel: 'Order history'),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('each step spells its state out for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(
        tester,
        const MallTimeline(steps: _steps, semanticLabel: 'Order history'),
      );
      expect(
        find.bySemanticsLabel(RegExp('Delivered. not started')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Order placed. completed')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('a step can carry evidence that stays tappable', (
      tester,
    ) async {
      var taps = 0;
      await pumpMall(
        tester,
        MallTimeline(
          steps: [
            MallTimelineStep(
              title: 'Sealed',
              state: MallStepState.done,
              trailing: TextButton(
                onPressed: () => taps++,
                child: const Text('View seal photo'),
              ),
            ),
          ],
        ),
      );
      await tester.tap(find.text('View seal photo'));
      expect(taps, 1);
    });

    testWidgets('an empty timeline draws nothing', (tester) async {
      await pumpMall(tester, const MallTimeline(steps: []));
      expect(find.byType(Icon), findsNothing);
    });
  });

  group('MallStatusStepper', () {
    testMallLayouts('fits four stages with wrapping labels', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallStatusStepper(
          semanticLabel: 'Tracking timeline',
          steps: [
            MallTimelineStep(title: 'Shipped', state: MallStepState.done),
            MallTimelineStep(title: 'In transit', state: MallStepState.done),
            MallTimelineStep(
              title: 'Out for delivery',
              state: MallStepState.current,
            ),
            MallTimelineStep(
              title: 'Delivered',
              state: MallStepState.upcoming,
            ),
          ],
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Out for delivery'), findsOneWidget);
    });

    testWidgets('marks can be addressed by key', (tester) async {
      await pumpMall(
        tester,
        const MallStatusStepper(
          steps: [
            MallTimelineStep(
              title: 'Shipped',
              state: MallStepState.done,
              markKey: ValueKey('stage-0'),
            ),
          ],
        ),
      );
      expect(find.byKey(const ValueKey('stage-0')), findsOneWidget);
    });
  });

  group('MallMoneyLedger', () {
    const amounts = [
      MallAmount(label: 'Subtotal', value: 'Rs 3,499'),
      MallAmount(
        label: 'Coupon MONSOON20',
        value: 'Rs 700',
        kind: MallAmountKind.deduction,
      ),
      MallAmount(
        label: 'Paid',
        value: 'Rs 2,899',
        kind: MallAmountKind.total,
        note: 'eSewa',
      ),
      MallAmount(
        label: 'Refund',
        value: 'Rs 1,200',
        kind: MallAmountKind.refund,
        note: 'Back to eSewa in 5-7 days',
      ),
      MallAmount(
        label: 'Still to pay',
        value: 'Rs 300',
        kind: MallAmountKind.due,
      ),
    ];

    testMallLayouts('lays out every kind of amount', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        const MallMoneyLedger(amounts: amounts, semanticLabel: 'Bill details'),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text('Rs 3,499'), findsOneWidget);
    });

    testWidgets('signs the amounts a buyer must not misread', (tester) async {
      await pumpMall(tester, const MallMoneyLedger(amounts: amounts));
      expect(find.text('-Rs 700'), findsOneWidget);
      expect(find.text('+Rs 1,200'), findsOneWidget);
      // A refund and an outstanding balance each carry a glyph too.
      expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('says in words what the number means', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpMall(tester, const MallMoneyLedger(amounts: amounts));
      expect(
        find.bySemanticsLabel(RegExp('Refund, Rs 1,200 refunded')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'Still to pay, Rs 300 still due')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('numerals are tabular so columns align', (tester) async {
      await pumpMall(tester, const MallMoneyLedger(amounts: amounts));
      final text = tester.widget<Text>(find.text('Rs 3,499'));
      expect(text.style?.fontFeatures, mallTabularFigures);
    });
  });

  group('MallErrorState', () {
    testMallLayouts('is a designed state, not a raw exception', (
      tester,
      width,
      scale,
    ) async {
      await pumpMall(
        tester,
        MallErrorState(
          title: "We couldn't load this order",
          body: 'Your order is safe. Check your connection and try again.',
          detail: 'HTTP 503 from orders-api',
          onRetry: () {},
        ),
        width: width,
        textScale: scale,
      );
      expectNoLayoutErrors(tester);
      expect(find.text("We couldn't load this order"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('HTTP 503 from orders-api'), findsOneWidget);
    });

    testWidgets('offers no action when there is nothing to retry', (
      tester,
    ) async {
      await pumpMall(tester, const MallErrorState(title: 'Nothing here'));
      expect(find.text('Try again'), findsNothing);
    });
  });
}
