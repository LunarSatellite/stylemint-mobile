import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/data/datasources/brand_storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/repositories/brand_storefront_repository.dart';

class BrandStorefrontRepositoryImpl implements BrandStorefrontRepository {
  BrandStorefrontRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final BrandStorefrontRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, PublicBrandProfile>> getBrand(
    String vendorAccountId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getBrand(
      vendorAccountId,
    )).toDomain(vendorAccountId),
  );
}
