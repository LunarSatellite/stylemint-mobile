import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';

/// Anonymous reads behind a brand's storefront. Products, reels and
/// collections come from the Catalog listing and the shared storefront
/// repository.
// A repository interface like every other feature's, so it can be faked.
// ignore: one_member_abstracts
abstract interface class BrandStorefrontRepository {
  /// `GET v1/public/brands/{vendorAccountId}`; `notFound` unless approved.
  Future<Either<NetworkExceptions, PublicBrandProfile>> getBrand(
    String vendorAccountId,
  );
}
