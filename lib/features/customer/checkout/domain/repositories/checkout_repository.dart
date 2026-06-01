import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

abstract interface class CheckoutRepository {
  Future<Either<NetworkExceptions, CheckoutSummary>> getCheckoutSummary();

  Future<Either<NetworkExceptions, List<ShippingAddress>>> getShippingAddresses();

  Future<Either<NetworkExceptions, List<PaymentMethod>>> getPaymentMethods();

  Future<Either<NetworkExceptions, String>> placeOrder({
    required String addressId,
    required String paymentMethodId,
    required String idempotencyKey,
  });
}
