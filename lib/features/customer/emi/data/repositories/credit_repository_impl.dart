import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart'
    show PaymentMethodType, ShippingAddress;
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/credit_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/credit_repository.dart';

/// Every call goes through [guardedEmiCall], the same offline check and
/// failure mapping phase 1's EMI, KYC and vendor-terms screens use, so a
/// payment plan fails in the same words as the calculator that led to it.
///
/// A plan checkout is a checkout: its session calls go through the checkout
/// feature's datasource, the one owner of `/v1/checkout/sessions`, and only
/// the failure mapping is this feature's.
class CreditRepositoryImpl implements CreditRepository {
  CreditRepositoryImpl({
    required this.remote,
    required this.networkInfo,
    required this.checkout,
  });

  final CreditRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;
  final CheckoutRemoteDataSource checkout;

  Future<Either<EmiFailure, T>> _call<T>(Future<T> Function() call) =>
      guardedEmiCall(networkInfo, call);

  @override
  Future<Either<EmiFailure, PlanOptions>> getPlanOptions(String variantId) =>
      _call(() => remote.getPlanOptions(variantId));

  @override
  Future<Either<EmiFailure, CreditProfile>> getProfile() =>
      _call(remote.getProfile);

  @override
  Future<Either<EmiFailure, CreditQuote>> createQuote({
    required String variantId,
    required PlanKind kind,
    required int? downPaymentPercent,
    required int tenureMonths,
  }) => _call(
    () => remote.createQuote(
      variantId: variantId,
      kind: kind,
      downPaymentPercent: downPaymentPercent,
      tenureMonths: tenureMonths,
    ),
  );

  @override
  Future<Either<EmiFailure, CreditAgreement>> apply({
    required String quoteToken,
    required String idempotencyKey,
  }) => _call(
    () => remote.apply(quoteToken: quoteToken, idempotencyKey: idempotencyKey),
  );

  @override
  Future<Either<EmiFailure, List<CreditAgreement>>> listAgreements() =>
      _call(remote.listAgreements);

  @override
  Future<Either<EmiFailure, CreditAgreement>> getAgreement(String id) =>
      _call(() => remote.getAgreement(id));

  @override
  Future<Either<EmiFailure, CreditAgreement>> cancel({
    required String agreementId,
    required String idempotencyKey,
  }) => _call(
    () =>
        remote.cancel(agreementId: agreementId, idempotencyKey: idempotencyKey),
  );

  @override
  Future<Either<EmiFailure, PlanPaymentStart>> startPayment({
    required String agreementId,
    required PaymentPurpose purpose,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  }) => _call(
    () => remote.startPayment(
      agreementId: agreementId,
      purpose: purpose,
      rail: rail,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<EmiFailure, PlanCheckout>> startCheckout(String agreementId) =>
      _call(
        () async => readPlanCheckout(
          await checkout.startPaymentPlanSession(agreementId),
        ),
      );

  @override
  Future<Either<EmiFailure, List<ShippingAddress>>> deliveryAddresses() =>
      _call(
        () async => (await checkout.getShippingAddresses())
            .map((d) => d.toDomain())
            .toList(growable: false),
      );

  @override
  Future<Either<EmiFailure, PlanCheckoutPlaced>> placeCheckout({
    required String sessionId,
    required String addressId,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  }) => _call(() async {
    final placed = await checkout.placePaymentPlanSession(
      sessionId: sessionId,
      addressId: addressId,
      paymentMethod: switch (rail) {
        PlanPaymentRail.card => PaymentMethodType.card,
        PlanPaymentRail.payPal => PaymentMethodType.paypal,
        PlanPaymentRail.eSewa => PaymentMethodType.eSewa,
      },
      idempotencyKey: idempotencyKey,
    );
    return PlanCheckoutPlaced(
      orderNumber: placed.orderNumber,
      redirectUrl: placed.paymentRedirectUrl,
    );
  });

  @override
  Future<Either<EmiFailure, List<CreditAgreement>>> vendorAgreements({
    AgreementStatus? status,
  }) => _call(() => remote.vendorAgreements(status: status));

  @override
  Future<Either<EmiFailure, CreditAgreement>> vendorAgreement(String id) =>
      _call(() => remote.vendorAgreement(id));

  @override
  Future<Either<EmiFailure, CreditAgreement>> vendorReview({
    required String agreementId,
    required bool approve,
    required List<String> reasons,
    required String idempotencyKey,
  }) => _call(
    () => remote.vendorReview(
      agreementId: agreementId,
      approve: approve,
      reasons: reasons,
      idempotencyKey: idempotencyKey,
    ),
  );

  @override
  Future<Either<EmiFailure, VendorCreditProgram>> vendorProgram() =>
      _call(remote.vendorProgram);

  @override
  Future<Either<EmiFailure, VendorCreditProgram>> putVendorProgram(
    VendorCreditProgram program, {
    required String idempotencyKey,
  }) => _call(
    () => remote.putVendorProgram(program, idempotencyKey: idempotencyKey),
  );
}
