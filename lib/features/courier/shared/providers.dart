import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateNotifierProvider lives here in Riverpod 3; without it the type
// cannot resolve, `ref` degrades to dynamic and every ref.watch in the
// notifier provider below fails to assign.
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_device_key.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/shared/providers.dart';

final courierRemoteDataSourceProvider = Provider<CourierRemoteDataSource>(
  (ref) => CourierRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final courierRepositoryProvider = Provider<CourierRepository>(
  (ref) => CourierRepositoryImpl(
    remoteDataSource: ref.watch(courierRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// This device's signing key. A singleton because the private key is a
/// property of the device, not of a screen: two instances would be two views
/// of the same secure-storage slots and the only thing that could differ is
/// how stale each one's cached key id was.
final courierDeviceKeyProvider = Provider<CourierDeviceKey>(
  (ref) => CourierDeviceKey(),
);

/// Whether this account is a courier, and in what state.
///
/// `null` is a real answer — most accounts are not couriers — so this is
/// `CourierProfile?` rather than a provider that throws. The delivery-partner
/// entry point reads it to decide between the apply flow and the dashboard.
final courierProfileProvider =
    FutureProvider.family<CourierProfile?, String>((ref, accountId) async {
      final result = await ref
          .watch(courierRepositoryProvider)
          .getMyProfile(accountId);
      return result.fold((failure) => throw failure, (profile) => profile);
    });

/// Open hop offers, newest round first.
///
/// Offers expire on a timer the server sets, so this is deliberately not
/// cached beyond the screen: `autoDispose` means leaving the screen and coming
/// back re-reads rather than showing offers that lapsed while it was off
/// screen.
final courierOffersProvider = FutureProvider.autoDispose<List<HopOffer>>(
  (ref) async {
    final result = await ref.watch(courierRepositoryProvider).listOffers();
    return result.fold((failure) => throw failure, (offers) {
      final sorted = [...offers]
        ..sort((a, b) => b.offeredUtc.compareTo(a.offeredUtc));
      return sorted;
    });
  },
);

/// The courier's current work. Unfinished hops first, then by hop index, so
/// the parcel that needs something done is at the top.
final courierHopsProvider = FutureProvider.autoDispose<List<DeliveryHop>>(
  (ref) async {
    final result = await ref.watch(courierRepositoryProvider).listMyHops();
    return result.fold((failure) => throw failure, (hops) {
      final sorted = [...hops]
        ..sort((a, b) {
          if (a.state.isFinished != b.state.isFinished) {
            return a.state.isFinished ? 1 : -1;
          }
          return a.hopIndex.compareTo(b.hopIndex);
        });
      return sorted;
    });
  },
);

final courierDeviceKeysProvider =
    FutureProvider.autoDispose.family<List<CourierDeviceKeyInfo>, String>(
      (ref, courierProfileId) async {
        final result = await ref
            .watch(courierRepositoryProvider)
            .listDeviceKeys(courierProfileId);
        return result.fold((failure) => throw failure, (keys) => keys);
      },
    );

final courierTravelPlansProvider =
    FutureProvider.autoDispose.family<List<CourierTravelPlan>, String>(
      (ref, courierProfileId) async {
        final result = await ref
            .watch(courierRepositoryProvider)
            .listTravelPlans(courierProfileId);
        return result.fold((failure) => throw failure, (plans) {
          final sorted = [...plans]
            ..sort((a, b) => a.departsUtcStart.compareTo(b.departsUtcStart));
          return sorted;
        });
      },
    );

final courierReliabilityProvider =
    FutureProvider.autoDispose.family<CourierReliability?, String>(
      (ref, courierProfileId) async {
        final result = await ref
            .watch(courierRepositoryProvider)
            .getReliability(courierProfileId);
        return result.fold((failure) => throw failure, (snapshot) => snapshot);
      },
    );

final courierEscrowBalanceProvider =
    FutureProvider.autoDispose.family<CourierMoney, String>(
      (ref, courierProfileId) async {
        final result = await ref
            .watch(courierRepositoryProvider)
            .getEscrowBalance(courierProfileId);
        return result.fold((failure) => throw failure, (money) => money);
      },
    );

/// Whether this device can sign custody events for the given courier.
///
/// Both halves have to line up: the server must list an active key, and this
/// device must hold the matching private half. A courier who registered on
/// another phone passes the first check and fails the second, and that is the
/// case worth catching before they are standing at a doorstep — a pickup with
/// no usable key fails at the signature step with nothing on screen to explain
/// why.
final courierCanSignProvider =
    FutureProvider.autoDispose.family<bool, String>(
      (ref, courierProfileId) async {
        final device = ref.watch(courierDeviceKeyProvider);
        final localKeyId = await device.currentKeyId();
        if (localKeyId == null || !await device.hasKey()) return false;

        final keys = await ref.watch(
          courierDeviceKeysProvider(courierProfileId).future,
        );
        return keys.any((k) => k.isActive && k.publicKeyId == localKeyId);
      },
    );

/// Courier mutations — apply, KYC, device-key enrolment, offers, custody
/// events. The bool is "an action is in flight", which screens read to disable
/// their buttons; the per-call outcome is returned rather than held in state,
/// because two screens can act on different hops at once and a shared
/// last-result field would show one of them the other's error.
final courierActionsNotifierProvider =
    StateNotifierProvider<CourierActionsNotifier, bool>(
      (ref) => CourierActionsNotifier(
        repository: ref.watch(courierRepositoryProvider),
        dataSource: ref.watch(courierRemoteDataSourceProvider),
        deviceKey: ref.watch(courierDeviceKeyProvider),
        location: ref.watch(locationCaptureServiceProvider),
      ),
    );

/// The signed-in account id, or empty when there is no session.
///
/// Read from the session controller rather than token storage so it reacts to
/// sign-out: a courier who logs out mid-shift should not keep seeing hops
/// resolved against the previous account's id.
final courierAccountIdProvider = Provider<String>(
  (ref) => ref.watch(sessionControllerProvider).maybeWhen(
    authenticated: (accountId) => accountId,
    orElse: () => '',
  ),
);
