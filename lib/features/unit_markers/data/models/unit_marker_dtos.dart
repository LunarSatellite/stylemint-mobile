import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';

/// Wire shape of backend `ProvisionedUnitMarkerVm`:
/// `{ id, reference, secret, productId, productVariantId, provisionedUtc }`.
///
/// `secret` appears on this one shape and nowhere else in the module. It is
/// carried straight into a [ProvisionedUnitMarker] and never copied anywhere
/// that outlives the reveal screen.
class ProvisionedUnitMarkerDto {
  const ProvisionedUnitMarkerDto({
    required this.id,
    required this.reference,
    required this.secret,
    required this.productId,
    required this.productVariantId,
    this.provisionedUtc,
  });

  factory ProvisionedUnitMarkerDto.fromJson(Map<String, dynamic> json) =>
      ProvisionedUnitMarkerDto(
        id: readString(json['id']),
        reference: readString(json['reference']),
        secret: readString(json['secret']),
        productId: readString(json['productId']),
        productVariantId: readString(json['productVariantId']),
        provisionedUtc: readDate(json['provisionedUtc']),
      );

  final String id;
  final String reference;
  final String secret;
  final String productId;
  final String productVariantId;
  final DateTime? provisionedUtc;

  ProvisionedUnitMarker toDomain() => ProvisionedUnitMarker(
    id: id,
    reference: reference,
    secret: secret,
    productId: productId,
    productVariantId: productVariantId,
    provisionedAt: provisionedUtc,
  );

  /// Deliberately omits [secret] — see [ProvisionedUnitMarker.toString].
  @override
  String toString() => 'ProvisionedUnitMarkerDto($reference)';
}

/// Wire shape of backend `UnitMarkerVm`: `{ id, reference, productId,
/// productVariantId, status, provisionedUtc, revokedUtc }`.
///
/// `status` arrives as a **name** (`"Active"` / `"Revoked"`) — the enum
/// carries `[JsonConverter(typeof(JsonStringEnumConverter<…>))]`.
class UnitMarkerDto {
  const UnitMarkerDto({
    required this.id,
    required this.reference,
    required this.productId,
    required this.productVariantId,
    required this.status,
    this.provisionedUtc,
    this.revokedUtc,
  });

  factory UnitMarkerDto.fromJson(Map<String, dynamic> json) => UnitMarkerDto(
    id: readString(json['id']),
    reference: readString(json['reference']),
    productId: readString(json['productId']),
    productVariantId: readString(json['productVariantId']),
    status: UnitMarkerStatus.fromJson(json['status']),
    provisionedUtc: readDate(json['provisionedUtc']),
    revokedUtc: readDate(json['revokedUtc']),
  );

  final String id;
  final String reference;
  final String productId;
  final String productVariantId;
  final UnitMarkerStatus status;
  final DateTime? provisionedUtc;
  final DateTime? revokedUtc;

  UnitMarker toDomain() => UnitMarker(
    id: id,
    reference: reference,
    productId: productId,
    productVariantId: productVariantId,
    status: status,
    provisionedAt: provisionedUtc,
    revokedAt: revokedUtc,
  );
}

/// Wire shape of backend `UnitMarkerBindingVm`.
class UnitMarkerBindingDto {
  const UnitMarkerBindingDto({
    required this.id,
    required this.markerReference,
    required this.orderId,
    required this.subOrderId,
    required this.subOrderLineId,
    required this.boundAtStage,
    this.boundUtc,
    this.correctsBindingId,
    this.supersededUtc,
    this.supersededReason,
  });

  factory UnitMarkerBindingDto.fromJson(Map<String, dynamic> json) =>
      UnitMarkerBindingDto(
        id: readString(json['id']),
        markerReference: readString(json['markerReference']),
        orderId: readString(json['orderId']),
        subOrderId: readString(json['subOrderId']),
        subOrderLineId: readString(json['subOrderLineId']),
        boundAtStage: UnitBindingStage.fromJson(json['boundAtStage']),
        boundUtc: readDate(json['boundUtc']),
        correctsBindingId: readOptionalString(json['correctsBindingId']),
        supersededUtc: readDate(json['supersededUtc']),
        supersededReason: readOptionalString(json['supersededReason']),
      );

  final String id;
  final String markerReference;
  final String orderId;
  final String subOrderId;
  final String subOrderLineId;
  final UnitBindingStage boundAtStage;
  final DateTime? boundUtc;
  final String? correctsBindingId;
  final DateTime? supersededUtc;
  final String? supersededReason;

  UnitMarkerBinding toDomain() => UnitMarkerBinding(
    id: id,
    markerReference: markerReference,
    orderId: orderId,
    subOrderId: subOrderId,
    subOrderLineId: subOrderLineId,
    boundAtStage: boundAtStage,
    boundAt: boundUtc,
    correctsBindingId: correctsBindingId,
    supersededAt: supersededUtc,
    supersededReason: supersededReason,
  );
}

/// Wire shape of backend `UnitMarkerScanResultVm` — the public scan answer.
///
/// The field list here is the field list on the wire, and the wire carries no
/// order, sub-order, line, account, buyer name, address, price or tracking
/// number. There is nothing to drop, because there is nothing to receive.
class UnitMarkerScanResultDto {
  const UnitMarkerScanResultDto({
    required this.unitMarkerId,
    required this.reference,
    required this.status,
    required this.productId,
    required this.isBoundToSale,
    required this.placeKind,
    this.productName,
    this.inServiceSinceUtc,
    this.scannedUtc,
    this.vendorStoreId,
    this.vendorStoreName,
    this.vendorStoreCity,
  });

  factory UnitMarkerScanResultDto.fromJson(Map<String, dynamic> json) =>
      UnitMarkerScanResultDto(
        unitMarkerId: readString(json['unitMarkerId']),
        reference: readString(json['reference']),
        status: UnitMarkerStatus.fromJson(json['status']),
        productId: readString(json['productId']),
        productName: readOptionalString(json['productName']),
        isBoundToSale: readBool(json['isBoundToSale']),
        inServiceSinceUtc: readDate(json['inServiceSinceUtc']),
        scannedUtc: readDate(json['scannedUtc']),
        placeKind: UnitScanPlaceKind.fromJson(json['placeKind']),
        vendorStoreId: readOptionalString(json['vendorStoreId']),
        vendorStoreName: readOptionalString(json['vendorStoreName']),
        vendorStoreCity: readOptionalString(json['vendorStoreCity']),
      );

  final String unitMarkerId;
  final String reference;
  final UnitMarkerStatus status;
  final String productId;
  final String? productName;
  final bool isBoundToSale;
  final DateTime? inServiceSinceUtc;
  final DateTime? scannedUtc;
  final UnitScanPlaceKind placeKind;
  final String? vendorStoreId;
  final String? vendorStoreName;
  final String? vendorStoreCity;

  UnitMarkerScanResult toDomain() => UnitMarkerScanResult(
    unitMarkerId: unitMarkerId,
    reference: reference,
    status: status,
    productId: productId,
    productName: productName,
    isBoundToSale: isBoundToSale,
    inServiceSince: inServiceSinceUtc,
    scannedAt: scannedUtc,
    placeKind: placeKind,
    vendorStoreId: vendorStoreId,
    vendorStoreName: vendorStoreName,
    vendorStoreCity: vendorStoreCity,
  );
}

/// Wire shape of backend `UnitMarkerScanVm` — one recorded reading, for the
/// marker's own seller.
class UnitMarkerScanDto {
  const UnitMarkerScanDto({
    required this.id,
    required this.via,
    required this.placeKind,
    this.scannedUtc,
    this.vendorStoreId,
    this.vendorStoreName,
  });

  factory UnitMarkerScanDto.fromJson(Map<String, dynamic> json) =>
      UnitMarkerScanDto(
        id: readString(json['id']),
        scannedUtc: readDate(json['scannedUtc']),
        via: readString(json['via']),
        placeKind: UnitScanPlaceKind.fromJson(json['placeKind']),
        vendorStoreId: readOptionalString(json['vendorStoreId']),
        vendorStoreName: readOptionalString(json['vendorStoreName']),
      );

  final String id;
  final DateTime? scannedUtc;
  final String via;
  final UnitScanPlaceKind placeKind;
  final String? vendorStoreId;
  final String? vendorStoreName;

  UnitMarkerScan toDomain() => UnitMarkerScan(
    id: id,
    scannedAt: scannedUtc,
    via: via,
    placeKind: placeKind,
    vendorStoreId: vendorStoreId,
    vendorStoreName: vendorStoreName,
  );
}
