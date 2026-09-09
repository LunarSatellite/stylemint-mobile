import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/data/datasources/vendor_profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/entities/vendor_profile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/repositories/vendor_profile_repository.dart';

class VendorProfileRepositoryImpl implements VendorProfileRepository {
  VendorProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorProfileRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<NetworkEither<VendorProfile>> getMyProfile(String accountId) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getMyProfile(accountId);
      return right(dto.toDomain());
    } on DioException catch (error) {
      return left(NetworkExceptions.server(error.message ?? 'Server error'));
    } on NetworkExceptions catch (error) {
      return left(error);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
