import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';

import 'checkout_harness.dart';

/// Right edge of [finder]'s widget, in logical pixels from the screen's left.
///
/// A `RenderFlex` that overflows still lays its children out at their natural
/// size and positions them past the edge, so this is the direct reading of
/// "did that widget end up off-screen" — sharper than only asking whether an
/// exception was thrown, and it names the widget that moved.
double _rightEdge(WidgetTester tester, Finder finder) =>
    tester.getRect(finder).right;

void main() {
  late MockCheckoutRepository repository;

  setUp(() {
    repository = MockCheckoutRepository();
    stubCheckout(repository);
  });

  group('the whole checkout screen lays out', () {
    testCheckoutLayouts('with a saved address and a six-figure total', (
      tester,
      width,
      scale,
    ) async {
      await pumpCheckout(tester, repository, width: width, textScale: scale);

      expectNoLayoutErrors(tester);
      // The screen really rendered — a silent error state would pass an
      // overflow check for the wrong reason.
      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.text(typedAddressLabel), findsOneWidget);
    });

    testCheckoutLayouts('before any address is saved', (
      tester,
      width,
      scale,
    ) async {
      stubCheckout(repository, summary: noAddressSummary);
      await pumpCheckout(tester, repository, width: width, textScale: scale);

      expectNoLayoutErrors(tester);
      expect(find.text('Add Shipping Address'), findsOneWidget);
    });

    testCheckoutLayouts('with the cart-items sheet open', (
      tester,
      width,
      scale,
    ) async {
      await pumpCheckout(tester, repository, width: width, textScale: scale);
      await tester.tap(
        find.text('Sub Total (${longCheckoutItems.length} items)'),
      );
      await tester.pumpAndSettle();

      expectNoLayoutErrors(tester);
      expect(
        find.text('Your Cart Items(${longCheckoutItems.length})'),
        findsOneWidget,
      );
    });

    testCheckoutLayouts('with the address picker open', (
      tester,
      width,
      scale,
    ) async {
      await pumpCheckout(tester, repository, width: width, textScale: scale);
      await tester.tap(find.text(typedAddressLabel));
      await tester.pumpAndSettle();

      expectNoLayoutErrors(tester);
      expect(find.text('Choose a Shipping Address'), findsOneWidget);
    });
  });

  group('the polished delivery card', () {
    testCheckoutLayouts(
      'keeps the "Recommended" chip on screen beside a long option title',
      (tester, width, scale) async {
        await pumpCheckout(tester, repository, width: width, textScale: scale);

        final chip = find.text('Recommended');
        if (chip.evaluate().isEmpty) return;
        expect(
          _rightEdge(tester, chip.first),
          lessThanOrEqualTo(width),
          reason: 'the recommended chip ran off the delivery card',
        );
        expectNoLayoutErrors(tester);
      },
    );
  });

  group('the fixed overflows stay fixed', () {
    // Each test below fails if its fix is reverted. Verified by reverting
    // each one in turn and watching it go red.

    testWidgets(
      'the grand total stays on screen beside a scaled-up label — '
      '320dp, text ×1.3',
      (tester) async {
        await pumpCheckout(tester, repository, width: 320, textScale: 1.3);

        final total = find.text(formatMoney(largeTotal));
        expect(total, findsOneWidget, reason: 'the total must be readable');
        // Unflexed under `spaceBetween`, a 20sp w800 "Rs 124,850.00" beside a
        // 1.3x "Grand Total" runs off a 320dp card. Wrapped, it drops to its
        // own line and stays inside.
        expect(
          _rightEdge(tester, total),
          lessThanOrEqualTo(320.0),
          reason: 'the grand total is painted off the right edge',
        );
        expectNoLayoutErrors(tester);
      },
    );

    testWidgets(
      "the shipping card's default badge stays on screen beside a "
      'customer-typed label — 320dp, text ×1.3',
      (tester) async {
        await pumpCheckout(tester, repository, width: 320, textScale: 1.3);

        expect(find.text(typedAddressLabel), findsOneWidget);
        final badge = find.text('Default');
        expect(badge, findsOneWidget);
        // The label yields (wraps) so the badge keeps its place; unflexed it
        // pushes the badge past the edge instead.
        expect(
          _rightEdge(tester, badge),
          lessThanOrEqualTo(320.0),
          reason: 'the default badge is pushed off the right edge',
        );
        expectNoLayoutErrors(tester);
      },
    );

    testWidgets(
      "the address picker's selected badge stays on screen beside a "
      'customer-typed label — 320dp, text ×1.3',
      (tester) async {
        await pumpCheckout(tester, repository, width: 320, textScale: 1.3);
        await tester.tap(find.text(typedAddressLabel));
        await tester.pumpAndSettle();

        expect(find.text('Choose a Shipping Address'), findsOneWidget);
        expect(find.text(secondTypedAddressLabel), findsOneWidget);
        final badge = find.text('Selected');
        expect(badge, findsOneWidget);
        expect(
          _rightEdge(tester, badge),
          lessThanOrEqualTo(320.0),
          reason: 'the selected badge is pushed off the right edge',
        );
        expectNoLayoutErrors(tester);
      },
    );
  });

  group('on a real small phone, scrolled end to end', () {
    // The sweep above uses a tall viewport so the lazy ListView builds every
    // card in one pass. This does the opposite: a genuine 320x640 phone,
    // scrolled to the bottom, so nothing is masked by the extra height and
    // the sticky bottom bar is laid out against real remaining space.
    testCheckoutLayouts('the checkout list scrolls without overflowing', (
      tester,
      width,
      scale,
    ) async {
      await pumpCheckout(
        tester,
        repository,
        width: width,
        textScale: scale,
        height: phoneHeight,
      );
      expectNoLayoutErrors(tester);

      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 12; i++) {
        await tester.drag(list, const Offset(0, -400));
        await tester.pumpAndSettle();
        expectNoLayoutErrors(tester);
      }

      // The list really did run to its end — otherwise this would pass by
      // never laying out the cards further down. The sticky bar is still
      // there, so the screen was rendered, not error-stated.
      final position = tester.state<ScrollableState>(list).position;
      expect(position.pixels, position.maxScrollExtent);
      expect(find.text('Place Order'), findsOneWidget);
    });
  });

  group('the payment method screen lays out', () {
    testCheckoutLayouts('with a saved card and a long label', (
      tester,
      width,
      scale,
    ) async {
      await pumpPaymentMethods(
        tester,
        repository,
        width: width,
        textScale: scale,
      );

      expectNoLayoutErrors(tester);
      expect(find.text('Payment Method'), findsOneWidget);
      expect(find.textContaining('4417'), findsOneWidget);
    });
  });
}
