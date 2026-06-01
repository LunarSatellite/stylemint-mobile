import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorEarningsRepository {
  Future<Either<NetworkExceptions, VendorEarningsSummary>> getEarningsSummary();

  Future<Either<NetworkExceptions, PagedResult<VendorEarningsLedger>>> getLedger({
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, List<VendorPayoutMethod>>> getPayoutMethods();

  Future<Either<NetworkExceptions, VendorPayoutMethod>> addPayoutMethod({
    required VendorPayoutMethodType type,
    required String label,
    required String accountInfo,
  });

  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required Money amount,
    required String methodId,
  });
}
