import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/repositories/reach_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/notifiers/reach_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _FakeRepository implements ReachRepository {
  _FakeRepository({this.targets, this.campaigns, this.analytics});

  NetworkEither<List<PublishTarget>>? targets;
  NetworkEither<List<BoostCampaign>>? campaigns;
  NetworkEither<ReachAnalytics>? analytics;

  int loadCalls = 0;

  @override
  Future<NetworkEither<List<PublishTarget>>> getPublishTargets() async {
    loadCalls++;
    return targets ?? networkRight(const <PublishTarget>[]);
  }

  @override
  Future<NetworkEither<List<BoostCampaign>>> getBoostCampaigns() async =>
      campaigns ?? networkRight(const <BoostCampaign>[]);

  @override
  Future<NetworkEither<ReachAnalytics>> getAnalytics({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async =>
      analytics ?? networkRight(_analytics());

  @override
  Future<NetworkEither<Unit>> schedulePublish({
    required String draftId,
    required List<String> platformNames,
    required DateTime scheduledAt,
  }) async =>
      networkRight(unit);

  @override
  Future<NetworkEither<BoostCampaign>> createBoostCampaign({
    required String reelId,
    required String platform,
    required Money budget,
    required int durationDays,
  }) async =>
      networkLeft(const NetworkExceptions.unexpectedError());
}

ReachAnalytics _analytics() => ReachAnalytics(
      totalImpressions: 1000,
      totalClicks: 50,
      totalEngagements: 75,
      totalSpent: const Money(amount: 500, currency: 'NPR'),
      periodStart: DateTime.utc(2026),
      periodEnd: DateTime.utc(2026, 2),
    );

Future<ReachNotifier> _settled(_FakeRepository repo) async {
  final notifier = ReachNotifier(repo);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  group('ReachNotifier', () {
    test('composes targets, campaigns and analytics into one success state',
        () async {
      final notifier = await _settled(_FakeRepository());

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (_, _, analytics) => analytics.totalImpressions,
          orElse: () => -1,
        ),
        1000,
      );
    });

    test('a failing targets call fails the load', () async {
      final notifier = await _settled(
        _FakeRepository(
          targets: networkLeft(const NetworkExceptions.noInternetConnection()),
        ),
      );

      expect(
        notifier.state.maybeWhen(
          loadFailure: (f) => NetworkExceptions.getMessage(f),
          orElse: () => null,
        ),
        'No internet connection.',
      );
    });

    test('a failing campaigns call fails the load', () async {
      final notifier = await _settled(
        _FakeRepository(
          campaigns: networkLeft(const NetworkExceptions.serverUnavailable()),
        ),
      );

      expect(
        notifier.state.maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('a failing analytics call fails the load', () async {
      final notifier = await _settled(
        _FakeRepository(
          analytics: networkLeft(const NetworkExceptions.unexpectedError()),
        ),
      );

      expect(
        notifier.state.maybeWhen(loadFailure: (_) => true, orElse: () => false),
        isTrue,
      );
    });

    test('load() can be called again to refresh', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      await notifier.load();

      expect(repo.loadCalls, 2);
    });
  });
}
