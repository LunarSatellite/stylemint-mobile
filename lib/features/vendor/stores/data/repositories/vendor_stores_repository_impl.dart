import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/datasources/vendor_stores_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/repositories/vendor_stores_repository.dart';
import 'package:uuid/uuid.dart';

class VendorStoresRepositoryImpl implements VendorStoresRepository {
  VendorStoresRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorStoresRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  /// Vendors have a handful of stores; this caps a runaway cursor.
  static const _maxPages = 20;

  @override
  Future<Either<NetworkExceptions, List<VendorStore>>> getStores() =>
      guardedNetworkCall(networkInfo, () async {
        final stores = <VendorStore>[];
        String? cursor;
        for (var page = 0; page < _maxPages; page++) {
          final result = await remoteDataSource.getStores(cursor: cursor);
          stores.addAll(result.stores.map((dto) => dto.toDomain()));
          cursor = result.nextCursor;
          if (cursor == null) break;
        }
        return stores;
      });

  @override
  Future<Either<NetworkExceptions, VendorStore>> createStore(
    VendorStoreDraft draft,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.createStore(
      draft: draft,
      // A fresh key per Save tap, so a retry after a failure is a new try.
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, VendorStore>> updateStore(
    String storeId,
    VendorStoreDraft draft,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.updateStore(
      storeId: storeId,
      draft: draft,
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> archiveStore(String storeId) =>
      guardedNetworkCall(networkInfo, () async {
        await remoteDataSource.archiveStore(
          storeId: storeId,
          idempotencyKey: _uuid.v4(),
        );
        return unit;
      });
}
