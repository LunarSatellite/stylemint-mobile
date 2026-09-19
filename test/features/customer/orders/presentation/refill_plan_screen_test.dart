import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/refill_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/refill_plan_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../../orders_test_harness.dart';
import 'refill_plan_test_doubles.dart';

/// The prepared refill basket, and the four things it is not allowed to do.
///
/// These are the failures this surface exists to make impossible: a basket
/// that quietly includes something the platform could not check, a price
/// change reported as one number, a missing price drawn as zero, and a
/// confirm step that reads like an order. Every group below is one of them.
void main() {
  late FakeRefillPlanDataSource data;
  late RecordingCartRepository cart;

  setUp(() {
    data = FakeRefillPlanDataSource()
      ..preferenceValue = preparingPreference
      ..currentPlan = fixturePlan;
    cart = RecordingCartRepository();
  });

  Widget app({
    bool personalizationAllowed = true,
    double textScale = 1,
  }) => ProviderScope(
    overrides: [
      refillPlanDataSourceProvider.overrideWithValue(data),
      cartRepositoryProvider.overrideWithValue(cart),
      personalizationAllowedProvider.overrideWith(
        (ref) async => personalizationAllowed,
      ),
    ],
    child: ordersTestApp(
      const RefillPlanScreen(),
      textScale: textScale,
      wrapInScaffold: false,
    ),
  );

  group('the prepared basket', () {
    testWidgets('renders the framing the server sent, verbatim', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text(fixturePlan.headline), findsOneWidget);
      // The standing admission: an estimate, and the platform cannot see what
      // is already at home. Same voice as the Buy-It-Again header.
      expect(find.text(fixturePlan.caveat), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('shows every line, included and excluded alike', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      for (final line in fixturePlan.lines) {
        expect(
          find.text(line.productName),
          findsOneWidget,
          reason: '${line.productName} was not rendered',
        );
      }
    });
  });

  group('an excluded line is visibly excluded', () {
    testWidgets('carries the "left out" heading and the reason sent', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final excluded = fixturePlan.lines.where((l) => !l.included).toList();
      expect(excluded, hasLength(2));

      // One heading per excluded line, plus the section heading above them.
      expect(
        find.text('Left out of this basket'),
        findsNWidgets(excluded.length),
      );
      expect(find.text('Left out'), findsOneWidget);

      // The backend's own sentence, not a paraphrase.
      for (final line in excluded) {
        expect(find.text(line.excludedReason!), findsOneWidget);
      }
    });

    testWidgets('is not counted in the basket total', (tester) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // The only total on screen is the server's includedSubtotal. The
      // excluded lines' prices are nowhere in it.
      final total = formatMoney(
        Money(
          amount: fixturePlan.includedSubtotal,
          currency: fixturePlan.currency,
        ),
      );
      expect(find.text(total), findsOneWidget);
      expect(
        find.textContaining('${fixturePlan.includedLineCount} item(s)'),
        findsWidgets,
      );
    });

    testWidgets('a notVerified line shows no price at all, not a zero', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // The unverifiable line's currentPrice is null on the payload.
      final unverified = fixturePlan.lines.firstWhere(
        (l) => l.checkKind == RefillLineCheck.notVerified,
      );
      expect(unverified.currentPrice, isNull);

      expect(find.text('Price not checked'), findsOneWidget);

      // Nothing anywhere renders a zero money figure, and no line's "price
      // now" was backfilled from what they last paid.
      final rendered = renderedText(tester);
      for (final text in rendered) {
        expect(
          RegExp(r'(?:Rs|NPR)\s*0(?:[.,]0+)?\b').hasMatch(text),
          isFalse,
          reason: 'a zero price was drawn: "$text"',
        );
      }
    });
  });

  group('a price change shows both prices', () {
    testWidgets('draws what they paid and what it costs now, side by side', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final changed = fixturePlan.lines.firstWhere(
        (l) => l.checkKind == RefillLineCheck.priceChanged,
      );
      final was = formatMoney(
        Money(
          amount: changed.lastPaidPrice,
          currency: changed.lastPaidCurrency,
        ),
      );
      final now = formatMoney(
        Money(
          amount: changed.currentPrice!,
          currency: changed.currentCurrency!,
        ),
      );

      expect(was, isNot(now));
      expect(find.text('You last paid'), findsOneWidget);
      expect(find.text(was), findsOneWidget);
      expect(find.text(now), findsWidgets);
      expect(find.text('Price changed'), findsOneWidget);
    });
  });

  group('no confidence figure anywhere', () {
    testWidgets('renders no score, confidence, rank or percentage', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final rendered = renderedText(tester).join(' ').toLowerCase();
      for (final banned in [
        'confidence',
        'score',
        'certainty',
        'probability',
        'likelihood',
        'rank',
        'risk',
        'accuracy',
        '%',
      ]) {
        expect(
          rendered.contains(banned),
          isFalse,
          reason: 'the screen said "$banned"',
        );
      }
    });

    testWidgets('renders no figure the payload did not contain', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      final allowed = figuresTheServerSent(fixturePlan);
      final digits = RegExp(r'\d+');
      final invented = <String>[];
      for (final text in renderedText(tester)) {
        for (final match in digits.allMatches(text)) {
          final figure = match.group(0)!;
          if (!allowed.contains(figure)) invented.add('$figure in "$text"');
        }
      }
      expect(invented, isEmpty, reason: 'figures no payload contained');
    });
  });

  group('approval is not an order', () {
    testWidgets('says so in plain words where the customer confirms', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('StyleMint never places an order on your behalf'),
        findsOneWidget,
      );
      expect(
        find.textContaining('hands these items to your own cart'),
        findsOneWidget,
      );
      expect(find.text('Approve this basket'), findsOneWidget);

      // No wording anywhere that would let a customer think an order exists.
      final rendered = renderedText(tester).join(' ').toLowerCase();
      for (final forbidden in [
        'order now',
        'place order',
        'buy now',
        'checkout now',
        'we will order',
        "we'll order",
        'automatically order',
        'auto-order',
      ]) {
        expect(
          rendered.contains(forbidden),
          isFalse,
          reason: 'the screen said "$forbidden"',
        );
      }
    });

    testWidgets('confirming records the yes and creates no order or cart add', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('refill-confirm')));
      await tester.pumpAndSettle();

      // Exactly one approval was recorded, and nothing else was called.
      expect(data.confirmedPlanIds, [fixturePlan.planId]);
      expect(cart.adds, isEmpty, reason: 'confirming touched the cart');

      // The server's own note is shown as it was sent.
      expect(find.text(fixtureHandoff.note), findsOneWidget);
      // Moving the lines into the cart is a second, explicit tap.
      expect(
        find.byKey(const ValueKey('refill-add-to-cart')),
        findsOneWidget,
      );
      expect(cart.adds, isEmpty);
    });

    testWidgets('the cart is only touched by the explicit second tap', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('refill-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('refill-add-to-cart')));
      await tester.pumpAndSettle();

      expect(cart.adds, hasLength(fixtureHandoff.lines.length));
      for (var i = 0; i < fixtureHandoff.lines.length; i++) {
        expect(cart.adds[i].productId, fixtureHandoff.lines[i].productId);
        expect(cart.adds[i].quantity, fixtureHandoff.lines[i].quantity);
      }
    });

    testWidgets('nothing is pre-selected and nothing swaps itself', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // Alternatives are offered as facts to read, never as a selection that
      // is already made for the customer.
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Radio<Object?>), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(
        find.text('We never swap one for another — picking is yours.'),
        findsOneWidget,
      );
      // Opening the screen prepares nothing: only the open plan was read.
      expect(data.prepareCalls, 0);
    });
  });

  group('204 is an answer, not an error', () {
    testWidgets('renders the calm empty state', (tester) async {
      data.currentPlan = null;
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('No refill basket right now'), findsOneWidget);

      final rendered = renderedText(tester).join(' ').toLowerCase();
      for (final forbidden in [
        'something went wrong',
        'error',
        'failed',
        'problem',
      ]) {
        expect(
          rendered.contains(forbidden),
          isFalse,
          reason: 'a 204 was rendered as "$forbidden"',
        );
      }
      expectNoLayoutErrors(tester);
    });
  });

  group('consent and the pause the customer set', () {
    testWidgets('a refused customer sees nothing and nothing is fetched', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app(personalizationAllowed: false));
      await tester.pumpAndSettle();

      expect(find.text('Restock estimates are paused'), findsOneWidget);
      expect(find.text(fixturePlan.headline), findsNothing);
      expect(data.currentCalls, 0, reason: 'the plan was fetched anyway');
      expect(data.preferenceCalls, 0);
    });

    testWidgets('a paused customer sees the pause, not a basket', (
      tester,
    ) async {
      data.preferenceValue = preparingPreference.copyWith(
        paused: true,
        pausedUntilUtc: DateTime.utc(2026, 10, 20),
      );
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('Restock is paused'), findsOneWidget);
      expect(find.text(fixturePlan.headline), findsNothing);
    });

    testWidgets('a reminders-only customer is told why, not shown an error', (
      tester,
    ) async {
      data.preferenceValue = preparingPreference.copyWith(
        automationLevel: 'remindOnly',
      );
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('You asked for reminders only'), findsOneWidget);
      expect(find.textContaining('we never order'), findsOneWidget);
    });
  });

  group('no product photograph outside product detail', () {
    testWidgets('draws no image even though the lines carry thumbnails', (
      tester,
    ) async {
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      // The fixture's lines do carry a thumbnailUrl; the screen must ignore
      // every one of them.
      expect(
        fixturePlan.lines.any((l) => (l.thumbnailUrl ?? '').isNotEmpty),
        isTrue,
      );
      expect(find.byType(Image), findsNothing);
      expect(find.byType(MallProductCard), findsNothing);
      expect(find.byType(FadeInImage), findsNothing);
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

      // Scrolled the whole way down, every line and the approval block are
      // laid out at this width and scale without a single overflow.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('refill-confirm')),
        200,
      );
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);

      // And the same at the confirmed step, which carries its own buttons.
      await tester.tap(find.byKey(const ValueKey('refill-confirm')));
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);
    });

    testWidgets('every control is labelled and tappable to a screen reader', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setTallPhoneView(tester);
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expectLabelledAndTappable(
        tester,
        const ValueKey('refill-confirm'),
        'Approve this basket. Nothing is ordered',
      );
      expectLabelledAndTappable(
        tester,
        const ValueKey('refill-dismiss'),
        'Throw this basket away',
      );

      // Each line announces whether it is in the basket before it announces
      // what it sells.
      final line = fixturePlan.lines.first;
      expect(
        find.bySemanticsLabel(RegExp('In this basket, ${line.productName}')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });
}

/// The cart, recording what it was asked to do and answering the same way
/// every time. Hand-written so the assertions are about what the screen
/// *did*.
class RecordingCartRepository implements CartRepository {
  final List<({String productId, int quantity})> adds =
      <({String productId, int quantity})>[];

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

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not used here');
}
