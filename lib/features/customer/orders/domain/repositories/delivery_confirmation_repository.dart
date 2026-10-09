import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';

/// The recipient's side of proof of delivery:
/// `POST /v1/customer/deliveries/confirm`.
///
/// Its own repository rather than more methods on `OrdersRepository`: the
/// failures are specific to this one call (not your parcel, expired, wrong
/// code, locked out) and the screens need them as themselves.
abstract interface class DeliveryConfirmationRepository {
  /// Confirms with the rider's scanned QR link. Mints its own
  /// Idempotency-Key — one call is one scan.
  Future<Either<DeliveryConfirmFailure, DeliveryConfirmation>> confirmByQr(
    String qrPayload,
  );

  /// Confirms with the package number and the rider's 6-digit code.
  Future<Either<DeliveryConfirmFailure, DeliveryConfirmation>> confirmByCode({
    required String packageNumber,
    required String code,
  });
}
