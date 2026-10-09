import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

abstract class VendorEmiRepository {
  Future<Either<EmiFailure, VendorEmiTerms>> getTerms(String productId);

  Future<Either<EmiFailure, VendorEmiTerms>> saveTerms(
    String productId, {
    required bool enabled,
    required int minDownPaymentPercent,
    required List<int> tenures,
  });

  Future<Either<EmiFailure, List<VendorEmiTerms>>> getEmiProducts();

  Future<Either<EmiFailure, VendorEmiSettings>> getSettings();

  Future<Either<EmiFailure, VendorEmiSettings>> saveSettings(
    Money? exposureLimit,
  );
}
