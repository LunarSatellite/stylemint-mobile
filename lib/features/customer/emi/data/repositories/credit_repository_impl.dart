import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/datasources/credit_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/repositories/emi_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/credit_repository.dart';

/// Every call goes through [guardedEmiCall], the same offline check and
/// failure mapping phase 1's EMI, KYC and vendor-terms screens use, so a
/// payment plan fails in the same words as the calculator that led to it.
class CreditRepositoryImpl implements CreditRepository {
  CreditRepositoryImpl({required this.remote, required this.networkInfo});

  final CreditRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;

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
