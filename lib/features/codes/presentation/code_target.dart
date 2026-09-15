import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/resolved_code.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/in_store_locations.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Where a resolved code opens: an in-app location and, for a person, the
/// profile header to show while their profile loads.
class CodeTarget {
  const CodeTarget(this.location, {this.extra});

  final String location;
  final Object? extra;
}

/// The screen [code] opens, or null when it points at nothing this app can
/// show (a missing id, or a kind this version doesn't know).
CodeTarget? codeTargetFor(ResolvedCode code) {
  switch (code.kind) {
    case CodeKind.productTag:
      final productId = code.productId;
      if (productId == null) return null;
      return CodeTarget(
        inStoreProductLocation(
          productId: productId,
          storeId: code.storeId,
          code: code.code,
          storeName: code.storeName,
          storeCity: code.storeCity,
        ),
      );
    case CodeKind.store:
      final storeId = code.storeId;
      if (storeId == null) return null;
      return CodeTarget(
        inStoreStoreLocation(
          storeId: storeId,
          code: code.code,
          storeName: code.storeName,
          storeCity: code.storeCity,
          vendorName: code.vendorDisplayName,
        ),
      );
    case CodeKind.profile:
      final accountId = code.accountId;
      if (accountId == null) return null;
      return CodeTarget(
        RouteNames.creatorProfile.replaceFirst(':accountId', accountId),
        extra: CreatorProfileArgs(
          accountId: accountId,
          displayName: code.displayName ?? '',
          handle: code.handle ?? '',
          avatarUrl: code.avatarUrl,
        ),
      );
    case CodeKind.unknown:
      return null;
  }
}
