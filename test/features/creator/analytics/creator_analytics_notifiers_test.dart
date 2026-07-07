import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/analytics_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_funnel.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_metrics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_reel_analytics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/full_analytics_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/funnel_stage.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/gender_distribution.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/kpi_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_header.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_statistics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reels_sort.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_dashboard_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_full_report_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_overview_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_reel_analytics_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_top_reels_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeAnalyticsRepository implements AnalyticsRepository {
  _FakeAnalyticsRepository({this.shouldFail = false});

  final bool shouldFail;
  String? lastReelId;
  TopReelsSort? lastSortBy;

  static final _window = AnalyticsWindow(
    fromUtc: DateTime.utc(2026, 6),
    toUtc: DateTime.utc(2026, 6, 30),
    durationDays: 30,
  );

  static final _dashboard = CreatorDashboard(
    window: _window,
    totalEarnings:
        const KpiTile<Money>(current: Money(amount: 100, currency: 'NPR')),
    pendingBalance: const Money(amount: 10, currency: 'NPR'),
    totalSales: const KpiTile<int>(current: 5),
    totalViews: const KpiTile<int>(current: 1000),
    conversionRate: const KpiTile<double>(current: 2.5),
    topReels: [],
    topProducts: [],
  );

  static final _overview = CreatorAnalyticsOverview(
    window: _window,
    totalEarnings:
        const KpiTile<Money>(current: Money(amount: 100, currency: 'NPR')),
    totalSales: const KpiTile<int>(current: 5),
    conversionRate: const KpiTile<double>(current: 2.5),
    totalViews: const KpiTile<int>(current: 1000),
    pendingBalance: const Money(amount: 10, currency: 'NPR'),
    earningsTrend: [],
    topReels: [],
    topProducts: [],
  );

  static final _fullReport = FullAnalyticsReport(
    window: _window,
    earningsTrend: [],
    contentPerformance: [],
    conversionMetrics: const ConversionMetrics(
      totalClicks: 0,
      totalOrders: 0,
      conversionRate: 0,
      averageOrderValue: Money(amount: 0, currency: 'NPR'),
    ),
    conversionFunnel: const ConversionFunnel(
      views: FunnelStage(count: 0, percentOfTop: 100),
      clicks: FunnelStage(count: 0, percentOfTop: 0),
      addedToCart: FunnelStage(count: 0, percentOfTop: 0),
      orders: FunnelStage(count: 0, percentOfTop: 0),
    ),
    audienceDemographic: [],
    bestPostingTimes: [],
    genderDistribution: const GenderDistribution(
      femalePercent: 0,
      malePercent: 0,
      otherPercent: 0,
    ),
    topProducts: [],
    topLocations: [],
  );

  static final _reelAnalytics = CreatorReelAnalytics(
    window: _window,
    reel: const ReelHeader(
      reelId: 'r1',
      durationSeconds: 30,
      views: 0,
      likes: 0,
      comments: 0,
    ),
    totalEarnings: const Money(amount: 0, currency: 'NPR'),
    earningsDistribution: [],
    statistics: const ReelStatistics(
      conversionRate: 0,
      clickThroughRate: 0,
      completionRate: 0,
      uniqueViewersEstimate: 0,
    ),
    watchTimeMinutes: 0,
    earningsTrend: [],
    audienceDemographic: [],
    genderDistribution: const GenderDistribution(
      femalePercent: 0,
      malePercent: 0,
      otherPercent: 0,
    ),
    topLocations: [],
  );

  @override
  Future<Either<NetworkExceptions, CreatorDashboard>> getDashboard({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_dashboard);
  }

  @override
  Future<Either<NetworkExceptions, CreatorAnalyticsOverview>> getOverview({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_overview);
  }

  @override
  Future<Either<NetworkExceptions, FullAnalyticsReport>> getReport({
    DateTime? fromUtc,
    DateTime? toUtc,
    int contentPerformanceLimit = 12,
    int topProductsLimit = 5,
    int topLocationsLimit = 5,
  }) async {
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_fullReport);
  }

  @override
  Future<Either<NetworkExceptions, List<TopReelSummary>>> getTopReels({
    DateTime? fromUtc,
    DateTime? toUtc,
    TopReelsSort sortBy = TopReelsSort.highestEarnings,
    int limit = 25,
  }) async {
    lastSortBy = sortBy;
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right([]);
  }

  @override
  Future<Either<NetworkExceptions, CreatorReelAnalytics>> getReelAnalytics({
    required String reelId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int topLocationsLimit = 5,
  }) async {
    lastReelId = reelId;
    if (shouldFail) return left(const NetworkExceptions.unexpectedError());
    return right(_reelAnalytics);
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CreatorDashboardNotifier', () {
    test('emits loadSuccess on repository success', () async {
      final notifier = CreatorDashboardNotifier(_FakeAnalyticsRepository());
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadSuccess: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final notifier =
          CreatorDashboardNotifier(_FakeAnalyticsRepository(shouldFail: true));
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });
  });

  group('CreatorOverviewNotifier', () {
    test('emits loadSuccess on repository success', () async {
      final notifier = CreatorOverviewNotifier(_FakeAnalyticsRepository());
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadSuccess: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final notifier =
          CreatorOverviewNotifier(_FakeAnalyticsRepository(shouldFail: true));
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });
  });

  group('CreatorFullReportNotifier', () {
    test('emits loadSuccess on repository success', () async {
      final notifier = CreatorFullReportNotifier(_FakeAnalyticsRepository());
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadSuccess: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final notifier = CreatorFullReportNotifier(
          _FakeAnalyticsRepository(shouldFail: true));
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });
  });

  group('CreatorTopReelsNotifier', () {
    test('emits loadSuccess with reel list on repository success', () async {
      final notifier = CreatorTopReelsNotifier(_FakeAnalyticsRepository());
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (reels) => reels.isEmpty,
          orElse: () => false,
        ),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final notifier =
          CreatorTopReelsNotifier(_FakeAnalyticsRepository(shouldFail: true));
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('uses highestEarnings as the default sort', () async {
      final repo = _FakeAnalyticsRepository();
      final notifier = CreatorTopReelsNotifier(repo);
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastSortBy, TopReelsSort.highestEarnings);
    });
  });

  group('CreatorReelAnalyticsNotifier', () {
    test('forwards reelId to repository', () async {
      final repo = _FakeAnalyticsRepository();
      final notifier = CreatorReelAnalyticsNotifier(repo, 'reel-42');
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastReelId, 'reel-42');
    });

    test('emits loadSuccess on repository success', () async {
      final notifier =
          CreatorReelAnalyticsNotifier(_FakeAnalyticsRepository(), 'reel-1');
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadSuccess: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('emits loadFailure on repository error', () async {
      final repo = _FakeAnalyticsRepository(shouldFail: true);
      final notifier = CreatorReelAnalyticsNotifier(repo, 'reel-1');
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        notifier.state
            .maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });
  });
}
