import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/entities/demand_signals.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/repositories/demand_signals_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/presentation/screens/vendor_demand_signals_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/shared/providers.dart';

class _MockDemandSignalsRepository extends Mock
    implements DemandSignalsRepository {}

const _signals = DemandSignals(
  windowDays: 7,
  topSearches: [
    DemandQuery(query: 'linen shirt', count: 1240),
    DemandQuery(query: 'running shoes', count: 1),
  ],
  unmetSearches: [DemandQuery(query: 'hemp tote bag', count: 42)],
);

const _empty = DemandSignals(windowDays: 7, topSearches: [], unmetSearches: []);

DemandSignals? _successOf(DemandSignalsState state) =>
    state.maybeWhen(loadSuccess: (s) => s, orElse: () => null);

void main() {
  late _MockDemandSignalsRepository repository;

  void stubAll(Either<NetworkExceptions, DemandSignals> result) {
    when(
      () => repository.getDemandSignals(
        days: any(named: 'days'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() => repository = _MockDemandSignalsRepository());

  group('DemandSignalsNotifier', () {
    test('loads the last 7 days with a limit of 20 on creation', () async {
      stubAll(right(_signals));

      final notifier = DemandSignalsNotifier(repository);
      addTearDown(notifier.dispose);
      await pumpEventQueue();

      expect(_successOf(notifier.state), same(_signals));
      expect(notifier.days, 7);
      verify(() => repository.getDemandSignals(days: 7, limit: 20)).called(1);
    });

    test('moves to loadFailure on a repository error', () async {
      stubAll(left(const NetworkExceptions.serverUnavailable()));

      final notifier = DemandSignalsNotifier(repository);
      addTearDown(notifier.dispose);
      await notifier.load();

      expect(
        notifier.state.maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('load(days: 30) switches the window and forwards it', () async {
      stubAll(right(_signals));

      final notifier = DemandSignalsNotifier(repository);
      addTearDown(notifier.dispose);
      await notifier.load(days: 30);

      expect(notifier.days, 30);
      verify(() => repository.getDemandSignals(days: 30, limit: 20)).called(1);
    });

    test('a late response for a previous window is discarded', () async {
      const thirty = DemandSignals(
        windowDays: 30,
        topSearches: [DemandQuery(query: 'wool coat', count: 88)],
        unmetSearches: [],
      );
      final pendingSeven = Completer<Either<NetworkExceptions, DemandSignals>>();
      when(
        () => repository.getDemandSignals(days: 7, limit: 20),
      ).thenAnswer((_) => pendingSeven.future);
      when(
        () => repository.getDemandSignals(days: 30, limit: 20),
      ).thenAnswer((_) async => right(thirty));

      final notifier = DemandSignalsNotifier(repository); // 7-day load pending
      addTearDown(notifier.dispose);
      await notifier.load(days: 30);
      pendingSeven.complete(right(_signals));
      await pumpEventQueue();

      expect(_successOf(notifier.state), same(thirty));
      expect(notifier.days, 30);
    });
  });

  group('VendorDemandSignalsScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            demandSignalsRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: VendorDemandSignalsScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('lists unmet searches before top searches', (tester) async {
      stubAll(right(_signals));

      await pumpScreen(tester);

      expect(find.text('Searched but not found'), findsOneWidget);
      expect(
        find.text(
          'These searches returned no products. Stocking them could '
          'win you sales.',
        ),
        findsOneWidget,
      );
      expect(find.text('hemp tote bag'), findsOneWidget);
      expect(find.text('42 searches'), findsOneWidget);
      expect(find.text('linen shirt'), findsOneWidget);
      expect(find.text('1,240 searches'), findsOneWidget);
      expect(find.text('1 search'), findsOneWidget);

      final unmetTop = tester.getTopLeft(
        find.byKey(const ValueKey('unmet-searches-header')),
      );
      final topTop = tester.getTopLeft(
        find.byKey(const ValueKey('top-searches-header')),
      );
      expect(unmetTop.dy, lessThan(topTop.dy));
    });

    testWidgets('the 30-day toggle reloads with days=30', (tester) async {
      stubAll(right(_signals));

      await pumpScreen(tester);
      await tester.tap(find.text('Last 30 days'));
      await tester.pumpAndSettle();

      verify(() => repository.getDemandSignals(days: 30, limit: 20)).called(1);
    });

    testWidgets('shows the empty state when both lists are empty', (
      tester,
    ) async {
      stubAll(right(_empty));

      await pumpScreen(tester);

      expect(find.text('No searches yet'), findsOneWidget);
      expect(find.text('Searched but not found'), findsNothing);
      expect(find.text('Top searches'), findsNothing);

      await tester.tap(find.text('See the last 30 days'));
      await tester.pumpAndSettle();

      verify(() => repository.getDemandSignals(days: 30, limit: 20)).called(1);
      expect(find.text('See the last 30 days'), findsNothing);
    });

    testWidgets('shows a retryable error instead of lists on failure', (
      tester,
    ) async {
      stubAll(left(const NetworkExceptions.serverUnavailable()));

      await pumpScreen(tester);

      expect(
        find.text('Could not load what shoppers searched for.'),
        findsOneWidget,
      );
      expect(find.text('Searched but not found'), findsNothing);
      expect(find.text('Top searches'), findsNothing);
    });
  });
}
