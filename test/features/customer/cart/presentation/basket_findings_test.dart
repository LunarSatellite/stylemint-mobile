import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_finding.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/basket_findings_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

class _MockCartRepository extends Mock implements CartRepository {}

const _zero = Money(amount: 0, currency: 'NPR');

const _cart = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'prod-1',
      productName: 'Linen shirt',
      productImageUrl: 'https://example.test/shirt.jpg',
      variantName: 'M / White',
      quantity: 1,
      unitPrice: Money(amount: 2500, currency: 'NPR'),
      isInStock: true,
    ),
    CartItem(
      id: 'line-2',
      productId: 'prod-2',
      productName: 'Paint thinner',
      productImageUrl: 'https://example.test/thinner.jpg',
      variantName: '1 L',
      quantity: 2,
      unitPrice: Money(amount: 800, currency: 'NPR'),
      isInStock: true,
    ),
  ],
  subtotal: Money(amount: 4100, currency: 'NPR'),
  shippingTotal: _zero,
  taxTotal: _zero,
  total: Money(amount: 4100, currency: 'NPR'),
);

// ── Wire fixtures, in the exact shape GET /v1/cart/optimize sends ──────────

Map<String, dynamic> _restrictedItemJson() => <String, dynamic>{
  'kind': 'restrictedItem',
  'stage': 'inspect',
  'headline': '"Paint thinner" carries a restriction',
  'detail':
      'This item is age-gated, so whoever accepts the delivery has to clear '
      'the same age check. Your basket has not been changed.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Recorded restriction',
      'value': 'Age restricted',
      'source': 'catalog.product_restriction',
    },
    <String, dynamic>{
      'label': 'Minimum age',
      'value': '18 years',
      'source': 'catalog.product_restriction',
    },
  ],
  'lineIds': <dynamic>['line-2'],
  'suggestedAction': null,
};

Map<String, dynamic> _priceChangedJson() => <String, dynamic>{
  'kind': 'priceChanged',
  'stage': 'inspect',
  'headline': '"Linen shirt" has gone up since you added it',
  'detail': 'You will be charged the current price at checkout.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Price when added',
      'value': 'NPR 2,500.00',
      'source': 'cart.line',
    },
    <String, dynamic>{
      'label': 'Price now',
      'value': 'NPR 2,750.00',
      'source': 'catalog.product_variant',
    },
  ],
  'lineIds': <dynamic>['line-1'],
  'suggestedAction': null,
};

Map<String, dynamic> _duplicateListingJson() => <String, dynamic>{
  'kind': 'duplicateListing',
  'stage': 'inspect',
  'headline': 'Two lines hold the same listing',
  'detail': 'Your basket has not been changed.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Listing',
      'value': 'Linen shirt',
      'source': 'cart.line',
    },
  ],
  'lineIds': <dynamic>['line-1'],
  'suggestedAction': <String, dynamic>{
    'kind': 'reviewLines',
    'label': 'Review these lines',
    'method': 'DELETE',
    'path': '/v1/cart/lines/{lineId}',
  },
};

Map<String, dynamic> _betterValueJson() => <String, dynamic>{
  'kind': 'betterValuePerUnit',
  'stage': 'compare',
  'headline': 'A same-category listing costs less per gram',
  'detail':
      'Both listings answered the same recorded measure. Your basket has '
      'not been changed.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Your line, per unit',
      'value': '0.8 NPR per g',
      'source': 'catalog.product_attribute_value',
    },
    <String, dynamic>{
      'label': 'The alternative, per unit',
      'value': '0.5 NPR per g',
      'source': 'catalog.product_attribute_value',
    },
  ],
  'lineIds': <dynamic>['line-1'],
  'suggestedAction': <String, dynamic>{
    'kind': 'openProduct',
    'label': 'Look at "Linen shirt, 3-pack"',
    'method': 'GET',
    'path': '/v1/public/products/prod-9',
  },
};

Map<String, dynamic> _unknownKindJson() => <String, dynamic>{
  // A kind added after this build shipped.
  'kind': 'vendorHolidayClosure',
  'stage': 'coordinate',
  'headline': 'One vendor is closed next week',
  'detail': 'Recorded closure dates. Your basket has not been changed.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Closed from',
      'value': '2026-10-01',
      'source': 'vendor.calendar',
    },
  ],
  'lineIds': <dynamic>['line-1'],
  'suggestedAction': null,
};

Map<String, dynamic> _unknownActionKindJson() => <String, dynamic>{
  'kind': 'slowestLine',
  'stage': 'coordinate',
  'headline': 'One line sets the whole delivery date',
  'detail': 'Your basket has not been changed.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Processing time',
      'value': '7 days',
      'source': 'catalog.product',
    },
  ],
  'lineIds': <dynamic>['line-1'],
  'suggestedAction': <String, dynamic>{
    // Not a kind this build maps to any client path.
    'kind': 'reserveStockForCustomer',
    'label': 'Reserve it now',
    'method': 'POST',
    'path': '/v1/cart/reserve',
  },
};

/// Every string the tree actually draws.
List<String> _renderedText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];

void main() {
  late _MockCartRepository repository;

  setUp(() {
    repository = _MockCartRepository();
    when(() => repository.getCart()).thenAnswer((_) async => right(_cart));
  });

  void stubFindings(List<Map<String, dynamic>> findings) {
    when(() => repository.getBasketOptimization()).thenAnswer(
      (_) async => right(
        BasketOptimization(
          insights: const [],
          findings: BasketFinding.listFromJson(findings),
        ),
      ),
    );
  }

  Future<void> pumpCart(
    WidgetTester tester, {
    Size size = const Size(1080, 2400),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: RouteNames.cart,
      routes: [
        GoRoute(path: RouteNames.cart, builder: (_, _) => const CartScreen()),
        GoRoute(
          path: RouteNames.productDetail,
          builder: (_, state) =>
              Scaffold(body: Text('PDP ${state.pathParameters['productId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
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
    await tester.pumpAndSettle();
  }

  group('rendering', () {
    testWidgets('a finding renders its headline, detail, facts and sources', (
      tester,
    ) async {
      stubFindings([_priceChangedJson()]);
      await pumpCart(tester);

      expect(find.text('What we noticed'), findsOneWidget);
      expect(
        find.text('"Linen shirt" has gone up since you added it'),
        findsOneWidget,
      );
      expect(
        find.text('You will be charged the current price at checkout.'),
        findsOneWidget,
      );
      // Facts, verbatim, each above the record it came from.
      expect(find.text('Price when added'), findsOneWidget);
      expect(find.text('NPR 2,500.00'), findsOneWidget);
      expect(find.text('Source: cart.line'), findsOneWidget);
      expect(find.text('Price now'), findsOneWidget);
      expect(find.text('NPR 2,750.00'), findsOneWidget);
      expect(find.text('Source: catalog.product_variant'), findsOneWidget);
    });

    testWidgets('an empty findings array renders nothing at all', (
      tester,
    ) async {
      stubFindings([]);
      await pumpCart(tester);

      expect(find.byType(BasketFindingCard), findsNothing);
      expect(find.text('What we noticed'), findsNothing);
      // No reassurance the backend never made.
      final rendered = _renderedText(tester).join(' ').toLowerCase();
      expect(rendered.contains('looks good'), isFalse);
      expect(rendered.contains('nothing to report'), isFalse);
      expect(rendered.contains('no issues'), isFalse);
      expect(rendered.contains('all good'), isFalse);
    });

    testWidgets('safety and price integrity sort above the rest', (
      tester,
    ) async {
      // Deliberately sent last-first by the fixture.
      stubFindings([
        _betterValueJson(),
        _duplicateListingJson(),
        _priceChangedJson(),
        _restrictedItemJson(),
      ]);
      await pumpCart(tester);

      final cards = tester
          .widgetList<BasketFindingCard>(find.byType(BasketFindingCard))
          .toList();
      expect(cards.length, 4);
      expect(cards[0].finding.kind, BasketFindingKind.restrictedItem);
      expect(cards[1].finding.kind, BasketFindingKind.priceChanged);
      // The rest keep the backend's own order.
      expect(cards[2].finding.kind, BasketFindingKind.betterValuePerUnit);
      expect(cards[3].finding.kind, BasketFindingKind.duplicateListing);
    });

    testWidgets('the layout does not look broken without betterValuePerUnit', (
      tester,
    ) async {
      stubFindings([_duplicateListingJson()]);
      await pumpCart(tester);

      expect(find.byType(BasketFindingCard), findsOneWidget);
      expect(find.text('Two lines hold the same listing'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('degrading gracefully', () {
    testWidgets('an unknown kind still renders headline, detail and facts', (
      tester,
    ) async {
      stubFindings([_unknownKindJson()]);
      await pumpCart(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(BasketFindingCard), findsOneWidget);
      expect(find.text('One vendor is closed next week'), findsOneWidget);
      expect(
        find.text('Recorded closure dates. Your basket has not been changed.'),
        findsOneWidget,
      );
      expect(find.text('Closed from'), findsOneWidget);
      expect(find.text('2026-10-01'), findsOneWidget);
      expect(find.text('Source: vendor.calendar'), findsOneWidget);
      // The raw kind survives parsing without the UI guessing its meaning.
      final card = tester.widget<BasketFindingCard>(
        find.byType(BasketFindingCard),
      );
      expect(card.finding.kind, BasketFindingKind.unknown);
      expect(card.finding.rawKind, 'vendorHolidayClosure');
      // The kind is never spelled out at the customer as if it were a label.
      expect(find.text('vendorHolidayClosure'), findsNothing);
    });

    testWidgets('an unknown action kind renders no button', (tester) async {
      stubFindings([_unknownActionKindJson()]);
      await pumpCart(tester);

      expect(find.byType(BasketFindingCard), findsOneWidget);
      expect(find.text('Reserve it now'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BasketFindingCard),
          matching: find.byType(OutlinedButton),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'an openProduct action whose path is not a product is ignored',
      (
        tester,
      ) async {
        final json = _betterValueJson();
        (json['suggestedAction']! as Map<String, dynamic>)['path'] =
            '/v1/something/else';
        stubFindings([json]);
        await pumpCart(tester);

        expect(find.byType(BasketFindingCard), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BasketFindingCard),
            matching: find.byType(OutlinedButton),
          ),
          findsNothing,
        );
      },
    );
  });

  group('no invented numbers', () {
    testWidgets('no aggregate, score, percentage or total is rendered', (
      tester,
    ) async {
      stubFindings([
        _restrictedItemJson(),
        _priceChangedJson(),
        _duplicateListingJson(),
        _betterValueJson(),
        _unknownKindJson(),
      ]);
      await pumpCart(tester);

      final section = find.byType(BasketFindingsList);
      final texts = [
        for (final text in tester.widgetList<Text>(
          find.descendant(of: section, matching: find.byType(Text)),
        ))
          (text.data ?? text.textSpan?.toPlainText() ?? '').toLowerCase(),
      ];
      expect(texts, isNotEmpty);
      final blob = texts.join(' | ');

      for (final banned in [
        'score',
        'confidence',
        'certainty',
        'rating',
        'total saving',
        'you could save',
        'in total',
        'altogether',
        'findings found',
        'issues found',
        'estimated',
      ]) {
        expect(blob.contains(banned), isFalse, reason: 'rendered "$banned"');
      }
      // No percentage anywhere, and no "N findings"-style count.
      expect(blob.contains('%'), isFalse);
      expect(
        RegExp(
          r'\b\d+\s+(findings?|issues?|problems?|items? flagged)\b',
        ).hasMatch(blob),
        isFalse,
      );

      // Every number on screen traces to a fact value the backend sent.
      final factValues = {
        for (final card in tester.widgetList<BasketFindingCard>(
          find.byType(BasketFindingCard),
        ))
          for (final fact in card.finding.facts) fact.value.toLowerCase(),
      };
      final numeric = RegExp(r'\d');
      for (final text in texts) {
        if (!numeric.hasMatch(text)) continue;
        final fromBackend =
            factValues.contains(text) ||
            tester
                .widgetList<BasketFindingCard>(find.byType(BasketFindingCard))
                .any(
                  (c) =>
                      c.finding.headline.toLowerCase() == text ||
                      c.finding.detail.toLowerCase() == text ||
                      c.finding.suggestedAction?.label.toLowerCase() == text,
                );
        expect(
          fromBackend,
          isTrue,
          reason: 'a number the backend did not send: "$text"',
        );
      }
    });
  });

  group('restrictedItem weight', () {
    testWidgets('is distinguishable without colour', (tester) async {
      stubFindings([_restrictedItemJson(), _duplicateListingJson()]);
      await pumpCart(tester);

      // Carrier 1: its own word.
      expect(find.text('Safety check'), findsOneWidget);
      // Carrier 2: its own glyph on the pill.
      final pill = tester.widget<MallStatusPill>(
        find.byType(MallStatusPill).first,
      );
      expect(pill.label, 'Safety check');
      expect(pill.icon, Icons.gpp_maybe_outlined);
      expect(pill.icon, isNot(equals(Icons.copy_all_outlined)));
      // Carrier 3: a heavier rule than any other card's.
      final borders = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(BasketFindingCard),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.border != null)
          .map((d) => (d.border! as Border).top.width)
          .toList();
      expect(borders.first, 2);
      expect(borders.skip(1).every((w) => w < 2), isTrue);
    });

    testWidgets('is never phrased as an upsell', (tester) async {
      stubFindings([_restrictedItemJson()]);
      await pumpCart(tester);

      final card = find.byType(BasketFindingCard);
      final blob = [
        for (final text in tester.widgetList<Text>(
          find.descendant(of: card, matching: find.byType(Text)),
        ))
          (text.data ?? '').toLowerCase(),
      ].join(' ');
      for (final banned in [
        'deal',
        'save',
        'cheaper',
        'offer',
        'upgrade',
        'instead',
        'better',
      ]) {
        expect(blob.contains(banned), isFalse, reason: 'upsell word "$banned"');
      }
      // And it offers no action button of its own.
      expect(
        find.descendant(of: card, matching: find.byType(OutlinedButton)),
        findsNothing,
      );
    });
  });

  group('the customer decides', () {
    testWidgets('rendering calls no mutating endpoint', (tester) async {
      stubFindings([
        _restrictedItemJson(),
        _duplicateListingJson(),
        _betterValueJson(),
      ]);
      await pumpCart(tester);

      verifyNever(
        () => repository.removeCartItem(any()),
      );
      verifyNever(
        () => repository.updateCartItem(
          itemId: any(named: 'itemId'),
          quantity: any(named: 'quantity'),
        ),
      );
      verifyNever(() => repository.saveForLater(any()));
      verifyNever(() => repository.applyPromo(any()));
    });

    testWidgets('a "review these lines" tap only moves the viewport', (
      tester,
    ) async {
      stubFindings([_duplicateListingJson()]);
      await pumpCart(tester);

      await tester.tap(find.text('Review these lines'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.removeCartItem(any()));
      verifyNever(
        () => repository.updateCartItem(
          itemId: any(named: 'itemId'),
          quantity: any(named: 'quantity'),
        ),
      );
      // Still on the cart, nothing deleted.
      expect(find.byType(CartScreen), findsOneWidget);
    });

    testWidgets('an openProduct tap navigates through the client route', (
      tester,
    ) async {
      stubFindings([_betterValueJson()]);
      await pumpCart(tester);

      await tester.tap(find.text('Look at "Linen shirt, 3-pack"'));
      await tester.pumpAndSettle();

      expect(find.text('PDP prod-9'), findsOneWidget);
      verifyNever(() => repository.removeCartItem(any()));
    });
  });

  group('accessibility and layout', () {
    testWidgets('the whole cart screen has no overflow at 320dp and 1.3', (
      tester,
    ) async {
      // This used to pump `BasketFindingsList` on its own, because the
      // checkout bar overflowed at this size and would have failed the test
      // for a reason that had nothing to do with the findings. That bar is
      // fixed (it wraps now), so the real screen is what gets asserted.
      stubFindings([
        _restrictedItemJson(),
        _priceChangedJson(),
        _duplicateListingJson(),
        _betterValueJson(),
        _unknownKindJson(),
        _unknownActionKindJson(),
      ]);

      await pumpCart(
        tester,
        size: const Size(320, 640),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(BasketFindingCard), findsNWidgets(6));
      // The checkout bar in particular: it is the widest fixed-width thing
      // on the screen and the one that used to blow out.
      expect(find.text('Proceed to checkout'), findsOneWidget);
    });

    testWidgets('every control carries a semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      stubFindings([_duplicateListingJson(), _betterValueJson()]);
      await pumpCart(tester);

      final buttons = find.descendant(
        of: find.byType(BasketFindingsList),
        matching: find.byType(OutlinedButton),
      );
      expect(buttons, findsNWidgets(2));
      for (final label in [
        'Review these lines',
        'Look at "Linen shirt, 3-pack"',
      ]) {
        expect(
          find.bySemanticsLabel(label),
          findsOneWidget,
          reason: 'no semantics label for "$label"',
        );
      }
      // The pills and the facts speak too.
      expect(
        find.bySemanticsLabel('Listing: Linen shirt. Source: cart.line'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Duplicate'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a safety pill announces itself as a safety check', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      stubFindings([_restrictedItemJson()]);
      await pumpCart(tester);

      expect(
        find.bySemanticsLabel('Safety check on this basket line'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('parsing', () {
    test('an absent findings key yields an empty list', () {
      expect(BasketFinding.listFromJson(null), isEmpty);
      expect(BasketFinding.listFromJson(<dynamic>[]), isEmpty);
      expect(
        const BasketOptimization(insights: []).findings,
        isEmpty,
      );
    });

    test(
      'a finding with no headline is dropped rather than rendered blank',
      () {
        final parsed = BasketFinding.listFromJson(<dynamic>[
          <String, dynamic>{'kind': 'priceChanged', 'facts': <dynamic>[]},
          _priceChangedJson(),
        ]);
        expect(parsed.length, 1);
        expect(parsed.single.kind, BasketFindingKind.priceChanged);
      },
    );

    test('an unknown kind and stage parse without throwing', () {
      final parsed = BasketFinding.listFromJson(<dynamic>[
        <String, dynamic>{
          'kind': 'somethingNew',
          'stage': 'somethingElse',
          'headline': 'Noticed',
          'detail': 'Detail',
          'facts': <dynamic>[
            <String, dynamic>{
              'label': 'L',
              'value': 'V',
              'source': 'some.record',
            },
          ],
          'lineIds': <dynamic>[],
        },
      ]);
      expect(parsed.single.kind, BasketFindingKind.unknown);
      expect(parsed.single.stage, BasketFindingStage.unknown);
      expect(parsed.single.rawKind, 'somethingNew');
      expect(parsed.single.facts.single.source, 'some.record');
    });

    test('ordering is stable inside each band', () {
      final parsed = BasketFinding.listFromJson(<dynamic>[
        _duplicateListingJson(),
        _betterValueJson(),
        _priceChangedJson(),
        _restrictedItemJson(),
      ]);
      final ordered = orderBasketFindings(parsed);
      expect(ordered.map((f) => f.kind).toList(), [
        BasketFindingKind.restrictedItem,
        BasketFindingKind.priceChanged,
        BasketFindingKind.duplicateListing,
        BasketFindingKind.betterValuePerUnit,
      ]);
    });
  });
}
