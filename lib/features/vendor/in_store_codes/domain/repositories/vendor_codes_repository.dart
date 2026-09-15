import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/entities/code_stats.dart';

abstract interface class VendorCodesRepository {
  /// The active ProductTag code for [productId] in [storeId]; made if there
  /// isn't one (get-or-create).
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> createProductTag({
    required String productId,
    required String storeId,
  });

  /// The store's active Store code; made if there isn't one.
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> createStoreCode(
    String storeId,
  );

  /// Every code in [storeId], optionally of one [kind], all pages.
  Future<Either<NetworkExceptions, List<StyleMintCodeInfo>>> listStoreCodes(
    String storeId, {
    CodeKind? kind,
  });

  /// Switches [code] off. Printed cards and tags with it stop opening.
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> revoke(String code);

  Future<Either<NetworkExceptions, CodeStats>> getStats(String code);
}
