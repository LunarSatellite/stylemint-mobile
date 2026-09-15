import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/resolved_code.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';

/// Wire shape of backend `ResolvedCodeVm`: `{ code, kind, productId?,
/// storeId?, storeName?, storeCity?, vendorAccountId?, vendorDisplayName?,
/// accountId?, displayName?, handle?, avatarUrl? }`.
class ResolvedCodeDto {
  const ResolvedCodeDto({
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

  factory ResolvedCodeDto.fromJson(Map<String, dynamic> json) =>
      ResolvedCodeDto(
        code: readString(json['code']),
        kind: parseCodeKind(json['kind']),
        productId: readOptionalString(json['productId']),
        storeId: readOptionalString(json['storeId']),
        storeName: readOptionalString(json['storeName']),
        storeCity: readOptionalString(json['storeCity']),
        vendorAccountId: readOptionalString(json['vendorAccountId']),
        vendorDisplayName: readOptionalString(json['vendorDisplayName']),
        accountId: readOptionalString(json['accountId']),
        displayName: readOptionalString(json['displayName']),
        handle: readOptionalString(json['handle']),
        avatarUrl: readOptionalString(json['avatarUrl']),
      );

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
  final String? handle;
  final String? avatarUrl;

  /// [requestedCode] stands in when the body's code is missing or odd.
  ResolvedCode toDomain({required String requestedCode}) {
    final bareHandle = handle?.replaceFirst(RegExp('^@+'), '');
    return ResolvedCode(
      code: StyleMintCodeFormat.normalize(code) ?? requestedCode,
      kind: kind,
      productId: productId,
      storeId: storeId,
      storeName: storeName,
      storeCity: storeCity,
      vendorAccountId: vendorAccountId,
      vendorDisplayName: vendorDisplayName,
      accountId: accountId,
      displayName: displayName,
      handle: bareHandle == null || bareHandle.isEmpty ? null : bareHandle,
      avatarUrl: avatarUrl,
    );
  }
}
