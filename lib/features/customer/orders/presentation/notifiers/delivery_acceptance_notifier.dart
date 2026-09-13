import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

sealed class DeliveryAcceptanceState {
  const DeliveryAcceptanceState();
}

/// Checking the parcel and any saved answer; the card shows nothing yet.
final class DeliveryAcceptanceChecking extends DeliveryAcceptanceState {
  const DeliveryAcceptanceChecking();
}

/// Nothing to show: the parcel isn't out for delivery yet, the package
/// wasn't found, or a check failed.
final class DeliveryAcceptanceHidden extends DeliveryAcceptanceState {
  const DeliveryAcceptanceHidden();
}

/// The parcel is out for delivery or delivered and no answer is saved yet.
final class DeliveryAcceptanceAsking extends DeliveryAcceptanceState {
  const DeliveryAcceptanceAsking({
    required this.hasSeal,
    this.sending = false,
    this.errorMessage,
  });

  /// The seller sealed the package, so the buyer must say if it was intact.
  final bool hasSeal;

  /// The answer is on its way; controls are disabled meanwhile.
  final bool sending;

  /// Why the last send didn't go through.
  final String? errorMessage;
}

/// The buyer's saved answer, shown read-only.
final class DeliveryAcceptanceRecorded extends DeliveryAcceptanceState {
  const DeliveryAcceptanceRecorded(this.acceptance, {this.notice});

  final DeliveryAcceptance acceptance;

  /// Set when the buyer just sent a different answer and the saved one was
  /// kept instead.
  final String? notice;
}

/// Voyager "Verified Scan-to-Receive Handover" for one StyleMint parcel:
/// works out whether to ask the buyer what arrived, sends their answer, and
/// shows the saved record.
class DeliveryAcceptanceNotifier
    extends StateNotifier<DeliveryAcceptanceState> {
  DeliveryAcceptanceNotifier(this._repository, this.trackingNumber)
    : super(const DeliveryAcceptanceChecking()) {
    unawaited(load());
  }

  static const alreadySavedNotice =
      'You had already answered for this parcel, so that answer was kept.';
  static const sendFailedMessage =
      "Couldn't send your answer. Please try again.";

  final OrdersRepository _repository;
  final String trackingNumber;

  Future<void> load() async {
    state = const DeliveryAcceptanceChecking();
    final next = await _check();
    if (mounted) state = next;
  }

  Future<void> submit({
    required DeliveryAcceptanceOutcome outcome,
    bool? sealIntact,
    String? issueNote,
  }) async {
    final asking = state;
    if (asking is! DeliveryAcceptanceAsking || asking.sending) return;
    final hasSeal = asking.hasSeal;

    final problem = deliveryAcceptanceProblem(
      outcome: outcome,
      hasSeal: hasSeal,
      sealIntact: sealIntact,
      issueNote: issueNote,
    );
    if (problem != null) {
      state = DeliveryAcceptanceAsking(hasSeal: hasSeal, errorMessage: problem);
      return;
    }

    state = DeliveryAcceptanceAsking(hasSeal: hasSeal, sending: true);
    Either<NetworkExceptions, DeliveryAcceptance> result;
    try {
      result = await _repository.recordDeliveryAcceptance(
        trackingNumber,
        outcome: outcome,
        // An unsealed package has no seal to report on.
        sealIntact: hasSeal ? sealIntact : null,
        issueNote: outcome.needsNote ? issueNote?.trim() : null,
      );
    } on Object catch (_) {
      result = left(const NetworkExceptions.unexpectedError());
    }
    if (!mounted) return;

    final saved = result.getRight().toNullable();
    if (saved != null) {
      state = DeliveryAcceptanceRecorded(saved);
      return;
    }

    final failure =
        result.getLeft().toNullable() ??
        const NetworkExceptions.unexpectedError();
    if (failure.isConflict) {
      // A different answer is already saved; it can't be changed, so show it.
      final next = await _check(notice: alreadySavedNotice);
      if (!mounted) return;
      state = next is DeliveryAcceptanceRecorded
          ? next
          : DeliveryAcceptanceAsking(
              hasSeal: hasSeal,
              errorMessage: sendFailedMessage,
            );
    } else if (failure.isNotFound) {
      state = const DeliveryAcceptanceHidden();
    } else {
      state = DeliveryAcceptanceAsking(
        hasSeal: hasSeal,
        errorMessage: _sendErrorMessage(failure),
      );
    }
  }

  /// A saved answer always wins. Otherwise ask only when the parcel is out
  /// for delivery or delivered and the backend says nothing is saved (404);
  /// any other failure hides the card.
  Future<DeliveryAcceptanceState> _check({String? notice}) async {
    try {
      final (package, acceptance) = await (
        _repository.getDeliveryPackageStatus(trackingNumber),
        _repository.getDeliveryAcceptance(trackingNumber),
      ).wait;

      final saved = acceptance.getRight().toNullable();
      if (saved != null) {
        return DeliveryAcceptanceRecorded(saved, notice: notice);
      }

      final notAnsweredYet =
          acceptance.getLeft().toNullable()?.isNotFound ?? false;
      final status = package.getRight().toNullable();
      if (!notAnsweredYet || status == null || !status.canRecordAcceptance) {
        return const DeliveryAcceptanceHidden();
      }
      return DeliveryAcceptanceAsking(hasSeal: status.hasSeal);
    } on Object catch (_) {
      return const DeliveryAcceptanceHidden();
    }
  }
}

String _sendErrorMessage(NetworkExceptions failure) {
  if (failure.isNoInternet) {
    return 'No internet connection. Please try again.';
  }
  // 400s carry the backend's own sentence, e.g. "You can confirm a parcel
  // once it is out for delivery or delivered."
  final backendMessage = failure.maybeWhen(
    validation: (_, message, _, errors) =>
        errors.isNotEmpty ? errors.first.message : message,
    orElse: () => null,
  );
  final trimmed = backendMessage?.trim() ?? '';
  return trimmed.isEmpty
      ? DeliveryAcceptanceNotifier.sendFailedMessage
      : trimmed;
}
