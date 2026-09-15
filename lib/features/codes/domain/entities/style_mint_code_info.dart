import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';

/// A StyleMint code as its owner sees it (backend `CodeVm`).
class StyleMintCodeInfo {
  const StyleMintCodeInfo({
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

  /// The 8-character code, upper case.
  final String code;
  final CodeKind kind;
  final CodeStatus status;

  /// The public link (`https://…/c/{code}`). Always a StyleMint link,
  /// whatever the server sent.
  final String url;
  final String? productId;
  final String? productName;
  final String? storeId;
  final String? storeName;
  final String? label;
  final int scanCount;
  final DateTime? createdUtc;
  final DateTime? revokedUtc;

  bool get isActive => status == CodeStatus.active;
}
