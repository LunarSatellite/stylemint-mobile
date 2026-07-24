import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

abstract interface class CheckoutRepository {
  Future<Either<NetworkExceptions, CheckoutSummary>> getCheckoutSummary();

  Future<Either<NetworkExceptions, List<ShippingAddress>>> getShippingAddresses();

  Future<Either<NetworkExceptions, ShippingAddress>> addAddress({
    required String label,
    required String receiverName,
    required String receiverPhone,
    required String addressLine1,
    String? landmark,
    required String country,
    required String state,
    required String city,
    required String zipCode,
    bool makeDefault,
    required String idempotencyKey,
  });

  Future<Either<NetworkExceptions, List<PaymentMethod>>> getPaymentMethods();

  Future<Either<NetworkExceptions, String>> placeOrder({
    required String addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  });
}
