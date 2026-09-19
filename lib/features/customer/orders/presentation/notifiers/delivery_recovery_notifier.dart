import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/delivery_recovery_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_recovery_offer.dart';
import 'package:uuid/uuid.dart';

/// Backend error codes for the two distinct 409s. They mean different things
/// to a person, so they are never collapsed into one generic failure.
class DeliveryRecoveryErrorCodes {
  const DeliveryRecoveryErrorCodes._();

  /// The 30-minute window lapsed before the acceptance reached the backend.
  static const String offerExpired = 'delivery.recovery.offer_expired';

  /// The delivery moved, so the offer no longer matches reality.
  static const String offerStale = 'delivery.recovery.offer_stale';
}

/// What the customer is being told right now, on top of the offer list.
enum DeliveryRecoveryNotice {
  none,

  /// The visible offer's own window ran out while the screen was open, before
  /// the customer tapped anything. Caught client-side so nobody taps into a
  /// guaranteed 409.
  lapsedOnScreen,

  /// 409 `offer_expired` — the window closed in flight. "Ask again."
  expired,

  /// 409 `offer_stale` — the delivery moved. "Here's what's true now."
  stale,

  /// The offer demands the refund-window acknowledgement and it was not
  /// given. No call was made.
  acknowledgementRequired,

  /// Anything else (network, 5xx). Retryable with the same idempotency key.
  failed,

  /// The remedy was carried out.
  accepted,
}

class DeliveryRecoveryState {
  const DeliveryRecoveryState({
    this.offers = const <DeliveryRecoveryOffer>[],
    this.loading = false,
    this.refreshing = false,
    this.acceptingOfferId,
    this.notice = DeliveryRecoveryNotice.none,
    this.acceptedOffer,
  });

  final List<DeliveryRecoveryOffer> offers;
  final bool loading;

  /// A re-read of the offers triggered by a 409 or an on-screen lapse.
  final bool refreshing;

  final String? acceptingOfferId;
  final DeliveryRecoveryNotice notice;

  /// The offer as the backend returned it after a successful acceptance —
  /// carries `outcomeReference` (the refund/ticket the customer can quote).
  final DeliveryRecoveryOffer? acceptedOffer;

  bool get isAccepting => acceptingOfferId != null;

  /// Offers worth putting a control on at [nowUtc].
  List<DeliveryRecoveryOffer> liveOffers(DateTime nowUtc) =>
      offers.where((offer) => offer.isActionableAt(nowUtc)).toList();

  /// Nothing at all to draw: no live offers, nothing in flight, nothing to
  /// say. A delivery that is not at risk lands here.
  bool isSilentAt(DateTime nowUtc) =>
      liveOffers(nowUtc).isEmpty &&
      !loading &&
      !refreshing &&
      !isAccepting &&
      notice == DeliveryRecoveryNotice.none;

  DeliveryRecoveryState copyWith({
    List<DeliveryRecoveryOffer>? offers,
    bool? loading,
    bool? refreshing,
    String? acceptingOfferId,
    bool clearAccepting = false,
    DeliveryRecoveryNotice? notice,
    DeliveryRecoveryOffer? acceptedOffer,
  }) => DeliveryRecoveryState(
    offers: offers ?? this.offers,
    loading: loading ?? this.loading,
    refreshing: refreshing ?? this.refreshing,
    acceptingOfferId: clearAccepting
        ? null
        : (acceptingOfferId ?? this.acceptingOfferId),
    notice: notice ?? this.notice,
    acceptedOffer: acceptedOffer ?? this.acceptedOffer,
  );
}

/// Owns the remedies for one delivery: which are still live, what happens
/// when one is accepted, and what the customer is told when the backend
/// refuses because the offer expired or went stale.
class DeliveryRecoveryNotifier extends StateNotifier<DeliveryRecoveryState> {
  DeliveryRecoveryNotifier({
    required DeliveryRecoveryDataSource dataSource,
    required this.trackingNumber,
    DateTime Function()? clock,
    Uuid uuid = const Uuid(),
  }) : _dataSource = dataSource,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _uuid = uuid,
       super(const DeliveryRecoveryState());

  final DeliveryRecoveryDataSource _dataSource;
  final String trackingNumber;
  final DateTime Function() _clock;
  final Uuid _uuid;

  /// One key per acceptance *attempt*, kept until that attempt resolves, so
  /// a retried tap cannot file two support tickets or two cancellations.
  final Map<String, String> _attemptKeys = <String, String>{};

  Timer? _lapseTimer;

  @override
  void dispose() {
    _lapseTimer?.cancel();
    super.dispose();
  }

  /// The risk call already carries the remedies, so the common path costs no
  /// extra round trip. Ignored once the customer has committed to an offer,
  /// so a background risk refresh can't yank the confirmation out from under
  /// them.
  void adoptFromRisk(List<DeliveryRecoveryOffer> remedies) {
    if (state.isAccepting || state.notice == DeliveryRecoveryNotice.accepted) {
      return;
    }
    state = state.copyWith(offers: remedies, loading: false);
    _scheduleLapseCheck();
  }

  /// Re-reads the offers. Used on pull-to-refresh and after either 409 —
  /// the customer is never left on a dead screen holding a refused offer.
  Future<void> refresh({bool silent = false}) async {
    if (!mounted) return;
    state = state.copyWith(refreshing: !silent, loading: state.offers.isEmpty);
    try {
      final offers = await _dataSource.listOffers(trackingNumber);
      if (!mounted) return;
      state = state.copyWith(
        offers: offers,
        loading: false,
        refreshing: false,
      );
    } on Object catch (_) {
      if (!mounted) return;
      // A failed re-read must not erase what is already on screen; the
      // per-offer lapse check still governs what stays tappable.
      state = state.copyWith(loading: false, refreshing: false);
    }
    _scheduleLapseCheck();
  }

  /// Accept [offer]. [acknowledgeRefundWindow] is the customer's own active
  /// confirmation — it is never defaulted to true anywhere in this flow, and
  /// an offer that demands it is not sent without it.
  Future<void> accept(
    DeliveryRecoveryOffer offer, {
    required bool acknowledgeRefundWindow,
  }) async {
    if (state.isAccepting) return;

    if (offer.requiresRefundWindowAcknowledgement && !acknowledgeRefundWindow) {
      state = state.copyWith(
        notice: DeliveryRecoveryNotice.acknowledgementRequired,
      );
      return;
    }

    // The window can close between the offer rendering and the tap landing.
    // Check before spending a call that is certain to come back 409.
    if (!offer.isActionableAt(_clock())) {
      _attemptKeys.remove(offer.offerId);
      state = state.copyWith(notice: DeliveryRecoveryNotice.lapsedOnScreen);
      await refresh(silent: true);
      return;
    }

    final idempotencyKey = _attemptKeys.putIfAbsent(
      offer.offerId,
      _uuid.v4,
    );

    state = state.copyWith(
      acceptingOfferId: offer.offerId,
      notice: DeliveryRecoveryNotice.none,
    );

    try {
      final accepted = await _dataSource.acceptOffer(
        trackingNumber: trackingNumber,
        offerId: offer.offerId,
        acknowledgeRefundWindow: acknowledgeRefundWindow,
        idempotencyKey: idempotencyKey,
      );
      _attemptKeys.remove(offer.offerId);
      _lapseTimer?.cancel();
      if (!mounted) return;
      state = state.copyWith(
        clearAccepting: true,
        notice: DeliveryRecoveryNotice.accepted,
        acceptedOffer: accepted,
        offers: const <DeliveryRecoveryOffer>[],
      );
    } on Object catch (error) {
      if (!mounted) return;
      final code = _errorCodeOf(error);
      switch (code) {
        case DeliveryRecoveryErrorCodes.offerExpired:
          // The attempt is over — a fresh offer deserves a fresh key.
          _attemptKeys.remove(offer.offerId);
          state = state.copyWith(
            clearAccepting: true,
            notice: DeliveryRecoveryNotice.expired,
          );
          await refresh(silent: true);
        case DeliveryRecoveryErrorCodes.offerStale:
          _attemptKeys.remove(offer.offerId);
          state = state.copyWith(
            clearAccepting: true,
            notice: DeliveryRecoveryNotice.stale,
          );
          await refresh(silent: true);
        default:
          // Transient: keep the key so "Try again" is the same attempt.
          state = state.copyWith(
            clearAccepting: true,
            notice: DeliveryRecoveryNotice.failed,
          );
      }
    }
  }

  /// Clears a notice the customer has read, without touching the offers.
  void dismissNotice() {
    if (state.notice == DeliveryRecoveryNotice.accepted) return;
    state = state.copyWith(notice: DeliveryRecoveryNotice.none);
  }

  /// Exposed for the card's countdown and for tests; always UTC.
  DateTime now() => _clock();

  /// Fires once, at the soonest expiry among the live offers, so an offer
  /// that lapses in front of the customer visibly stops being tappable and
  /// the fresh set is fetched — instead of sitting there as a trap.
  void _scheduleLapseCheck() {
    _lapseTimer?.cancel();
    if (!mounted) return;
    final now = _clock();
    DateTime? soonest;
    for (final offer in state.offers) {
      if (!offer.isActionableAt(now)) continue;
      if (soonest == null || offer.expiresUtc.isBefore(soonest)) {
        soonest = offer.expiresUtc;
      }
    }
    if (soonest == null) return;
    final delay = soonest.difference(now) + const Duration(seconds: 1);
    _lapseTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted) return;
      if (state.isAccepting) return;
      state = state.copyWith(notice: DeliveryRecoveryNotice.lapsedOnScreen);
      unawaited(refresh(silent: true));
    });
  }

  static String? _errorCodeOf(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    if (data is Map) return data['errorCode'] as String?;
    return null;
  }
}
