import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/repositories/creator_performance_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/notifiers/creator_performance_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockCreatorPerformanceRepository extends Mock
    implements CreatorPerformanceRepository {}

List<CreatorPerformance> _creators() => const [
  CreatorPerformance(
    creatorAccountId: 'acc-1',
    unitsSold: 12,
    attributedRevenue: Money(amount: 45000, currency: 'NPR'),
    commissionPaid: Money(amount: 5400, currency: 'NPR'),
    distinctReelCount: 3,
  ),
];

void main() {
  late _MockCreatorPerformanceRepository repository;

  setUp(() {
    repository = _MockCreatorPerformanceRepository();
    when(
      () => repository.getCreatorPerformance(
        windowDays: any(named: 'windowDays'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => right(_creators()));
  });

  test('load() transitions to loadSuccess with the fetched creators', () async {
    final creators = _creators();
    when(
      () => repository.getCreatorPerformance(
        windowDays: any(named: 'windowDays'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => right(creators));

    final notifier = CreatorPerformanceNotifier(repository);
    await notifier.load();

    expect(
      notifier.state.maybeWhen(
        loadSuccess: (c) => c,
        orElse: () => null,
      ),
      creators,
    );
  });

  test('load() transitions to loadFailure on repository error', () async {
    when(
      () => repository.getCreatorPerformance(
        windowDays: any(named: 'windowDays'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );

    final notifier = CreatorPerformanceNotifier(repository);
    await notifier.load();

    expect(
      notifier.state.maybeWhen(loadFailure: (_) => true, orElse: () => false),
      isTrue,
    );
  });

  test('load() forwards windowDays to the repository', () async {
    final notifier = CreatorPerformanceNotifier(repository);
    await notifier.load(windowDays: 30);

    verify(
      () => repository.getCreatorPerformance(
        windowDays: 30,
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  test('load() sorts results client-side by the requested metric', () async {
    final creators = [
      const CreatorPerformance(
        creatorAccountId: 'acc-1',
        unitsSold: 5,
        attributedRevenue: Money(amount: 1000, currency: 'NPR'),
        commissionPaid: Money(amount: 100, currency: 'NPR'),
        distinctReelCount: 1,
      ),
      const CreatorPerformance(
        creatorAccountId: 'acc-2',
        unitsSold: 20,
        attributedRevenue: Money(amount: 500, currency: 'NPR'),
        commissionPaid: Money(amount: 300, currency: 'NPR'),
        distinctReelCount: 2,
      ),
    ];
    when(
      () => repository.getCreatorPerformance(
        windowDays: any(named: 'windowDays'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => right(creators));

    final notifier = CreatorPerformanceNotifier(repository);
    await notifier.load(sortBy: CreatorPerformanceSortBy.sales);

    final result = notifier.state.maybeWhen(
      loadSuccess: (c) => c,
      orElse: () => null,
    );
    expect(
      result?.map((c) => c.creatorAccountId).toList(),
      ['acc-2', 'acc-1'],
    );
  });
}
