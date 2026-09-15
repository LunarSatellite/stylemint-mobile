import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/code_links.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';

/// Wire shape of backend `CodeVm`: `{ code, kind, status, url, productId?,
/// productName?, storeId?, storeName?, label?, scanCount, createdUtc,
/// revokedUtc? }`. Enums arrive as names (`ProductTag`, `Active`); their
/// numbers are accepted too.
class CodeDto {
  const CodeDto({
    required this.code,
    required this.kind,
    required this.status,
    required this.url,
    this.productId,
    this.productName,
    this.storeId,
    this.storeName,
    this.label,
    this.scanCount = 0,
    this.createdUtc,
    this.revokedUtc,
  });

  factory CodeDto.fromJson(Map<String, dynamic> json) => CodeDto(
    code: readString(json['code']).toUpperCase(),
    kind: parseCodeKind(json['kind']),
    status: parseCodeStatus(json['status']),
    url: readString(json['url']),
    productId: readOptionalString(json['productId']),
    productName: readOptionalString(json['productName']),
    storeId: readOptionalString(json['storeId']),
    storeName: readOptionalString(json['storeName']),
    label: readOptionalString(json['label']),
    scanCount: readInt(json['scanCount']),
    createdUtc: readDate(json['createdUtc']),
    revokedUtc: readDate(json['revokedUtc']),
  );

  /// The `items` of a `PagedResult<CodeVm>`. Entries without a valid code
  /// can't be shown or printed, so they are dropped.
  static List<CodeDto> listFromPage(Object? raw) => readPagedItems(raw)
      .map(CodeDto.fromJson)
      .where((dto) => dto.isValid)
      .toList(growable: false);

  final String code;
  final CodeKind kind;
  final CodeStatus status;
  final String url;
  final String? productId;
  final String? productName;
  final String? storeId;
  final String? storeName;
  final String? label;
  final int scanCount;
  final DateTime? createdUtc;
  final DateTime? revokedUtc;

  bool get isValid => StyleMintCodeFormat.normalize(code) != null;

  /// Throws [FormatException] when [code] isn't a StyleMint code. The link
  /// is always a StyleMint link (see [StyleMintCodeLinks.publicUrl]).
  StyleMintCodeInfo toDomain() {
    final normalized = StyleMintCodeFormat.normalize(code);
    if (normalized == null) {
      throw const FormatException('Not a StyleMint code');
    }
    return StyleMintCodeInfo(
      code: normalized,
      kind: kind,
      status: status,
      url: StyleMintCodeLinks.publicUrl(normalized, serverUrl: url),
      productId: productId,
      productName: productName,
      storeId: storeId,
      storeName: storeName,
      label: label,
      scanCount: scanCount,
      createdUtc: createdUtc,
      revokedUtc: revokedUtc,
    );
  }
}

/// Backend `CodeKind`: ProductTag=1, Store=2, Profile=3. Reserved and future
/// kinds read as [CodeKind.unknown].
CodeKind parseCodeKind(Object? raw) => switch (normalizeWireEnum(raw)) {
  1 || 'producttag' => CodeKind.productTag,
  2 || 'store' => CodeKind.store,
  3 || 'profile' => CodeKind.profile,
  _ => CodeKind.unknown,
};

/// Backend `CodeStatus`: Active=1, Revoked=2.
CodeStatus parseCodeStatus(Object? raw) => switch (normalizeWireEnum(raw)) {
  1 || 'active' => CodeStatus.active,
  2 || 'revoked' => CodeStatus.revoked,
  _ => CodeStatus.unknown,
};
