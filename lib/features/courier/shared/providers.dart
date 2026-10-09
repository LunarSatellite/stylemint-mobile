import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateNotifierProvider lives here in Riverpod 3; without it the type
// cannot resolve, `ref` degrades to dynamic and every ref.watch in the
// notifier provider below fails to assign.
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_kyc_documents.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_device_key.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_location_reporter.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/osrm_route_planner.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/rider_locator.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_job_notifiers.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
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

/// What the courier has earned from completed hops.
///
/// Keyed by nothing: the server resolves the courier from the caller's token,
/// so unlike escrow and reliability this takes no profile id. autoDispose so
/// the figure is re-read on return rather than shown stale after a delivery.
final courierEarningsProvider = FutureProvider.autoDispose<CourierEarnings>(
  (ref) async {
    final result = await ref.watch(courierRepositoryProvider).getEarnings();
    return result.fold((failure) => throw failure, (earnings) => earnings);
  },
);

/// The completed hops behind that total, newest first.
final courierEarningsHistoryProvider =
    FutureProvider.autoDispose<List<CourierEarningRow>>((ref) async {
      final result = await ref
          .watch(courierRepositoryProvider)
          .listEarningsHistory();
      return result.fold((failure) => throw failure, (rows) => rows);
    });

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

/// Where the rider's live position comes from. Overridden in tests.
final courierPositionSourceProvider = Provider<CourierPositionSource>(
  (ref) => GeolocatorCourierPositionSource(
    ref.watch(locationCaptureServiceProvider),
  ),
);

/// Reports the rider's position while they are online and the app is open.
/// One per app: started and stopped by `CourierLocationBeacon`, and stopped
/// for good when the provider graph is torn down (sign-out).
final courierLocationReporterProvider = Provider<CourierLocationReporter>((
  ref,
) {
  final repository = ref.watch(courierRepositoryProvider);
  final reporter = CourierLocationReporter(
    positions: ref.watch(courierPositionSourceProvider),
    send: (fix) async {
      final result = await repository.reportLocation(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracyMetres,
      );
      // Silent by design: a missed report is replaced within a minute, and a
      // rider should never see an error about something they did not do.
      result.fold((failure) {
        if (kDebugMode) {
          debugPrint('[courier-location] report refused: $failure');
        }
      }, (_) {});
    },
  );
  ref.onDispose(reporter.stop);
  return reporter;
});

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

/// Puts a courier's identity documents through Identity's KYC pipeline.
///
/// Built on the account-scoped document client that creator apply already
/// uses — see [CourierKycDocuments] for why there is no courier-specific
/// document API and should not be one.
final courierKycDocumentsProvider = Provider<CourierKycDocuments>(
  (ref) => CourierKycDocuments(
    ref.watch(creatorDocumentsRemoteDataSourceProvider),
  ),
);

// ── Jobs: the in-app job map and QR proof of delivery ─────────────────────

/// One job, for the job screen. autoDispose so reopening the screen re-reads
/// rather than showing a status the rider has since moved past.
///
/// No automatic retry: Riverpod's default retries a failing provider in the
/// background and the screen stays on its loader the whole time, so a 404 or
/// an offline phone looked like an endless spinner. A failure shows the error
/// and a "Try again" button instead.
final courierJobProvider = FutureProvider.autoDispose
    .family<CourierJob, String>(
      (ref, hopId) async {
        final result = await ref.watch(courierRepositoryProvider).getJob(hopId);
        return result.fold((failure) => throw failure, (job) => job);
      },
      retry: (_, _) => null,
    );

/// The rider's jobs — active ones and the last day's completed ones — for
/// the dashboard's "Delivered today".
///
/// A failure is an empty list rather than an error: the list is a record,
/// not something the rider acts on, and an error here would only start
/// Riverpod's automatic retry against an endpoint that is not answering.
final courierJobsProvider = FutureProvider.autoDispose<List<CourierJob>>((
  ref,
) async {
  final result = await ref.watch(courierRepositoryProvider).listJobs();
  return result.fold((_) => const <CourierJob>[], (jobs) => jobs);
});

final courierJobActionsNotifierProvider =
    StateNotifierProvider.autoDispose<CourierJobActionsNotifier, bool>(
      (ref) => CourierJobActionsNotifier(ref.watch(courierRepositoryProvider)),
    );

/// How often the QR screen asks whether the recipient has scanned. Overridden
/// in tests.
final deliveryProofPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

/// One hop's proof of delivery. Keyed by the hop and the proof the screen was
/// opened with ("Complete ride" already returned one), so opening it does not
/// read the same proof twice.
final deliveryProofNotifierProvider = StateNotifierProvider.autoDispose
    .family<
      DeliveryProofNotifier,
      DeliveryProofState,
      ({String hopId, DeliveryProof? initial})
    >(
      (ref, args) => DeliveryProofNotifier(
        ref.watch(courierRepositoryProvider),
        args.hopId,
        initial: args.initial,
        pollInterval: ref.watch(deliveryProofPollIntervalProvider),
      ),
    );

/// Road routes for the job map. Overridden in tests so they never touch the
/// network; the map falls back to straight lines on a null.
final courierRoutePlannerProvider = Provider<CourierRoutePlanner>(
  (ref) => OsrmRoutePlanner(),
);

/// The rider's live position on the job map. Overridden in tests.
final riderLocatorProvider = Provider<RiderLocator>(
  (ref) => DeviceRiderLocator(
    capture: ref.watch(locationCaptureServiceProvider),
    positions: ref.watch(courierPositionSourceProvider),
  ),
);

/// Whether the job map loads OpenStreetMap tiles. Off in widget tests, where
/// there is no network to load them from.
final courierMapTilesEnabledProvider = Provider<bool>((ref) => true);
