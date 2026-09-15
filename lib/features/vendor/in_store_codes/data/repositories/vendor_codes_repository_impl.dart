import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/datasources/vendor_codes_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/entities/code_stats.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/repositories/vendor_codes_repository.dart';
import 'package:uuid/uuid.dart';

class VendorCodesRepositoryImpl implements VendorCodesRepository {
  VendorCodesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorCodesRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  /// Caps a runaway cursor: 40 pages of 50 codes is 2,000 shelf cards.
  static const _maxPages = 40;

  @override
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> createProductTag({
    required String productId,
    required String storeId,
  }) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.createCode(
      kind: CodeKind.productTag,
      productId: productId,
      storeId: storeId,
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> createStoreCode(
    String storeId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.createCode(
      kind: CodeKind.store,
      storeId: storeId,
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, List<StyleMintCodeInfo>>> listStoreCodes(
    String storeId, {
    CodeKind? kind,
  }) => guardedNetworkCall(networkInfo, () async {
    final codes = <StyleMintCodeInfo>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final result = await remoteDataSource.listCodes(
        storeId: storeId,
        kind: kind,
        cursor: cursor,
      );
      codes.addAll(result.codes.map((dto) => dto.toDomain()));
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return codes;
  });

  @override
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> revoke(String code) =>
      guardedNetworkCall(
        networkInfo,
        () async => (await remoteDataSource.revoke(
          code: code,
          idempotencyKey: _uuid.v4(),
        )).toDomain(),
      );

  @override
  Future<Either<NetworkExceptions, CodeStats>> getStats(String code) =>
      guardedNetworkCall(
        networkInfo,
        () async => (await remoteDataSource.getStats(code)).toDomain(),
      );
}
