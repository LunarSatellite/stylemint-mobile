import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/brand.dart';

/// Read-only catalog of approved vendors a creator can partner with.
abstract interface class BrandsRepository {
  Future<Either<NetworkExceptions, List<Brand>>> listBrands();

  Future<Either<NetworkExceptions, List<Brand>>> listRecommendedBrands();
}
