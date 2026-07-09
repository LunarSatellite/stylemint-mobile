import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/repositories/analytics_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/presentation/notifiers/analytics_notifier.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

VendorAnalyticsSummary _summary() => const VendorAnalyticsSummary(
  revenueOverview: RevenueOverview(
    grossSales: 100000,
    grossSalesBadge: '+12%',
    netRevenue: 85000,
    netRevenueBadge: '+9%',
    conversionRate: 3.2,
    conversionRateBadge: '+0.4%',
    totalOrders: 42,
    totalOrdersBadge: '+5',
    currency: 'NPR',
  ),
  earningsPoints: [],
  topProducts: [],
  topCreators: [],
  trafficSources: [],
);

void main() {
  late _MockAnalyticsRepository repository;

  setUp(() {
    repository = _MockAnalyticsRepository();
    when(() => repository.getSummary(window: any(named: 'window')))
        .thenAnswer((_) async => right(_summary()));
  });

  test('load() transitions to loadSuccess with the fetched summary', () async {
    final summary = _summary();
    when(() => repository.getSummary(window: any(named: 'window')))
        .thenAnswer((_) async => right(summary));

    final notifier = AnalyticsNotifier(repository);
    await notifier.load();

    expect(
      notifier.state.maybeWhen(
        loadSuccess: (s) => s,
        orElse: () => null,
      ),
      summary,
    );
  });

  test('load() transitions to loadFailure on repository error', () async {
    when(() => repository.getSummary(window: any(named: 'window')))
        .thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );

    final notifier = AnalyticsNotifier(repository);
    await notifier.load();

    expect(
      notifier.state.maybeWhen(loadFailure: (_) => true, orElse: () => false),
      isTrue,
    );
  });

  test('load() forwards the window parameter to the repository', () async {
    final notifier = AnalyticsNotifier(repository);
    await notifier.load(window: '7d');

    verify(() => repository.getSummary(window: '7d')).called(1);
  });
}
