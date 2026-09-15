import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/mall_home_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';
import 'package:uuid/uuid.dart';

class MallHomeRepositoryImpl implements MallHomeRepository {
  MallHomeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final MallHomeRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, MallHome>> getHome() => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getHome()).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> recordRecentlyViewed(
    String productId,
  ) => guardedNetworkCall(networkInfo, () async {
    await remoteDataSource.recordRecentlyViewed(
      productId,
      idempotencyKey: _uuid.v4(),
    );
    return unit;
  });
}
