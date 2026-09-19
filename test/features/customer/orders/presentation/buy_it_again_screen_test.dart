import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/buy_it_again_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/buy_it_again_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../../orders_test_harness.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

/// Records every add, and answers each one the same way. Hand-written rather
/// than stubbed so the assertions are about what the screen *did*, not about
/// which argument matcher happened to fire.
class _MockCartRepository extends Mock implements CartRepository {
  final List<({String productId, int quantity})> adds =
      <({String productId, int quantity})>[];

  /// The cart notifier fetches on creation; nothing on this screen needs the
  /// result, so it is answered and ignored.
  @override
  Future<Either<NetworkExceptions, Cart>> getCart() async =>
      left(const NetworkExceptions.server('offline in test'));

  @override
  Future<Either<NetworkExceptions, Cart>> addToCart({
    required String productId,
    required int quantity,
    required String idempotencyKey,
    String? variantId,
    String? reelTagContextId,
  }) async {
    adds.add((productId: productId, quantity: quantity));
    return left(const NetworkExceptions.server('offline in test'));
  }
}

/// The only figures the screen is allowed to say. Everything the widget tree
/// renders is checked against the numbers in here — the four fabrications
/// this codebase has already shipped to customers all began as a figure no
/// payload contained.
const _suggestions = [
  ReorderSuggestionDto(
    productId: 'p-1',
    productName: 'Aloe Face Wash',
    suggestedQuantity: 2,
    reason:
        "Based on your typical 30-day restock cycle — you're likely running "
        'low',
    price: 450,
    currency: 'NPR',
    daysUntilExpected: 4,
    confidence: 0.72,
  ),
  ReorderSuggestionDto(
    productId: 'p-2',
    productName: 'Cotton Socks',
    suggestedQuantity: 1,
    reason: 'Based on your typical 21-day restock cycle — you may be out',
    price: 300,
    currency: 'NPR',
    daysUntilExpected: 0,
    confidence: 0.55,
  ),
];

/// Every run of digits in the fixture's *displayable* fields, plus the digits
/// of each price as the app formats it. Confidence is deliberately left out:
/// it is a model internal, and a screen that printed it would fail this.
Set<String> _figuresTheServerSent() {
  final digits = RegExp(r'\d+');
  final allowed = <String>{};
  for (final s in _suggestions) {
    for (final field in [
      s.productName,
      s.reason,
      '${s.suggestedQuantity}',
      '${s.daysUntilExpected}',
      formatMoney(Money(amount: s.price, currency: s.currency)),
    ]) {
      allowed.addAll(digits.allMatches(field).map((m) => m.group(0)!));
    }
  }
  return allowed;
}

Widget _app(
  _MockOrdersRepository orders,
  _MockCartRepository cart, {
  bool personalizationAllowed = true,
  double textScale = 1,
  Widget screen = const BuyItAgainScreen(),
}) => ProviderScope(
  overrides: [
    ordersRepositoryProvider.overrideWithValue(orders),
    cartRepositoryProvider.overrideWithValue(cart),
    personalizationAllowedProvider.overrideWith(
      (ref) async => personalizationAllowed,
    ),
  ],
  child: ordersTestApp(screen, textScale: textScale, wrapInScaffold: false),
);

void main() {
  late _MockOrdersRepository orders;
  late _MockCartRepository cart;

  setUp(() {
    orders = _MockOrdersRepository();
    cart = _MockCartRepository();
    when(
      orders.getReplenishmentPreference,
    ).thenAnswer((_) async => right(true));
    when(orders.getReorderSuggestions).thenAnswer(
      (_) async => right(_suggestions),
    );
  });

  group('the estimates list', () {
    testWidgets('renders one row per suggestion, in the server words', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      expect(find.text('Aloe Face Wash'), findsOneWidget);
      expect(find.text('Cotton Socks'), findsOneWidget);
      // The backend's own reason line, verbatim.
      for (final suggestion in _suggestions) {
        expect(find.text(suggestion.reason), findsOneWidget);
      }
      // The server's day count, said as the count it is.
      expect(find.text('Estimated in about 4 days'), findsOneWidget);
      expect(find.text('Estimated for around today'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('frames the list as estimates, not as facts about a home', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('These are guesses about timing'),
        findsOneWidget,
      );
      expect(
        find.textContaining("we don't know what you still have"),
        findsOneWidget,
      );
      // Nothing claims the customer has run out, or that a reorder is due as
      // a matter of fact. The hedge is the backend's and it is kept.
      final rendered = _renderedText(tester).join(' ').toLowerCase();
      for (final forbidden in [
        "you've run out",
        'you have run out',
        'you are out of',
        'running out now',
        'order now',
        'last chance',
        'only ',
        'left!',
      ]) {
        expect(
          rendered.contains(forbidden),
          isFalse,
          reason: 'the screen said "$forbidden"',
        );
      }
    });

    testWidgets('renders no figure the payload did not contain', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      final allowed = _figuresTheServerSent();
      final digits = RegExp(r'\d+');
      final invented = <String>[];
      for (final text in _renderedText(tester)) {
        for (final match in digits.allMatches(text)) {
          final figure = match.group(0)!;
          if (!allowed.contains(figure)) invented.add('$figure in "$text"');
        }
      }
      expect(
        invented,
        isEmpty,
        reason: 'a number on screen that the server never sent',
      );
      // Confidence is a model internal: never a percentage, never a score.
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('72'), findsNothing);
      expect(find.textContaining('55'), findsNothing);
    });

    testWidgets('draws no product photograph — the Mall is video-first', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
      expect(find.byType(FadeInImage), findsNothing);
      // The typographic ground the Mall kit uses instead.
      expect(find.byType(MallTypeGround), findsWidgets);
    });

    testWidgets('every control carries a label a screen reader can say', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Add 2 to cart, Aloe Face Wash'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Add 1 to cart, Cotton Socks'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Restock estimate.*Aloe Face Wash')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      handle.dispose();
    });

    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('lays out at ${width}dp and text scale $scale', (
          tester,
        ) async {
          setPhoneView(tester, width: width);
          await tester.pumpWidget(_app(orders, cart, textScale: scale));
          await tester.pumpAndSettle();
          expectNoLayoutErrors(tester);
        });
      }
    }
  });

  group('reordering is the customer move', () {
    testWidgets('opening, settling and scrolling the screen touches no cart', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(cart.adds, isEmpty);
    });

    testWidgets('one tap adds one product, at the quantity the server sent', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('buy-it-again-add-p-1')));
      await tester.pumpAndSettle();

      // Exactly one add, for the tapped product, at the server's quantity —
      // and nothing for the row nobody touched.
      expect(cart.adds, [(productId: 'p-1', quantity: 2)]);
    });
  });

  group('empty is normal', () {
    testWidgets('an empty result is calm, and nudges nobody to buy', (
      tester,
    ) async {
      when(orders.getReorderSuggestions).thenAnswer((_) async => right([]));
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to suggest right now'), findsOneWidget);
      expect(
        find.textContaining('An empty list is the normal one'),
        findsOneWidget,
      );
      // No error language, and no call to action selling anything.
      final rendered = _renderedText(tester).join(' ').toLowerCase();
      for (final forbidden in [
        'something went wrong',
        'error',
        'failed',
        'try again',
        'shop now',
        'browse deals',
        'start shopping',
      ]) {
        expect(
          rendered.contains(forbidden),
          isFalse,
          reason: 'the empty state said "$forbidden"',
        );
      }
      expectNoLayoutErrors(tester);
    });
  });

  group('consent', () {
    testWidgets('a paused customer is shown no prediction at all', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        _app(orders, cart, personalizationAllowed: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Restock estimates are paused'), findsOneWidget);
      expect(find.text('Aloe Face Wash'), findsNothing);
      expect(find.text('Cotton Socks'), findsNothing);
      expect(find.byKey(const ValueKey('buy-it-again-add-p-1')), findsNothing);
      // The pause stops the asking, not only the showing.
      verifyNever(orders.getReorderSuggestions);
      verifyNever(orders.getReplenishmentPreference);
    });

    testWidgets('a paused customer is offered no entry point to dangle from', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        _app(
          orders,
          cart,
          personalizationAllowed: false,
          screen: const Scaffold(body: BuyItAgainSection()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('restock-see-all')), findsNothing);
      expect(find.byKey(const ValueKey('restock-enable')), findsNothing);
      expect(find.textContaining('restock'), findsNothing);
      verifyNever(orders.getReorderSuggestions);
    });

    testWidgets('the rail links to the screen when personalisation is on', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        _app(orders, cart, screen: const Scaffold(body: BuyItAgainSection())),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('restock-see-all')), findsOneWidget);
    });

    testWidgets('a customer who has not opted in sees the invitation, not '
        'predictions', (tester) async {
      when(
        orders.getReplenishmentPreference,
      ).thenAnswer((_) async => right(false));
      setPhoneView(tester);
      await tester.pumpWidget(_app(orders, cart));
      await tester.pumpAndSettle();

      expect(find.text('Restock estimates are off'), findsOneWidget);
      expect(find.text('Aloe Face Wash'), findsNothing);
      expectNoLayoutErrors(tester);
    });
  });
}

/// Every string the tree is currently drawing.
List<String> _renderedText(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];
