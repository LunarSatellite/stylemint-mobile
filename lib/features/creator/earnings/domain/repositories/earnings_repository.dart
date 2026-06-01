import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

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

  Future<Either<NetworkExceptions, Unit>> addPayoutMethod({
    required PayoutMethodType type,
    required String label,
    required Map<String, String> details,
  });
}
