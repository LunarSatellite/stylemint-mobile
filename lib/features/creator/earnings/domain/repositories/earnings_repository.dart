import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

abstract interface class EarningsRepository {
  Future<Either<NetworkExceptions, EarningsSummary>> getSummary();

  Future<Either<NetworkExceptions, List<EarningsLedgerEntry>>> getLedger({
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, List<PayoutMethod>>> getPayoutMethods();

  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required Money amount,
    required String payoutMethodId,
  });

  Future<Either<NetworkExceptions, Unit>> addBankPayoutMethod({
    required int kind,
    required String label,
    String? maskedAccountNumber,
    String? beneficiaryName,
    String? processorReference,
  });

  Future<Either<NetworkExceptions, Unit>> addExternalWalletPayoutMethod({
    required int kind,
    required String label,
    String? externalIdentifier,
    String? processorReference,
  });

  Future<Either<NetworkExceptions, Unit>> removePayoutMethod(String methodId);

  Future<Either<NetworkExceptions, List<PayoutRecord>>> getPayouts({
    int pageSize = 25,
    String? cursor,
  });

  Future<Either<NetworkExceptions, PayoutInvoice>> getPayoutInvoice(
    String payoutId,
  );

  Future<Either<NetworkExceptions, Unit>> cancelPayout(String payoutId);
}
