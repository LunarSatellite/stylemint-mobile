/// The StyleMint-rider delivery behind a buyer's order, as the order detail
/// reports it (`delivery` on the order / sub-order DTO).
///
/// Only present for parcels carried by StyleMint riders. Its one job on the
/// order screen is [awaitingConfirmation]: the rider is at the door and has
/// shown a QR, so the buyer is asked to confirm.
class OrderDelivery {
  const OrderDelivery({
    required this.packageNumber,
    required this.status,
    required this.awaitingConfirmation,
    this.riderName,
    this.subOrderId,
  });

  /// `SM-D-00000013` — prefilled in the "Enter code" form.
  final String packageNumber;

  /// The delivery's own status string, as sent. Read loosely — see
  /// [isOutForDelivery] and [isDelivered].
  final String status;
  final bool awaitingConfirmation;
  final String? riderName;

  /// The sub-order this delivery belongs to, when it came from one.
  final String? subOrderId;

  String get _normalised => status.toLowerCase().replaceAll(RegExp('[ _-]'), '');

  /// With the rider and heading to the buyer — the moment to have the
  /// scanner ready even before the QR is shown.
  bool get isOutForDelivery => const {
    'pickedup',
    'outfordelivery',
    'intransit',
    'awaitingconfirmation',
  }.contains(_normalised);

  bool get isDelivered => _normalised == 'delivered';
}

/// What `POST /v1/customer/deliveries/confirm` answered.
class DeliveryConfirmation {
  const DeliveryConfirmation({
    required this.orderId,
    required this.subOrderId,
    required this.packageNumber,
    required this.status,
    this.deliveredUtc,
  });

  final String orderId;
  final String subOrderId;
  final String packageNumber;
  final String status;
  final DateTime? deliveredUtc;
}

/// Why a delivery could not be confirmed, in the terms the buyer needs.
///
/// Keyed on the contract's `delivery_proof.*` error codes rather than HTTP
/// statuses: a 403 here means "not your parcel", which is a different
/// sentence from "please sign in again".
sealed class DeliveryConfirmFailure {
  const DeliveryConfirmFailure();
}

/// `delivery_proof.not_recipient` — only the order's buyer can confirm.
final class DeliveryConfirmNotRecipient extends DeliveryConfirmFailure {
  const DeliveryConfirmNotRecipient();
}

/// `delivery_proof.expired` — the rider needs to show a new code.
final class DeliveryConfirmExpired extends DeliveryConfirmFailure {
  const DeliveryConfirmExpired();
}

/// `delivery_proof.invalid` — not a live code for any parcel, or a wrong
/// 6-digit code.
final class DeliveryConfirmInvalid extends DeliveryConfirmFailure {
  const DeliveryConfirmInvalid();
}

/// `delivery_proof.too_many_attempts` — five wrong codes lock it for 15
/// minutes.
final class DeliveryConfirmTooManyAttempts extends DeliveryConfirmFailure {
  const DeliveryConfirmTooManyAttempts();
}

/// `delivery_proof.already_confirmed`, should a server send it as an error
/// rather than the contract's idempotent 200.
final class DeliveryConfirmAlreadyConfirmed extends DeliveryConfirmFailure {
  const DeliveryConfirmAlreadyConfirmed();
}

/// Anything else: offline, server down, a code this app does not know.
final class DeliveryConfirmOtherFailure extends DeliveryConfirmFailure {
  const DeliveryConfirmOtherFailure({this.message, this.offline = false});

  /// The server's own sentence, when it sent one.
  final String? message;
  final bool offline;
}
