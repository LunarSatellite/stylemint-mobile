import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart'
    show ShippingAddress;
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';

/// Payment plans: the menu, the buyer's quotes, agreements and payments, and
/// the vendor's side of the same agreements.
abstract class CreditRepository {
  Future<Either<EmiFailure, PlanOptions>> getPlanOptions(String variantId);

  Future<Either<EmiFailure, CreditProfile>> getProfile();

  Future<Either<EmiFailure, CreditQuote>> createQuote({
    required String variantId,
    required PlanKind kind,
    required int? downPaymentPercent,
    required int tenureMonths,
  });

  Future<Either<EmiFailure, CreditAgreement>> apply({
    required String quoteToken,
    required String idempotencyKey,
  });

  Future<Either<EmiFailure, List<CreditAgreement>>> listAgreements();

  Future<Either<EmiFailure, CreditAgreement>> getAgreement(String id);

  Future<Either<EmiFailure, CreditAgreement>> cancel({
    required String agreementId,
    required String idempotencyKey,
  });

  Future<Either<EmiFailure, PlanPaymentStart>> startPayment({
    required String agreementId,
    required PaymentPurpose purpose,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  });

  /// Checks out an approved plan: its one item at its price, the cart untouched.
  Future<Either<EmiFailure, PlanCheckout>> startCheckout(String agreementId);

  /// The buyer's delivery addresses, for a plan checkout.
  Future<Either<EmiFailure, List<ShippingAddress>>> deliveryAddresses();

  /// Places a plan checkout: the order the plan pays for, and the plan's first
  /// payment to make.
  Future<Either<EmiFailure, PlanCheckoutPlaced>> placeCheckout({
    required String sessionId,
    required String addressId,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  });

  Future<Either<EmiFailure, List<CreditAgreement>>> vendorAgreements({
    AgreementStatus? status,
  });

  Future<Either<EmiFailure, CreditAgreement>> vendorAgreement(String id);

  Future<Either<EmiFailure, CreditAgreement>> vendorReview({
    required String agreementId,
    required bool approve,
    required List<String> reasons,
    required String idempotencyKey,
  });

  Future<Either<EmiFailure, VendorCreditProgram>> vendorProgram();

  Future<Either<EmiFailure, VendorCreditProgram>> putVendorProgram(
    VendorCreditProgram program, {
    required String idempotencyKey,
  });
}
