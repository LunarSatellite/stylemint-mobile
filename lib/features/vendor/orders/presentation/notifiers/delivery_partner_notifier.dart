import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';

/// What the delivery-partner sheet is showing.
///
/// Plain sealed classes rather than a generated union: the sheet switches on
/// them exhaustively, and the one live state carries the request itself, so
/// there is nothing for codegen to add.
sealed class DeliveryPartnerState {
  const DeliveryPartnerState();
}

/// Reading the current request, or opening one when [finding].
final class DeliveryPartnerLoading extends DeliveryPartnerState {
  const DeliveryPartnerLoading({this.finding = false});

  final bool finding;
}

/// No request has been opened for this parcel yet.
final class DeliveryPartnerNotRequested extends DeliveryPartnerState {
  const DeliveryPartnerNotRequested();
}

/// A request is open (or settled), and this is the latest word on it.
final class DeliveryPartnerLive extends DeliveryPartnerState {
  const DeliveryPartnerLive(this.request, {this.choosingOfferId});

  final DeliveryRequest request;

  /// The rider whose selection is in flight, so only their card spins.
  final String? choosingOfferId;

  bool get choosing => choosingOfferId != null;
}

/// The request could not be read or opened. Distinct from "no riders": a 500
/// or a dropped connection says nothing about who is nearby, and telling the
/// vendor otherwise sends them to their own courier for no reason.
final class DeliveryPartnerFailed extends DeliveryPartnerState {
  const DeliveryPartnerFailed(this.failure);

  final NetworkExceptions failure;
}

/// Drives one sub-order's "find a delivery partner" sheet.
///
/// Polls while the request can still change — riders answer over minutes, and
/// the vendor is watching — and stops once it is assigned or expired, or the
/// sheet closes (the provider is autoDispose, so closing disposes this and
/// the timer with it). A `delivery.interest` push calls [refresh] directly so
/// a new rider shows up without waiting for the next tick.
class DeliveryPartnerNotifier extends StateNotifier<DeliveryPartnerState> {
  DeliveryPartnerNotifier(
    this._repository,
    this.subOrderId, {
    this.pollInterval = const Duration(seconds: 5),
    bool autoLoad = true,
  }) : super(const DeliveryPartnerLoading()) {
    if (autoLoad) unawaited(load());
  }

  final VendorOrdersRepository _repository;
  final String subOrderId;
  final Duration pollInterval;

  Timer? _poll;
  bool _refreshing = false;

  /// Bumped by every vendor action, so a poll that was already in flight when
  /// the vendor chose a rider cannot land afterwards and put the stale
  /// "riders interested" list back over the assignment.
  int _generation = 0;

  /// What "Try again" on a failure re-runs: the read that failed, or the
  /// request the vendor was trying to open.
  Future<void> Function()? _retry;

  /// Whether the poll timer is running. Exposed for tests.
  bool get isPolling => _poll?.isActive ?? false;

  /// Reads the current request. A 404 is "none yet", not an error.
  Future<void> load() async {
    _retry = load;
    final generation = ++_generation;
    state = const DeliveryPartnerLoading();
    final either = await _repository.currentDeliveryRequest(subOrderId);
    if (!mounted || generation != _generation) return;
    either.fold(_fail, (request) {
      if (request == null) {
        _stopPolling();
        state = const DeliveryPartnerNotRequested();
      } else {
        _show(request);
      }
    });
  }

  /// Opens a request — or re-opens one that expired or found nobody, which
  /// re-plans the parcel and notifies whoever is in range now.
  Future<void> findPartner() async {
    _retry = findPartner;
    final generation = ++_generation;
    _stopPolling();
    state = const DeliveryPartnerLoading(finding: true);
    final either = await _repository.openDeliveryRequest(subOrderId);
    if (!mounted || generation != _generation) return;
    either.fold(_fail, _show);
  }

  /// Re-reads the request in place. Used by the poll and by a push.
  ///
  /// Silent on failure: one missed poll is not worth replacing a panel full
  /// of riders with an error, and the next tick tries again.
  Future<void> refresh() async {
    if (_refreshing || state is! DeliveryPartnerLive) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final either = await _repository.currentDeliveryRequest(subOrderId);
      if (!mounted || generation != _generation) return;
      final current = state;
      if (current is! DeliveryPartnerLive || current.choosing) return;
      either.fold((_) {}, (request) {
        if (request == null) {
          _stopPolling();
          state = const DeliveryPartnerNotRequested();
        } else {
          _show(request);
        }
      });
    } finally {
      _refreshing = false;
    }
  }

  /// Chooses the rider behind [offerId]. Returns the failure for the sheet to
  /// show, or null on success (the state then carries the assignment).
  Future<NetworkExceptions?> choose(String offerId) async {
    final current = state;
    if (current is! DeliveryPartnerLive || current.choosing) return null;
    final generation = ++_generation;
    state = DeliveryPartnerLive(current.request, choosingOfferId: offerId);
    final either = await _repository.selectDeliveryPartner(
      subOrderId,
      offerId,
    );
    if (!mounted || generation != _generation) return null;
    return either.fold<NetworkExceptions?>(
      (failure) {
        // Back to the list as it was, and re-read it: the usual reason a
        // choice fails is that the rider withdrew or the request closed, and
        // the vendor should see that rather than the same stale card.
        state = DeliveryPartnerLive(current.request);
        unawaited(refresh());
        return failure;
      },
      (request) {
        _show(request);
        return null;
      },
    );
  }

  Future<void> retry() => (_retry ?? load)();

  void _show(DeliveryRequest request) {
    state = DeliveryPartnerLive(request);
    if (request.state.isSettled) {
      _stopPolling();
    } else {
      _startPolling();
    }
  }

  void _fail(NetworkExceptions failure) {
    _stopPolling();
    state = DeliveryPartnerFailed(failure);
  }

  void _startPolling() {
    if (_poll?.isActive ?? false) return;
    _poll = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
