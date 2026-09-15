import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';

/// What a scanned code opens (backend `ResolvedCodeVm`). Product and store
/// fields are set for [CodeKind.productTag] and [CodeKind.store]; the
/// person's fields for [CodeKind.profile].
class ResolvedCode {
  const ResolvedCode({
    required this.code,
    required this.kind,
    this.productId,
    this.storeId,
    this.storeName,
    this.storeCity,
    this.vendorAccountId,
    this.vendorDisplayName,
    this.accountId,
    this.displayName,
    this.handle,
    this.avatarUrl,
  });

  final String code;
  final CodeKind kind;
  final String? productId;
  final String? storeId;
  final String? storeName;
  final String? storeCity;
  final String? vendorAccountId;
  final String? vendorDisplayName;
  final String? accountId;
  final String? displayName;

  /// The person's @handle without the `@`.
  final String? handle;
  final String? avatarUrl;
}
