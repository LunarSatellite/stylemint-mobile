import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorEarningsRepository {
  Future<Either<NetworkExceptions, VendorEarningsSummary>> getEarningsSummary();

  Future<Either<NetworkExceptions, VendorEarningsBalance>> getBalance();

  Future<Either<NetworkExceptions, PagedResult<VendorEarningsLedger>>>
  getLedger({int pageSize = 20, String? cursor});

  Future<Either<NetworkExceptions, PagedResult<VendorPayout>>> getPayouts({
    int pageSize = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, VendorPayoutInvoice>> getPayoutInvoice(
    String payoutId,
  );

  Future<Either<NetworkExceptions, Unit>> requestPayout({
    required double amount,
    required int destinationKind,
    required String destinationId,
  });
}
