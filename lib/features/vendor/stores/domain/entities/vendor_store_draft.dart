import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';

/// What a vendor enters to create or edit a store (backend
/// `CreateVendorStoreVm` / `UpdateVendorStoreVm`).
class VendorStoreDraft {
  const VendorStoreDraft({
    required this.name,
    required this.addressLine,
    required this.city,
    this.latitude,
    this.longitude,
    this.phone,
  });

  static const int nameMin = 2;
  static const int nameMax = 80;
  static const int addressMax = 160;
  static const int cityMax = 80;
  static const int phoneMax = 20;

  final String name;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? phone;

  /// Trimmed, with a blank phone as null.
  VendorStoreDraft normalized() {
    final trimmedPhone = phone?.trim() ?? '';
    return VendorStoreDraft(
      name: name.trim(),
      addressLine: addressLine.trim(),
      city: city.trim(),
      latitude: latitude,
      longitude: longitude,
      phone: trimmedPhone.isEmpty ? null : trimmedPhone,
    );
  }

  /// Checks the contract's rules: name 2–80, address 1–160, city 1–80,
  /// latitude −90..90, longitude −180..180, phone up to 20 characters.
  VendorStoreFormErrors validate() {
    final d = normalized();
    final lat = d.latitude;
    final lng = d.longitude;
    return VendorStoreFormErrors(
      name: d.name.length < nameMin
          ? 'Enter a store name of at least $nameMin characters.'
          : d.name.length > nameMax
          ? 'Keep the store name to $nameMax characters or fewer.'
          : null,
      addressLine: d.addressLine.isEmpty
          ? 'Enter the street address.'
          : d.addressLine.length > addressMax
          ? 'Keep the address to $addressMax characters or fewer.'
          : null,
      city: d.city.isEmpty
          ? 'Enter the city.'
          : d.city.length > cityMax
          ? 'Keep the city to $cityMax characters or fewer.'
          : null,
      latitude: lat != null && (lat < -90 || lat > 90)
          ? 'Latitude must be between -90 and 90.'
          : null,
      longitude: lng != null && (lng < -180 || lng > 180)
          ? 'Longitude must be between -180 and 180.'
          : null,
      phone: (d.phone?.length ?? 0) > phoneMax
          ? 'Keep the phone number to $phoneMax characters or fewer.'
          : null,
    );
  }
}

/// Messages to show under the store form's fields; [general] for anything
/// that isn't about one field.
class VendorStoreFormErrors {
  const VendorStoreFormErrors({
    this.name,
    this.addressLine,
    this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.general,
  });

  /// Places the backend's field errors (RFC 7807 `errors[]`, or a top-level
  /// `field`) under the matching inputs; everything else is [general].
  factory VendorStoreFormErrors.fromFailure(NetworkExceptions failure) {
    final fields = <String, String>{};
    String? general;
    failure.maybeWhen<void>(
      validation: (code, message, field, errors) {
        if (errors.isNotEmpty) {
          for (final error in errors) {
            final key = _fieldKey(error.field);
            final text = error.message.isNotEmpty ? error.message : error.code;
            if (key == null) {
              general ??= text;
            } else {
              fields.putIfAbsent(key, () => text);
            }
          }
          return;
        }
        final key = _fieldKey(field);
        final text = NetworkExceptions.getMessage(failure);
        if (key == null) {
          general = text;
        } else {
          fields[key] = text;
        }
      },
      orElse: () => general = NetworkExceptions.getMessage(failure),
    );
    return VendorStoreFormErrors(
      name: fields['name'],
      addressLine: fields['addressline'],
      city: fields['city'],
      latitude: fields['latitude'],
      longitude: fields['longitude'],
      phone: fields['phone'],
      general: general,
    );
  }

  final String? name;
  final String? addressLine;
  final String? city;
  final String? latitude;
  final String? longitude;
  final String? phone;
  final String? general;

  bool get isEmpty => [
    name,
    addressLine,
    city,
    latitude,
    longitude,
    phone,
    general,
  ].every((message) => message == null);

  VendorStoreFormErrors copyWith({String? latitude, String? longitude}) =>
      VendorStoreFormErrors(
        name: name,
        addressLine: addressLine,
        city: city,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        phone: phone,
        general: general,
      );

  static const _fields = {
    'name',
    'addressline',
    'city',
    'latitude',
    'longitude',
    'phone',
  };

  static String? _fieldKey(String? field) {
    final key = (field ?? '').trim().toLowerCase();
    return _fields.contains(key) ? key : null;
  }
}
