import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_payouts_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_payouts_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_payout.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/shared/providers.dart';

/// A payout read that failed, with the failure kept so the screen can tell
/// "not deployed yet" (404) from "could not load".
class CourierPayoutLoadException implements Exception {
  const CourierPayoutLoadException(this.failure, {this.settingUp = false});

  final NetworkExceptions failure;

  /// The endpoint is not on this server yet. Screens say the feature is
  /// being set up — never "nothing", and never an error the rider can fix.
  final bool settingUp;

  factory CourierPayoutLoadException.from(NetworkExceptions failure) =>
      CourierPayoutLoadException(failure, settingUp: failure.isNotFound);

  @override
  String toString() => 'CourierPayoutLoadException($failure)';
}

/// Whether [error] is a payout endpoint that is not deployed yet.
bool courierPayoutsSettingUp(Object? error) =>
    error is CourierPayoutLoadException && error.settingUp;

final courierPayoutsRemoteDataSourceProvider =
    Provider<CourierPayoutsRemoteDataSource>(
      (ref) =>
          CourierPayoutsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final courierPayoutsRepositoryProvider = Provider<CourierPayoutsRepository>(
  (ref) => CourierPayoutsRepositoryImpl(
    ref.watch(courierPayoutsRemoteDataSourceProvider),
  ),
);

/// The rider's balance. No automatic retry: Riverpod's default would keep a
/// 404 in loading-with-error while it retried, and "being set up" has to show
/// at once.
final courierBalanceProvider = FutureProvider.autoDispose<CourierBalance>((
  ref,
) async {
  final result = await ref.watch(courierPayoutsRepositoryProvider).getBalance();
  return result.fold(
    (failure) => throw CourierPayoutLoadException.from(failure),
    (balance) => balance,
  );
}, retry: (_, _) => null);

/// One page of the earnings ledger; null cursor is the first (newest) page.
final courierPayoutEarningsProvider = FutureProvider.autoDispose
    .family<CourierPage<CourierPayoutEarning>, String?>((ref, cursor) async {
      final result = await ref
          .watch(courierPayoutsRepositoryProvider)
          .listEarnings(cursor: cursor);
      return result.fold(
        (failure) => throw CourierPayoutLoadException.from(failure),
        (page) => page,
      );
    }, retry: (_, _) => null);

/// One page of the rider's payouts; null cursor is the newest.
final courierPayoutsProvider = FutureProvider.autoDispose
    .family<CourierPage<CourierPayout>, String?>((ref, cursor) async {
      final result = await ref
          .watch(courierPayoutsRepositoryProvider)
          .listPayouts(cursor: cursor);
      return result.fold(
        (failure) => throw CourierPayoutLoadException.from(failure),
        (page) => page,
      );
    }, retry: (_, _) => null);

/// The rider's saved payout destinations (`/v1/payout-destinations?role=3`),
/// masked by the server.
///
/// Read here rather than through the shared destinations controller because
/// that one turns every failure into an empty list, and an empty list is
/// "you have none" — the wrong thing to say when the read failed. Before the
/// courier role is deployed the server refuses `role=3`, as a 404 or a 400,
/// and both read as "being set up".
final courierPayoutDestinationsProvider =
    FutureProvider.autoDispose<List<PayoutDestinationDto>>((ref) async {
      try {
        return await ref
            .watch(payoutDestinationsDataSourceProvider)
            .list(PayeeKind.courier.value);
      } on Object catch (error) {
        final failure = _failureOf(error);
        final settingUp =
            failure.isNotFound || failure.validationCode != null;
        throw CourierPayoutLoadException(failure, settingUp: settingUp);
      }
    }, retry: (_, _) => null);

NetworkExceptions _failureOf(Object error) {
  if (error is NetworkExceptions) return error;
  return mapDioExceptionToNetworkException(error);
}
