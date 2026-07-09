import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/repositories/creator_performance_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/notifiers/creator_performance_notifier.dart';

class _MockCreatorPerformanceRepository extends Mock
    implements CreatorPerformanceRepository {}

List<CreatorPerformance> _creators() => const [
  CreatorPerformance(
    creatorAccountId: 'acc-1',
    unitsSold: 12,
    attributedRevenue: 45000,
    commissionPaid: 5400,
    currency: 'NPR',
    distinctReelCount: 3,
    creatorHandle: 'creator1',
    creatorDisplayName: 'Creator One',
  ),
];

void main() {
  late _MockCreatorPerformanceRepository repository;

  setUp(() {
    repository = _MockCreatorPerformanceRepository();
    when(
      () => repository.getCreatorPerformance(
        sortBy: any(named: 'sortBy'),
        window: any(named: 'window'),
      ),
    ).thenAnswer((_) async => right(_creators()));
  });

  test('load() transitions to loadSuccess with the fetched creators', () async {
    final creators = _creators();
    when(
      () => repository.getCreatorPerformance(
        sortBy: any(named: 'sortBy'),
        window: any(named: 'window'),
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
        sortBy: any(named: 'sortBy'),
        window: any(named: 'window'),
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

  test(
    'load() forwards sortBy and window parameters to the repository',
    () async {
      final notifier = CreatorPerformanceNotifier(repository);
      await notifier.load(sortBy: 'revenue', window: '30d');

      verify(
        () => repository.getCreatorPerformance(
          sortBy: 'revenue',
          window: '30d',
        ),
      ).called(1);
    },
  );
}
