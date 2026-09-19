import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Wire shape of the backend `PickupLocationVm`: `{ locationId, kind, name,
/// addressLine, city, latitude?, longitude?, openingHours?, lastConfirmedUtc?,
/// confirmationState, confirmationNote, stockAvailability,
/// stockAvailabilityNote }`.
///
/// `stockAvailability` is the string `"Unknown"` and is the only value the
/// backend can send. It is not a count and it is not zero.
class PickupLocationDto {
  const PickupLocationDto({
    required this.locationId,
    required this.name,
    required this.addressLine,
    required this.city,
    required this.confirmationState,
    required this.confirmationNote,
    required this.stockAvailability,
    required this.stockAvailabilityNote,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.lastConfirmedUtc,
  });

  factory PickupLocationDto.fromJson(Map<String, dynamic> json) =>
      PickupLocationDto(
        locationId: readString(json['locationId']),
        name: readString(json['name']),
        addressLine: readString(json['addressLine']),
        city: readString(json['city']),
        latitude: readOptionalDouble(json['latitude']),
        longitude: readOptionalDouble(json['longitude']),
        openingHours: readOptionalString(json['openingHours']),
        lastConfirmedUtc: readDate(json['lastConfirmedUtc']),
        confirmationState: parseLocationConfirmationState(
          json['confirmationState'],
        ),
        confirmationNote: readString(json['confirmationNote']),
        stockAvailability: parsePickupStockAvailability(
          json['stockAvailability'],
        ),
        stockAvailabilityNote: readString(json['stockAvailabilityNote']),
      );

  final String locationId;
  final String name;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? openingHours;
  final DateTime? lastConfirmedUtc;
  final LocationConfirmationState confirmationState;
  final String confirmationNote;
  final PickupStockAvailability stockAvailability;
  final String stockAvailabilityNote;

  PickupLocation toDomain() => PickupLocation(
    locationId: locationId,
    name: name,
    addressLine: addressLine,
    city: city,
    latitude: latitude,
    longitude: longitude,
    openingHours: openingHours,
    lastConfirmedUtc: lastConfirmedUtc,
    confirmationState: confirmationState,
    confirmationNote: confirmationNote,
    stockAvailability: stockAvailability,
    stockAvailabilityNote: stockAvailabilityNote,
  );
}

/// Wire shape of the backend `EndlessAisleVm`.
class EndlessAisleDto {
  const EndlessAisleDto({
    required this.code,
    required this.kind,
    required this.vendorAccountId,
    required this.canOrderFromAnywhere,
    required this.reachNote,
    required this.inStoreAvailability,
    required this.inStoreAvailabilityNote,
    required this.pickupOffered,
    required this.pickupNote,
    required this.pickupLocations,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.productPriceAmount,
    this.productPriceCurrency,
    this.scannedAtLocationId,
    this.scannedAtLocationName,
    this.vendorDisplayName,
  });

  factory EndlessAisleDto.fromJson(Map<String, dynamic> json) {
    final locations = json['pickupLocations'];
    return EndlessAisleDto(
      code: readString(json['code']),
      kind: parseCodeKind(json['kind']),
      productId: readOptionalString(json['productId']),
      productName: readOptionalString(json['productName']),
      productImageUrl: readOptionalString(json['productImageUrl']),
      productPriceAmount: readOptionalDouble(json['productPriceAmount']),
      productPriceCurrency: readOptionalString(json['productPriceCurrency']),
      scannedAtLocationId: readOptionalString(json['scannedAtLocationId']),
      scannedAtLocationName: readOptionalString(json['scannedAtLocationName']),
      vendorAccountId: readString(json['vendorAccountId']),
      vendorDisplayName: readOptionalString(json['vendorDisplayName']),
      canOrderFromAnywhere: readBool(json['canOrderFromAnywhere']),
      reachNote: readString(json['reachNote']),
      inStoreAvailability: parsePickupStockAvailability(
        json['inStoreAvailability'],
      ),
      inStoreAvailabilityNote: readString(json['inStoreAvailabilityNote']),
      pickupOffered: readBool(json['pickupOffered']),
      pickupNote: readString(json['pickupNote']),
      pickupLocations: locations is! List
          ? const <PickupLocationDto>[]
          : locations
                .whereType<Map<String, dynamic>>()
                .map(PickupLocationDto.fromJson)
                .toList(growable: false),
    );
  }

  final String code;
  final CodeKind kind;
  final String? productId;
  final String? productName;
  final String? productImageUrl;
  final double? productPriceAmount;
  final String? productPriceCurrency;
  final String? scannedAtLocationId;
  final String? scannedAtLocationName;
  final String vendorAccountId;
  final String? vendorDisplayName;
  final bool canOrderFromAnywhere;
  final String reachNote;
  final PickupStockAvailability inStoreAvailability;
  final String inStoreAvailabilityNote;
  final bool pickupOffered;
  final String pickupNote;
  final List<PickupLocationDto> pickupLocations;

  /// A price only exists when the backend sent both halves of one. Half a
  /// price is no price — never a zero, never a bare number in an assumed
  /// currency.
  Money? get productPrice {
    final amount = productPriceAmount;
    final currency = productPriceCurrency;
    if (amount == null || currency == null || currency.isEmpty) return null;
    return Money(amount: amount, currency: currency);
  }

  EndlessAisle toDomain() => EndlessAisle(
    code: code,
    kind: kind,
    productId: productId,
    productName: productName,
    productImageUrl: productImageUrl,
    productPrice: productPrice,
    scannedAtLocationId: scannedAtLocationId,
    scannedAtLocationName: scannedAtLocationName,
    vendorAccountId: vendorAccountId,
    vendorDisplayName: vendorDisplayName,
    canOrderFromAnywhere: canOrderFromAnywhere,
    reachNote: reachNote,
    inStoreAvailability: inStoreAvailability,
    inStoreAvailabilityNote: inStoreAvailabilityNote,
    pickupOffered: pickupOffered,
    pickupNote: pickupNote,
    pickupLocations: pickupLocations
        .map((location) => location.toDomain())
        .toList(growable: false),
  );
}

/// The backend sends the word `"Unknown"`, and that is the only value its
/// enum has. Anything else is [PickupStockAvailability.unrecognised], which
/// this app draws identically — an unreadable answer is still not an answer,
/// and neither is ever drawn as a quantity.
PickupStockAvailability parsePickupStockAvailability(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'unknown' => PickupStockAvailability.unknown,
      _ => PickupStockAvailability.unrecognised,
    };

/// `"NeverConfirmed"`, `"Confirmed"` or `"Stale"` on the wire; integers are
/// accepted too because the backend's converter takes them on input.
LocationConfirmationState parseLocationConfirmationState(Object? raw) =>
    switch (normalizeWireEnum(raw)) {
      1 || 'neverconfirmed' => LocationConfirmationState.neverConfirmed,
      2 || 'confirmed' => LocationConfirmationState.confirmed,
      3 || 'stale' => LocationConfirmationState.stale,
      _ => LocationConfirmationState.unrecognised,
    };
