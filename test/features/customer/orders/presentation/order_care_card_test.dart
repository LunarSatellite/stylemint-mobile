import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_care_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _orderNumber = 'NK2026-00015';

final _openItem = CareItem(
  subOrderId: 'sub-1',
  subOrderLineId: 'line-1',
  productVariantId: 'variant-1',
  title: 'Linen shirt',
  variantLabel: 'M / White',
  stage: CareStage.returnWindowOpen,
  daysLeftToReturn: 5,
  actions: [
    CareAction.returnItem,
    CareAction.review,
    CareAction.getHelp,
    CareAction.warrantyClaim,
  ],
  guidance: 'You have 5 days to start a return if it does not fit.',
  warrantyEligible: true,
  warrantyEndsUtc: DateTime.utc(2027, 9, 11),
  warrantyTerms: 'Covers manufacturing defects.',
);

const _closedItem = CareItem(
  subOrderId: 'sub-1',
  subOrderLineId: 'line-2',
  productVariantId: 'variant-2',
  title: 'Canvas tote',
  stage: CareStage.returnWindowClosed,
  actions: [CareAction.reorder],
  guidance: 'The return window has closed. Buy it again any time.',
);

final _plan = OrderCarePlan(
  orderNumber: _orderNumber,
  items: [_openItem, _closedItem],
);

Future<OrderCarePlan?> _readProvider(OrdersRepository repository) async {
  final container = ProviderContainer(
    overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(
    orderCarePlanProvider(_orderNumber).future,
    (_, _) {},
  );
  return sub.read();
}

void main() {
  late _MockOrdersRepository repository;

  setUp(() => repository = _MockOrdersRepository());

  group('orderCarePlanProvider', () {
    test('exposes a plan that has items', () async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenAnswer((_) async => right(_plan));

      expect(await _readProvider(repository), same(_plan));
    });

    test('is null when the plan has no items', () async {
      when(() => repository.getOrderCarePlan(_orderNumber)).thenAnswer(
        (_) async =>
            right(const OrderCarePlan(orderNumber: _orderNumber, items: [])),
      );

      expect(await _readProvider(repository), isNull);
    });

    test('is null on a repository failure such as 404', () async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      expect(await _readProvider(repository), isNull);
    });

    test('is null when the repository throws', () async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenThrow(StateError('boom'));

      expect(await _readProvider(repository), isNull);
    });
  });

  group('OrderCareCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      CareActionResolver? resolveAction,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OrderCareCard(
                  orderNumber: _orderNumber,
                  resolveAction: resolveAction,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists guidance and a days-left chip only for open windows', (
      tester,
    ) async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenAnswer((_) async => right(_plan));

      await pumpCard(tester);

      expect(find.text('Care & returns'), findsOneWidget);
      expect(find.text('Linen shirt'), findsOneWidget);
      expect(find.text('M / White'), findsOneWidget);
      expect(
        find.text('You have 5 days to start a return if it does not fit.'),
        findsOneWidget,
      );
      expect(
        find.text('The return window has closed. Buy it again any time.'),
        findsOneWidget,
      );
      expect(find.text('5 days left to return'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.text('Warranty to Sep 11, 2027'), findsOneWidget);
      // No resolver: every action button is omitted.
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('wires resolvable actions and omits the rest', (tester) async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenAnswer((_) async => right(_plan));
      final returned = <CareItem>[];

      await pumpCard(
        tester,
        resolveAction: (item, action) => switch (action) {
          CareAction.returnItem => returned.add,
          CareAction.getHelp => (_) {},
          _ => null,
        },
      );

      expect(find.text('Start a return'), findsOneWidget);
      expect(find.text('Get help'), findsOneWidget);
      expect(find.text('Write a review'), findsNothing);
      expect(find.text('Buy again'), findsNothing);

      await tester.tap(find.text('Start a return'));
      expect(returned, [same(_openItem)]);
    });

    testWidgets('renders nothing when the care plan request fails', (
      tester,
    ) async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      await pumpCard(tester, resolveAction: (_, _) => (_) {});

      expect(find.text('Care & returns'), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('renders nothing when the repository throws', (tester) async {
      when(
        () => repository.getOrderCarePlan(_orderNumber),
      ).thenThrow(StateError('boom'));

      await pumpCard(tester);

      expect(find.text('Care & returns'), findsNothing);
    });
  });

  group('daysLeftToReturnLabel', () {
    test('pluralises and handles the final day', () {
      expect(daysLeftToReturnLabel(5), '5 days left to return');
      expect(daysLeftToReturnLabel(1), '1 day left to return');
      expect(daysLeftToReturnLabel(0), 'Last day to return');
    });
  });
}
