import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/repositories/creator_dashboard_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/notifiers/creator_dashboard_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _FakeRepository implements CreatorDashboardRepository {
  _FakeRepository({this.dashboard});

  NetworkEither<CreatorDashboard>? dashboard;
  int calls = 0;

  @override
  Future<NetworkEither<CreatorDashboard>> getDashboard() async {
    calls++;
    return dashboard ?? networkRight(_dashboard());
  }
}

CreatorDashboard _dashboard() => const CreatorDashboard(
      earnings: Money(amount: 250, currency: 'NPR'),
      pendingBalance: Money(amount: 50, currency: 'NPR'),
      totalSales: 12,
      totalViews: 3400,
      topReels: [],
      earningsDeltaPercent: 12.5,
    );

Future<CreatorDashboardNotifier> _settled(_FakeRepository repo) async {
  final notifier = CreatorDashboardNotifier(repo);
  await Future<void>.delayed(Duration.zero);
  return notifier;
}

void main() {
  group('CreatorDashboardNotifier', () {
    test('loads the dashboard on construction', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      expect(repo.calls, 1);
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (d) => d.totalSales,
          orElse: () => -1,
        ),
        12,
      );
    });

    test('carries the delta percent through, including when absent', () async {
      final withDelta = await _settled(_FakeRepository());
      expect(
        withDelta.state.maybeWhen(
          loadSuccess: (d) => d.earningsDeltaPercent,
          orElse: () => null,
        ),
        12.5,
      );

      // Null is meaningful here: the backend has no comparison baseline yet,
      // which the UI must not render as a 0% change.
      final noDelta = await _settled(
        _FakeRepository(
          dashboard: networkRight(
            const CreatorDashboard(
              earnings: Money(amount: 250, currency: 'NPR'),
              pendingBalance: Money(amount: 50, currency: 'NPR'),
              totalSales: 12,
              totalViews: 3400,
              topReels: [],
            ),
          ),
        ),
      );
      expect(
        noDelta.state.maybeWhen(
          loadSuccess: (d) => d.earningsDeltaPercent,
          orElse: () => -1.0,
        ),
        isNull,
      );
    });

    test('surfaces a load failure rather than an empty dashboard', () async {
      final notifier = await _settled(
        _FakeRepository(
          dashboard: networkLeft(const NetworkExceptions.noInternetConnection()),
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

    test('load() can be called again to refresh', () async {
      final repo = _FakeRepository();
      final notifier = await _settled(repo);

      await notifier.load();

      expect(repo.calls, 2);
    });
  });
}
