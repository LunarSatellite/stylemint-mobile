import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/condition_assurance_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/custody_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/delivery_recovery_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/handover_delegation_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/refill_plan_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/condition_assurance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_recovery_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/carbon_impact.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_event_history.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_shipment.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracking_lookup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/customer_returns_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/order_timeline_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_acceptance_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_recovery_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/handover_delegation_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/refill_plan_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/replenishment_rules_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>(
  (ref) => OrdersRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// Delivery Story Mode is the authoritative customer-facing tracking history
/// for first-party P2P shipments. External carriers keep their own timeline.
final deliveryStoryProvider = FutureProvider.autoDispose
    .family<List<DeliveryStoryChapter>, String>((ref, trackingNumber) async {
      final api = ref.watch(apiClientProvider);
      final response = await api.get('/v1/deliveries/$trackingNumber/story');
      return (response as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DeliveryStoryChapter.fromJson)
          .toList(growable: false)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
    });

/// "AI Delivery Guardian" — best-effort risk assessment for one delivery.
/// A failure here should never block the order detail screen.
final deliveryRiskProvider = FutureProvider.autoDispose
    .family<DeliveryRiskAssessment?, String>((ref, trackingNumber) async {
      try {
        final api = ref.watch(apiClientProvider);
        final response =
            await api.get('/v1/deliveries/$trackingNumber/risk')
                as Map<String, dynamic>;
        return DeliveryRiskAssessment.fromJson(response);
      } catch (_) {
        return null;
      }
    });

/// Reads/accepts the recovery remedies for a slipping delivery.
final deliveryRecoveryDataSourceProvider = Provider<DeliveryRecoveryDataSource>(
  (ref) =>
      DeliveryRecoveryRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// The remedies for one delivery, keyed by tracking number.
///
/// Seeded from the risk assessment (which already carries `remedies`, so the
/// common path costs no extra call) and re-read from `/recovery-offers` when
/// an offer lapses or the backend refuses one as expired/stale.
final StateNotifierProviderFamily<
  DeliveryRecoveryNotifier,
  DeliveryRecoveryState,
  String
>
deliveryRecoveryNotifierProvider = StateNotifierProvider.autoDispose
    .family<DeliveryRecoveryNotifier, DeliveryRecoveryState, String>((
      ref,
      trackingNumber,
    ) {
      final notifier = DeliveryRecoveryNotifier(
        dataSource: ref.watch(deliveryRecoveryDataSourceProvider),
        trackingNumber: trackingNumber,
      );
      ref.listen<AsyncValue<DeliveryRiskAssessment?>>(
        deliveryRiskProvider(trackingNumber),
        (_, next) {
          final risk = next.asData?.value;
          if (risk == null) return;
          notifier.adoptFromRisk(
            risk.atRisk ? risk.remedies : const <DeliveryRecoveryOffer>[],
          );
        },
        fireImmediately: true,
      );
      return notifier;
    });

/// Voyager "Tamper/Seal Proof": best-effort read of the package's tamper-
/// evident seal (photo + seal id + sealed timestamp), when the vendor
/// applied one at pack time. Null (no seal section shown) on any failure
/// or when the package was never sealed — this is a trust-building
/// supplementary card, never a blocking read.
final packageSealProvider = FutureProvider.autoDispose
    .family<PackageSeal?, String>((ref, trackingNumber) async {
      try {
        final api = ref.watch(apiClientProvider);
        final response =
            await api.get('/v1/deliveries/$trackingNumber')
                as Map<String, dynamic>;
        final sealPhotoUrl = response['sealPhotoUrl'] as String?;
        final sealId = response['sealId'] as String?;
        if (sealPhotoUrl == null || sealId == null) return null;

        final sealedUtcRaw = response['sealedUtc'] as String?;
        return PackageSeal(
          sealPhotoUrl: sealPhotoUrl,
          sealId: sealId,
          sealedUtc: sealedUtcRaw != null
              ? DateTime.tryParse(sealedUtcRaw)
              : null,
        );
      } catch (_) {
        return null;
      }
    });

/// Reads the chain-of-custody proof for one parcel.
final custodyDataSourceProvider = Provider<CustodyDataSource>(
  (ref) => CustodyRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// Reads the condition and tamper record for one parcel.
final conditionAssuranceDataSourceProvider =
    Provider<ConditionAssuranceDataSource>(
      (ref) => ConditionAssuranceRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

/// "Condition and tamper assurance": what was recorded about the state of
/// this parcel, in the server's own words, identical to what the seller sees.
///
/// Null when there is nothing to show — no controls, no findings, or the
/// endpoint is unavailable — and the card then renders nothing at all. An
/// absent card is deliberately *not* the same as `notRecorded`: the app says
/// nothing rather than asserting an absence of evidence it never read.
final FutureProviderFamily<ConditionAssurance?, String>
conditionAssuranceProvider = FutureProvider.autoDispose
    .family<ConditionAssurance?, String>(
      (ref, trackingNumber) =>
          ref.watch(conditionAssuranceDataSourceProvider).fetch(trackingNumber),
    );

/// "Permissioned Chain-of-Custody Proof": the signed, hash-chained log of
/// every handover of this parcel, plus the backend's own integrity verdict.
///
/// Null when there is nothing to prove — no entries, or the endpoint is
/// unavailable — and the custody card then renders nothing at all. It is a
/// supplementary trust surface, never a blocking read and never an error
/// state on order detail.
final FutureProviderFamily<CustodyProof?, String> custodyProofProvider =
    FutureProvider.autoDispose.family<CustodyProof?, String>(
      (ref, trackingNumber) =>
          ref.watch(custodyDataSourceProvider).fetch(trackingNumber),
    );

/// Resolves a delivery tracking number to the customer's own order number in
/// a single call — `GET /v1/orders/by-tracking/{trackingNumber}`.
///
/// The backend answers the whole question and is scoped to the authenticated
/// customer, so there is nothing to scan and nothing to cap: a tracking
/// number from a months-old notification resolves as long as the parcel
/// exists and is the caller's.
///
/// Its 404 is deliberately ambiguous — unknown, someone else's, or an
/// unreadable order all return the identical response, so that a reply cannot
/// confirm a stranger's guess named a real parcel. That collapses to one
/// [TrackingLookupNotFound] here and the screen must keep it that way.
/// The 20/min rate limit is a separate answer ([TrackingLookupRateLimited]):
/// "ask again shortly", never "we couldn't find it". Any other failure is
/// rethrown and lands on the same not-found surface as before.
// The family type this returns is not exported under the imports this file
// uses, and every other provider here is declared the same way.
// ignore: specify_nonobvious_property_types
final orderNumberForTrackingProvider = FutureProvider.autoDispose
    .family<TrackingLookup, String>((ref, trackingNumber) async {
      final tracking = trackingNumber.trim();
      // A blank tracking number is malformed input (the backend answers 400);
      // there is nothing to ask about, so don't spend a call on it.
      if (tracking.isEmpty) return const TrackingLookupNotFound();

      final dataSource = ref.watch(ordersRemoteDataSourceProvider);
      try {
        return TrackingLookupResolved(
          await dataSource.resolveOrderNumberByTracking(tracking),
        );
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status == 429) return const TrackingLookupRateLimited();
        if (status == 404 || status == 400) {
          return const TrackingLookupNotFound();
        }
        rethrow;
      }
    });

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Voyager "Carbon impact of delivery" — the customer's cumulative CO2
/// saved by community delivery. Best-effort: null (no card) on any failure
/// or 404, and when nothing has been saved yet. Errors are swallowed here
/// rather than surfaced so Riverpod's automatic retry never kicks in for a
/// supplementary card.
final carbonImpactProvider = FutureProvider.autoDispose<CarbonImpact?>((
  ref,
) async {
  try {
    final result = await ref.watch(ordersRepositoryProvider).getCarbonImpact();
    return result.fold(
      (_) => null,
      (impact) => impact.hasSavings ? impact : null,
    );
  } catch (_) {
    return null;
  }
});

/// Voyager "Post-Purchase Care" — per-item next steps and return deadlines
/// for one order, keyed by order number. Best-effort like the carbon card:
/// null (no card) on any failure, 404 or an empty plan, with errors
/// swallowed so Riverpod's automatic retry never runs for a supplementary
/// card.
final orderCarePlanProvider = FutureProvider.autoDispose
    .family<OrderCarePlan?, String>((ref, orderNumber) async {
      try {
        final result = await ref
            .watch(ordersRepositoryProvider)
            .getOrderCarePlan(orderNumber);
        return result.fold(
          (_) => null,
          (plan) => plan.items.isEmpty ? null : plan,
        );
      } catch (_) {
        return null;
      }
    });

final warrantyClaimsProvider = FutureProvider.autoDispose<List<WarrantyClaim>>((
  ref,
) async {
  final result = await ref.watch(ordersRepositoryProvider).getWarrantyClaims();
  return result.fold((_) => const <WarrantyClaim>[], (claims) => claims);
});

/// Voyager "Verified Scan-to-Receive Handover" — asks the buyer what arrived
/// once a StyleMint parcel is out for delivery or delivered, then shows the
/// saved answer. Keyed by tracking number; autoDispose so reopening the
/// order checks again.
final deliveryAcceptanceNotifierProvider = StateNotifierProvider.family
    .autoDispose<DeliveryAcceptanceNotifier, DeliveryAcceptanceState, String>(
      (ref, trackingNumber) => DeliveryAcceptanceNotifier(
        ref.watch(ordersRepositoryProvider),
        trackingNumber,
      ),
    );

final orderInvoiceProvider = FutureProvider.autoDispose
    .family<OrderInvoice, String>((ref, orderNumber) async {
      final result = await ref
          .watch(ordersRepositoryProvider)
          .getOrderInvoice(
            orderNumber,
          );
      return result.match(
        (failure) => throw StateError(failure.toString()),
        (invoice) => invoice,
      );
    });

final trackOrdersNotifierProvider =
    StateNotifierProvider.autoDispose<TrackOrdersNotifier, TrackOrdersState>(
      (ref) => TrackOrdersNotifier(ref.watch(ordersRepositoryProvider)),
    );

/// Bumped by [CustomerShellScreen] every time the Orders tab is switched to.
/// autoDispose alone doesn't refetch here: go_router's StatefulNavigationShell
/// keeps every branch's widget tree mounted (just hidden) when you switch
/// tabs, so the screen never actually stops listening to the provider and it
/// never gets disposed — same reason the Home-tab reels refresh needs its own
/// [homeTabReselectedProvider]-style counter instead of relying on lifecycle.
final ordersTabVisitedProvider = StateProvider<int>((ref) => 0);

// family<orderNumber>.autoDispose — a single shared (non-family) notifier
// let an older in-flight loadOrder(orderA) response overwrite state after a
// newer loadOrder(orderB) had already started (navigating detail -> detail
// for a different order reuses the same instance), showing the wrong
// order's address/items. Keying by order number gives each order its own
// notifier, and autoDispose means revisiting one refetches fresh instead of
// showing whatever was last loaded into the shared singleton.
final orderDetailNotifierProvider = StateNotifierProvider.family
    .autoDispose<OrderDetailNotifier, OrderDetailState, String>(
      (ref, orderNumber) =>
          OrderDetailNotifier(ref.watch(ordersRepositoryProvider)),
    );

final cancelOrderControllerProvider =
    StateNotifierProvider.autoDispose<
      CancelOrderController,
      CancelOrderUiState
    >(
      (ref) => CancelOrderController(ref.watch(ordersRepositoryProvider)),
    );

/// What actually happened to one order — `GET /v1/orders/{orderNumber}/events`.
///
/// Unlike the supplementary cards above, a failure here is NOT swallowed into
/// null. This is the order's history: if the read fails the screen has to say
/// so, because silently rendering "no events" would present a failed read as
/// the fact that nothing happened. The widget handles the error state; the
/// rest of the order detail is unaffected either way.
final FutureProviderFamily<OrderEventHistory, String>
orderEventHistoryProvider = FutureProvider.autoDispose
    .family<OrderEventHistory, String>((ref, orderNumber) async {
      final result = await ref
          .watch(ordersRepositoryProvider)
          .getOrderEventHistory(orderNumber);
      return result.match(
        (failure) => throw StateError(failure.toString()),
        (history) => history,
      );
    });

/// Buyer tracking timeline per order number (Orders contract §3).
final StateNotifierProviderFamily<
  OrderTimelineNotifier,
  OrderTimelineState,
  String
>
orderTimelineNotifierProvider = StateNotifierProvider.autoDispose
    .family<OrderTimelineNotifier, OrderTimelineState, String>(
      (ref, orderNumber) => OrderTimelineNotifier(
        ref.watch(ordersRepositoryProvider),
        orderNumber,
      ),
    );

/// "My returns" list (Orders contract §4).
final StateNotifierProvider<MyReturnsNotifier, MyReturnsState>
myReturnsNotifierProvider =
    StateNotifierProvider.autoDispose<MyReturnsNotifier, MyReturnsState>(
      (ref) => MyReturnsNotifier(ref.watch(ordersRepositoryProvider)),
    );

/// One return request, keyed by id.
final StateNotifierProviderFamily<
  ReturnDetailNotifier,
  ReturnDetailState,
  String
>
returnDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReturnDetailNotifier, ReturnDetailState, String>(
      (ref, returnId) => ReturnDetailNotifier(
        ref.watch(ordersRepositoryProvider),
        returnId,
      ),
    );

/// Best-effort reverse-logistics tracking for an approved return. Older
/// backends and not-yet-approved returns return null so this supplementary
/// card never blocks the core return details.
final returnPickupProvider = FutureProvider.autoDispose
    .family<ReturnPickup?, String>((ref, returnRequestId) async {
      try {
        final response = await ref
            .watch(apiClientProvider)
            .get('/v1/deliveries/returns/$returnRequestId');
        return ReturnPickup.fromJson(response as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    });

/// Best-effort outbound tracking created after a replacement is approved and
/// the returned item has reached the seller.
final replacementShipmentProvider = FutureProvider.autoDispose
    .family<ReplacementShipment?, String>((ref, returnRequestId) async {
      try {
        final response = await ref
            .watch(apiClientProvider)
            .get('/v1/deliveries/replacements/$returnRequestId');
        return ReplacementShipment.fromJson(response as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    });

final replenishmentPreferenceNotifierProvider =
    StateNotifierProvider.autoDispose<
      ReplenishmentPreferenceNotifier,
      ReplenishmentPreferenceState
    >(
      (ref) =>
          ReplenishmentPreferenceNotifier(ref.watch(ordersRepositoryProvider)),
    );
final reorderSuggestionsNotifierProvider =
    StateNotifierProvider.autoDispose<
      ReorderSuggestionsNotifier,
      ReorderSuggestionsState
    >(
      (ref) => ReorderSuggestionsNotifier(ref.watch(ordersRepositoryProvider)),
    );

// ── Delegated parcel handover ───────────────────────────────────────────────
//
// Deliberately only two providers, and neither can hold a verification code:
// the data source is stateless, and [HandoverDelegationState] has no field for
// one. Creation is driven from the sheet's own `State` so the code never
// enters provider scope, which outlives the screen.

/// Creates, lists and revokes handover delegations for one parcel.
final handoverDelegationDataSourceProvider =
    Provider<HandoverDelegationDataSource>(
      (ref) => HandoverDelegationRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

/// The delegations for one parcel, keyed by tracking number. Never holds a
/// verification code — see [HandoverDelegationState].
final StateNotifierProviderFamily<
  HandoverDelegationNotifier,
  HandoverDelegationState,
  String
>
handoverDelegationNotifierProvider = StateNotifierProvider.autoDispose
    .family<HandoverDelegationNotifier, HandoverDelegationState, String>(
      (ref, trackingNumber) => HandoverDelegationNotifier(
        dataSource: ref.watch(handoverDelegationDataSourceProvider),
        trackingNumber: trackingNumber,
      ),
    );

// ── Prepared refill basket, and the rules that govern it ────────────────────
//
// The Prepare stage of predictive replenishment. Everything here is a
// proposal: no provider in this block can place an order, reserve stock or
// move money, and none may be added that can.

/// `/v1/customer/refill-plans` plus the rules and pause routes.
final refillPlanDataSourceProvider = Provider<RefillPlanDataSource>(
  (ref) => RefillPlanRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// The customer's open refill basket. `autoDispose` so reopening the screen
/// re-reads rather than showing a basket whose prices have since expired.
final StateNotifierProvider<RefillPlanNotifier, RefillPlanState>
refillPlanNotifierProvider =
    StateNotifierProvider.autoDispose<RefillPlanNotifier, RefillPlanState>(
      (ref) => RefillPlanNotifier(ref.watch(refillPlanDataSourceProvider)),
    );

/// The whole replenishment rule set, including the on/off switch and any
/// pause. Kept separate from [replenishmentPreferenceNotifierProvider], which
/// owns only the on/off switch and is what the existing Buy-It-Again surface
/// reads — this one is additive and changes nothing there.
final StateNotifierProvider<
  ReplenishmentRulesNotifier,
  ReplenishmentRulesState
>
replenishmentRulesNotifierProvider =
    StateNotifierProvider.autoDispose<
      ReplenishmentRulesNotifier,
      ReplenishmentRulesState
    >(
      (ref) =>
          ReplenishmentRulesNotifier(ref.watch(refillPlanDataSourceProvider)),
    );
