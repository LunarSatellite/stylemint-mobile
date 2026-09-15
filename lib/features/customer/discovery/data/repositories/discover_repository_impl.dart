import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discover_feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final DiscoverFeedRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, SearchSuggestions>> suggest(
    String query, {
    int limit = 8,
  }) => guardedNetworkCall(
    networkInfo,
    () async =>
        (await remoteDataSource.suggest(query, limit: limit)).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, CatalogPage<HomeCollection>>>
  getCollections({String? cursor, int pageSize = 20}) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getCollections(
      pageSize: pageSize,
      cursor: cursor,
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> markNotInterested(
    NotInterestedTarget target, {
    String? reason,
  }) => guardedNetworkCall(networkInfo, () async {
    await remoteDataSource.markNotInterested(
      targetKind: target.kind.wire,
      targetId: target.id,
      reason: reason,
    );
    return unit;
  });

  @override
  Future<Either<NetworkExceptions, Unit>> undoNotInterested(
    NotInterestedTarget target,
  ) => guardedNetworkCall(networkInfo, () async {
    await remoteDataSource.undoNotInterested(
      targetKind: target.kind.wire,
      targetId: target.id,
    );
    return unit;
  });

  @override
  Future<Either<NetworkExceptions, List<NotInterestedSignal>>>
  getNotInterested() => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getNotInterested()).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> reportReel(
    String reelId,
    ReelReportReason reason,
  ) => guardedNetworkCall(networkInfo, () async {
    await remoteDataSource.reportReel(reelId, reason.code);
    return unit;
  });
}
