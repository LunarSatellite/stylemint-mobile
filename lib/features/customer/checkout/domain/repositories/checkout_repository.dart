import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

abstract interface class CheckoutRepository {
  Future<Either<NetworkExceptions, CheckoutSummary>> getCheckoutSummary();

  Future<Either<NetworkExceptions, List<ShippingAddress>>>
  getShippingAddresses();

  Future<Either<NetworkExceptions, DeliveryChoices>> getDeliveryChoices();

  Future<Either<NetworkExceptions, Unit>> selectDeliveryChoice(
    DeliveryChoice choice,
  );

  /// Records which counter the shopper will collect from. Only ever called
  /// after they tap one — nothing calls this on the shopper's behalf, so a
  /// session with no counter chosen stays that way.
  Future<Either<NetworkExceptions, Unit>> selectPickupLocation({
    required String sellerId,
    required String locationId,
  });

  Future<Either<NetworkExceptions, DeliveryPreference>>
  updateDeliveryPreference(DeliveryPreference preference);

  Future<Either<NetworkExceptions, List<PaymentMethod>>> getPaymentMethods();

  Future<Either<NetworkExceptions, PlaceOrderResult>> placeOrder({
    required String? addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  });
}
