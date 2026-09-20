import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

part 'shipping_address_dto.freezed.dart';
part 'shipping_address_dto.g.dart';

/// Maps `ShippingAddressDto` from `StyleMint.Modules.CartCheckout`
/// (`/v1/addresses`) — the real, checkout-connected address book.
///
/// Since the location-capture contract (backend `3cde0e34`) the response
/// carries `locationNote` and `mapsLink`, and **`addressLine1`, `city`,
/// `state` and `zipCode` are nullable** — a location-captured address has
/// none of them. They are declared `String?` here on purpose: a `@Default('')`
/// on a non-nullable field only fills in a *missing* key, so an explicit
/// `"city": null` would throw in `fromJson` and make every new address
/// invisible to the app.
@freezed
abstract class ShippingAddressDto with _$ShippingAddressDto {
  const factory ShippingAddressDto({
    required String id,
    @Default('') String accountId,
    @Default('Home') String label,
    @Default('') String receiverName,
    @Default('') String receiverPhone,
    @Default('NP') String country,
    @Default('') String locationNote,
    String? mapsLink,
    double? latitude,
    double? longitude,
    double? locationAccuracyMetres,
    int? locationCapturedFrom,
    String? addressLine1,
    String? landmark,
    String? state,
    String? city,
    String? zipCode,
    @Default(false) bool isDefault,
    @Default('') String rowVersion,
    DateTime? createdUtc,
    DateTime? updatedUtc,
  }) = _ShippingAddressDto;

  const ShippingAddressDto._();

  factory ShippingAddressDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressDtoFromJson(json);

  /// Build a write body from a domain address.
  ///
  /// `makeDefault` is only accepted by `POST`, so the caller passes
  /// `includeMakeDefault: false` for a `PATCH`.
  ///
  /// The postal fields are sent as explicit `null`s: the customer's view no
  /// longer collects them, and sending them null on an edit clears the stale
  /// text a legacy address carried. Latitude/longitude/`locationCapturedFrom`
  /// travel together or not at all — omitting all three on an edit makes the
  /// backend **keep** the stored location, which is what a note-only edit
  /// wants.
  ///
  /// The point is sent only when the app can name a first-hand provenance for
  /// it: `1` DeviceGps (this phone measured it) or `2` ManualPin (the shopper
  /// placed it). A point the app merely *received* — the one
  /// `/v1/addresses/resolve-link` returns for a pasted Maps link, or `3`
  /// GeocodedFromAddress on a legacy row — is an inference the server made,
  /// so the link is sent on its own and the server resolves it and stamps
  /// `4` SharedMapsLink itself. Sending such a point with a made-up source
  /// would file someone else's guess as this phone's measurement.
  static Map<String, dynamic> writeBody(
    ShippingAddress address, {
    bool includeMakeDefault = true,
  }) {
    final link = address.mapsLink?.trim();
    return {
      'label': address.label,
      'receiverName': address.receiverName,
      'receiverPhone': address.receiverPhone,
      'country': address.country,
      'locationNote': address.locationNote.trim(),
      'mapsLink': (link == null || link.isEmpty) ? null : link,
      if (address.hasClientCapturedPoint) ...{
        'latitude': address.latitude,
        'longitude': address.longitude,
        // Geolocator reports a double, while the API contract stores whole
        // metres (int?). A decimal makes System.Text.Json reject the body.
        'locationAccuracyMetres': address.locationAccuracyMetres?.round(),
        // Not `?? deviceGps`. There is no sane default here: a point with no
        // client provenance is excluded by `hasClientCapturedPoint` above, so
        // by this line the source is known and is the true one.
        'locationCapturedFrom': address.locationCapturedFrom!.wireValue,
      },
      'addressLine1': null,
      'landmark': null,
      'state': null,
      'city': null,
      'zipCode': null,
      if (includeMakeDefault) 'makeDefault': address.isDefault,
    };
  }

  ShippingAddress toDomain() => ShippingAddress(
    id: id,
    label: label,
    receiverName: receiverName,
    receiverPhone: receiverPhone,
    country: country,
    locationNote: locationNote,
    mapsLink: mapsLink,
    latitude: latitude,
    longitude: longitude,
    locationAccuracyMetres: locationAccuracyMetres,
    locationCapturedFrom: LocationSource.fromWire(locationCapturedFrom),
    addressLine1: addressLine1,
    landmark: landmark,
    city: city,
    state: state,
    zipCode: zipCode,
    isDefault: isDefault,
    rowVersion: rowVersion,
  );
}

/// Maps the `POST /v1/addresses/resolve-link` response.
@freezed
abstract class ResolvedMapsLinkDto with _$ResolvedMapsLinkDto {
  const factory ResolvedMapsLinkDto({
    required double latitude,
    required double longitude,
    @Default('') String sourceUrl,
    @Default(0) int redirectsFollowed,
  }) = _ResolvedMapsLinkDto;

  const ResolvedMapsLinkDto._();

  factory ResolvedMapsLinkDto.fromJson(Map<String, dynamic> json) =>
      _$ResolvedMapsLinkDtoFromJson(json);

  ResolvedMapsLink toDomain() => ResolvedMapsLink(
    latitude: latitude,
    longitude: longitude,
    sourceUrl: sourceUrl,
    redirectsFollowed: redirectsFollowed,
  );
}
