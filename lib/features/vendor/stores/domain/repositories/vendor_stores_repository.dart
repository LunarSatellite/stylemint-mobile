import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';

abstract interface class VendorStoresRepository {
  /// Every store of the signed-in vendor, all pages.
  Future<Either<NetworkExceptions, List<VendorStore>>> getStores();

  Future<Either<NetworkExceptions, VendorStore>> createStore(
    VendorStoreDraft draft,
  );

  Future<Either<NetworkExceptions, VendorStore>> updateStore(
    String storeId,
    VendorStoreDraft draft,
  );

  /// Archives the store; its codes can't be opened any more.
  Future<Either<NetworkExceptions, Unit>> archiveStore(String storeId);
}
