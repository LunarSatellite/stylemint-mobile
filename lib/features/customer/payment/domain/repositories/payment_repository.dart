import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';

abstract interface class PaymentRepository {
  Future<Either<NetworkExceptions, List<PaymentMethod>>> getPaymentMethods();

  Future<Either<NetworkExceptions, PaymentMethod>> addCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String cardholderName,
  });

  Future<Either<NetworkExceptions, Unit>> deletePaymentMethod(String id);

  Future<Either<NetworkExceptions, Unit>> setDefault(String id);
}
