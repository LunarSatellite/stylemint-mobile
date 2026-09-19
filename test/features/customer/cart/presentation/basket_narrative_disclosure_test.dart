import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/repositories/cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_finding.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/basket_findings_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/basket_insights_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';

class _MockCartRepository extends Mock implements CartRepository {}

class _MockCartRemoteDataSource extends Mock implements CartRemoteDataSource {}

/// The exact words `BasketNarrativeOptions.Disclosure` sends. Copied here so
/// the test fails if the client ever reworded, shortened or restyled them.
const _disclosure =
    'AI-written suggestion. Unlike the findings, it is not based on your '
    "basket's records and cites no source — check it before you rely on it.";

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
  ],
  subtotal: Money(amount: 2500, currency: 'NPR'),
  shippingTotal: _zero,
  taxTotal: _zero,
  total: Money(amount: 2500, currency: 'NPR'),
);

const _insight = 'Your basket leans towards linen — a light jacket would suit.';
const _tip = 'Adding one more item could unlock free delivery.';

/// One evidence-backed finding, in the wire shape `GET /v1/cart/optimize`
/// sends. Every fact carries the record it rests on.
Map<String, dynamic> _findingJson() => <String, dynamic>{
  'kind': 'priceChanged',
  'stage': 'inspect',
  'headline': '"Linen shirt" costs more than when you added it',
  'detail': 'The seller raised the price. Your basket has not been changed.',
  'facts': <dynamic>[
    <String, dynamic>{
      'label': 'Price when added',
      'value': 'NPR 2,200',
      'source': 'cart.line.unitPriceAtAdd',
    },
  ],
  'lineIds': <dynamic>['line-1'],
};

void main() {
  late _MockCartRepository repository;

  setUp(() {
    repository = _MockCartRepository();
    when(() => repository.getCart()).thenAnswer((_) async => right(_cart));
  });

  /// Stubs the optimize call. [withFindings] keeps evidence on screen so each
  /// case also asserts the findings are untouched.
  void stubOptimization({
    List<String> insights = const [],
    String? savingsTip,
    String? narrativeDisclosure,
    bool withFindings = true,
  }) {
    when(() => repository.getBasketOptimization()).thenAnswer(
      (_) async => right(
        BasketOptimization(
          insights: insights,
          savingsTip: savingsTip,
          findings: withFindings
              ? BasketFinding.listFromJson(<dynamic>[_findingJson()])
              : const [],
          narrativeDisclosure: narrativeDisclosure,
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

  /// The card, when it renders at all.
  Finder insightsCard() => find.byType(BasketInsightsCard);

  /// The rendered box inside the card — absent when the card short-circuits.
  Finder insightsBody() =>
      find.descendant(of: insightsCard(), matching: find.byType(Column));

  group('narrative with its disclosure', () {
    testWidgets('renders both, and the disclosure sits with the narrative', (
      tester,
    ) async {
      stubOptimization(
        insights: const [_insight],
        savingsTip: _tip,
        narrativeDisclosure: _disclosure,
      );
      await pumpCart(tester);

      expect(find.text('Basket Insights'), findsOneWidget);
      expect(find.text(_insight), findsOneWidget);
      expect(find.text(_tip), findsOneWidget);
      expect(find.text(_disclosure), findsOneWidget);

      // Attached, not filed away: the disclosure is inside the same card as
      // the narrative it describes, and above the text it marks.
      expect(
        find.descendant(of: insightsCard(), matching: find.text(_disclosure)),
        findsOneWidget,
      );
      final disclosureY = tester.getTopLeft(find.text(_disclosure)).dy;
      expect(disclosureY, lessThan(tester.getTopLeft(find.text(_insight)).dy));
      expect(disclosureY, lessThan(tester.getTopLeft(find.text(_tip)).dy));
    });

    testWidgets('renders the disclosure verbatim, not reworded or clipped', (
      tester,
    ) async {
      stubOptimization(
        insights: const [_insight],
        narrativeDisclosure: _disclosure,
      );
      await pumpCart(tester);

      final rendered = tester.widget<Text>(find.text(_disclosure));
      expect(rendered.data, _disclosure);
      // Not shortened by the widget itself.
      expect(rendered.maxLines, isNull);
      expect(rendered.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('leaves the findings exactly as they were', (tester) async {
      stubOptimization(
        insights: const [_insight],
        savingsTip: _tip,
        narrativeDisclosure: _disclosure,
      );
      await pumpCart(tester);

      expect(find.byType(BasketFindingCard), findsOneWidget);
      expect(find.textContaining('Source: cart.line.unitPriceAtAdd'),
          findsOneWidget);
      expect(find.text('What we noticed'), findsOneWidget);
    });
  });

  group('narrative without its disclosure', () {
    testWidgets('renders no narrative at all', (tester) async {
      stubOptimization(insights: const [_insight], savingsTip: _tip);
      await pumpCart(tester);

      expect(find.text(_insight), findsNothing);
      expect(find.text(_tip), findsNothing);
      expect(find.text('Basket Insights'), findsNothing);
      expect(insightsBody(), findsNothing);
    });

    testWidgets('an empty-string disclosure is not a disclosure', (
      tester,
    ) async {
      stubOptimization(
        insights: const [_insight],
        narrativeDisclosure: '   ',
      );
      await pumpCart(tester);

      expect(find.text(_insight), findsNothing);
      expect(find.text('Basket Insights'), findsNothing);
    });

    testWidgets('the findings still render in full', (tester) async {
      stubOptimization(insights: const [_insight], savingsTip: _tip);
      await pumpCart(tester);

      expect(find.byType(BasketFindingCard), findsOneWidget);
      expect(find.textContaining('Source: cart.line.unitPriceAtAdd'),
          findsOneWidget);
    });
  });

  group("the flag off — today's default", () {
    testWidgets('renders no card, no heading, no empty state', (tester) async {
      // What the endpoint sends while CartCheckout:BasketNarrative:Enabled is
      // false: empty insights, null tip, and so no disclosure to carry.
      stubOptimization();
      await pumpCart(tester);

      expect(find.text('Basket Insights'), findsNothing);
      expect(insightsBody(), findsNothing);
      expect(find.text(_disclosure), findsNothing);
    });

    testWidgets('the findings are untouched by the narrative being off', (
      tester,
    ) async {
      stubOptimization();
      await pumpCart(tester);

      expect(find.byType(BasketFindingCard), findsOneWidget);
      expect(find.text('What we noticed'), findsOneWidget);
      expect(
        find.text('Checked against your basket. Nothing has been changed.'),
        findsOneWidget,
      );
    });
  });

  group('narrative reads differently from evidence', () {
    testWidgets('is distinguishable without colour', (tester) async {
      stubOptimization(
        insights: const [_insight],
        savingsTip: _tip,
        narrativeDisclosure: _disclosure,
      );
      await pumpCart(tester);

      // Carrier 1: its own word, on its own pill.
      final narrativePill = tester.widget<MallStatusPill>(
        find.descendant(
          of: insightsCard(),
          matching: find.byType(MallStatusPill),
        ),
      );
      expect(narrativePill.label, 'AI suggestion');
      // Carrier 2: its own glyph, shared with no finding badge.
      expect(narrativePill.icon, Icons.auto_awesome);
      final findingPill = tester.widget<MallStatusPill>(
        find.descendant(
          of: find.byType(BasketFindingCard),
          matching: find.byType(MallStatusPill),
        ),
      );
      expect(findingPill.icon, isNot(narrativePill.icon));
      expect(findingPill.label, isNot(narrativePill.label));

      // Carrier 3: an italic body. Every finding's body is upright.
      final narrativeStyle = tester.widget<Text>(find.text(_insight)).style;
      expect(narrativeStyle?.fontStyle, FontStyle.italic);
      final findingBody = tester.widget<Text>(
        find.text(
          'The seller raised the price. Your basket has not been changed.',
        ),
      );
      expect(findingBody.style?.fontStyle, isNot(FontStyle.italic));

      // Carrier 4: evidence cites a record; the narrative cites none, and the
      // disclosure inside the card says so in words.
      expect(
        find.descendant(
          of: insightsCard(),
          matching: find.textContaining('Source:'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(BasketFindingCard),
          matching: find.textContaining('Source:'),
        ),
        findsOneWidget,
      );
    });
  });

  group('accessibility and layout', () {
    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      stubOptimization(
        insights: const [_insight, 'A second, longer AI observation here.'],
        savingsTip: _tip,
        narrativeDisclosure: _disclosure,
      );
      await pumpCart(tester, size: const Size(320, 640), textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.byType(BasketFindingCard), findsOneWidget);
    });

    testWidgets('the card itself lays out at 320dp and 1.3', (tester) async {
      // The card on its own, so the assertion is about this card rather than
      // about whatever else the cart screen puts below the fold.
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: BasketInsightsCard(
                  optimization: BasketOptimization(
                    insights: [
                      _insight,
                      'A second, longer AI observation here.',
                    ],
                    savingsTip: _tip,
                    narrativeDisclosure: _disclosure,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_disclosure), findsOneWidget);
      // The disclosure wraps inside the card rather than running past it.
      final cardWidth = tester.getSize(find.byType(BasketInsightsCard)).width;
      expect(cardWidth, lessThanOrEqualTo(320));
      expect(
        tester.getSize(find.text(_disclosure)).width,
        lessThanOrEqualTo(cardWidth),
      );
    });

    testWidgets('the card carries semantics labels', (tester) async {
      final handle = tester.ensureSemantics();
      stubOptimization(
        insights: const [_insight],
        savingsTip: _tip,
        narrativeDisclosure: _disclosure,
      );
      await pumpCart(tester);

      // The heading announces itself as one.
      expect(
        tester.getSemantics(find.text('Basket Insights')),
        matchesSemantics(label: 'Basket Insights', isHeader: true),
      );
      // The narrative is one node that opens with the disclosure, verbatim:
      // a screen reader cannot reach the claim without the mark.
      final narrativeNode = tester.getSemantics(
        find.ancestor(
          of: find.text(_disclosure),
          matching: find.byType(MergeSemantics),
        ),
      );
      expect(narrativeNode.label, startsWith(_disclosure));
      expect(narrativeNode.label, contains(_insight));
      expect(narrativeNode.label, contains(_tip));
      // The pill says what it is rather than just naming itself.
      expect(
        find.bySemanticsLabel('AI suggestion, not based on your basket'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('parsing', () {
    late _MockCartRemoteDataSource remote;
    late CartRepositoryImpl repo;

    setUp(() {
      remote = _MockCartRemoteDataSource();
      repo = CartRepositoryImpl(remoteDataSource: remote);
    });

    Future<BasketOptimization> read(Map<String, dynamic> json) async {
      when(() => remote.getBasketOptimization()).thenAnswer((_) async => json);
      final result = await repo.getBasketOptimization();
      return result.getRight().toNullable()!;
    }

    test('narrativeDisclosure is read off the wire', () async {
      final parsed = await read(<String, dynamic>{
        'insights': <dynamic>[_insight],
        'savingsTip': _tip,
        'findings': <dynamic>[],
        'narrativeDisclosure': _disclosure,
      });

      expect(parsed.narrativeDisclosure, _disclosure);
      expect(parsed.canRenderNarrative, isTrue);
    });

    test('an absent key leaves it null and suppresses the narrative', () async {
      final parsed = await read(<String, dynamic>{
        'insights': <dynamic>[_insight],
        'savingsTip': _tip,
        'findings': <dynamic>[],
      });

      expect(parsed.narrativeDisclosure, isNull);
      expect(parsed.hasNarrativeText, isTrue);
      expect(parsed.canRenderNarrative, isFalse);
    });

    test('the flag-off response yields nothing to render', () async {
      final parsed = await read(<String, dynamic>{
        'insights': <dynamic>[],
        'savingsTip': null,
        'findings': <dynamic>[],
      });

      expect(parsed.hasNarrativeText, isFalse);
      expect(parsed.canRenderNarrative, isFalse);
    });

    test('a non-string disclosure is ignored rather than rendered', () async {
      final parsed = await read(<String, dynamic>{
        'insights': <dynamic>[_insight],
        'findings': <dynamic>[],
        'narrativeDisclosure': 42,
      });

      expect(parsed.narrativeDisclosure, isNull);
      expect(parsed.canRenderNarrative, isFalse);
    });
  });
}
