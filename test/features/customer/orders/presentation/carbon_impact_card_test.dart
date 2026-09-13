import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/carbon_impact.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/carbon_impact_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _saved = CarbonImpact(
  kgCo2Saved: 3.25,
  deliveryCount: 4,
  comparedToTraditionalKg: 8.5,
);

Future<CarbonImpact?> _readProvider(OrdersRepository repository) async {
  final container = ProviderContainer(
    overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  final sub = container.listen(carbonImpactProvider.future, (_, _) {});
  return sub.read();
}

void main() {
  group('carbonImpactProvider', () {
    late _MockOrdersRepository repository;

    setUp(() => repository = _MockOrdersRepository());

    test('exposes the impact when there is a saving to show', () async {
      when(
        () => repository.getCarbonImpact(),
      ).thenAnswer((_) async => right(_saved));

      expect(await _readProvider(repository), same(_saved));
    });

    test('is null when nothing has been saved yet', () async {
      when(() => repository.getCarbonImpact()).thenAnswer(
        (_) async => right(
          const CarbonImpact(
            kgCo2Saved: 0,
            deliveryCount: 0,
            comparedToTraditionalKg: 0,
          ),
        ),
      );

      expect(await _readProvider(repository), isNull);
    });

    test('is null when the repository returns a failure (e.g. 404)', () async {
      when(
        () => repository.getCarbonImpact(),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      expect(await _readProvider(repository), isNull);
    });

    test('is null when the repository throws', () async {
      when(() => repository.getCarbonImpact()).thenThrow(StateError('boom'));

      expect(await _readProvider(repository), isNull);
    });
  });

  group('CarbonImpactCard', () {
    Future<void> pumpCard(WidgetTester tester, CarbonImpact? impact) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [carbonImpactProvider.overrideWith((ref) async => impact)],
          child: const MaterialApp(home: Scaffold(body: CarbonImpactCard())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the saving, delivery count and percentage', (
      tester,
    ) async {
      await pumpCard(tester, _saved);

      expect(
        find.text('You saved 3.3 kg CO₂ with StyleMint delivery'),
        findsOneWidget,
      );
      expect(
        find.text(
          '4 community deliveries · 38% less than a traditional courier',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders nothing when there is no impact', (tester) async {
      await pumpCard(tester, null);

      expect(find.byIcon(Icons.eco_outlined), findsNothing);
      expect(find.textContaining('CO₂'), findsNothing);
    });
  });

  group('formatCo2Mass', () {
    test('uses grams below one kilogram', () {
      expect(formatCo2Mass(0.045), '45 g');
      expect(formatCo2Mass(0.9994), '999 g');
    });

    test('uses one decimal below ten kilograms, whole kg above', () {
      expect(formatCo2Mass(1), '1.0 kg');
      expect(formatCo2Mass(3.25), '3.3 kg');
      expect(formatCo2Mass(12.6), '13 kg');
    });
  });
}
