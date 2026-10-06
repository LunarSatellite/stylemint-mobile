/// Geohash encoding, base-32, as the delivery backend expects it.
///
/// Every courier call that records where something happened takes a
/// `geohashAtEvent`, and the routing engine matches couriers and travel plans
/// on geohash prefixes. The backend validates the alphabet
/// (`^[0-9a-z]+$`, the base-32 geohash set) and a length of 5 to 16, so this
/// has to produce exactly that — a geohash from a different alphabet variant
/// passes a length check and then matches nothing.
///
/// Written here rather than taken from a package because it is thirty lines of
/// a fixed, well-specified algorithm, and the alternative is a dependency in
/// the signing path whose alphabet we would have to verify anyway.
library;

/// The standard geohash alphabet: base-32 with a, i, l and o removed so the
/// characters cannot be confused when read aloud or typed.
const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Precision used for a custody event.
///
/// Nine characters is roughly a 5-metre cell — precise enough to say which
/// doorway a parcel changed hands at, which is the point of recording it, and
/// no more precise than a phone's GPS can honestly claim. Going finer would
/// encode noise as evidence.
const int custodyEventPrecision = 9;

/// Precision used for a courier's home area and for travel-plan endpoints.
///
/// Five characters is a ~5 km cell, which is the granularity the router's
/// prefix matching works at (`HomeGeohashPrefix5`, `OriginPrefix5`). Declaring
/// a home location to street precision would be handing over where someone
/// lives for no matching benefit.
const int serviceAreaPrecision = 5;

/// Encodes a latitude/longitude to [precision] geohash characters.
///
/// Clamps rather than throws on out-of-range input: this sits between a GPS
/// read and a network call made at a doorstep, and a courier who cannot record
/// a handoff because a sensor returned 90.0000001 is worse served than one
/// whose geohash is a metre off.
String encodeGeohash(
  double latitude,
  double longitude, {
  int precision = custodyEventPrecision,
}) {
  final targetLength = precision < 1 ? 1 : (precision > 16 ? 16 : precision);

  var latMin = -90.0;
  var latMax = 90.0;
  var lonMin = -180.0;
  var lonMax = 180.0;

  final lat = latitude.clamp(-90.0, 90.0).toDouble();
  final lon = longitude.clamp(-180.0, 180.0).toDouble();

  final out = StringBuffer();
  var isEven = true; // Longitude is bisected first, by the specification.
  var bit = 0;
  var charIndex = 0;

  while (out.length < targetLength) {
    if (isEven) {
      final mid = (lonMin + lonMax) / 2;
      if (lon >= mid) {
        charIndex = (charIndex << 1) | 1;
        lonMin = mid;
      } else {
        charIndex <<= 1;
        lonMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (lat >= mid) {
        charIndex = (charIndex << 1) | 1;
        latMin = mid;
      } else {
        charIndex <<= 1;
        latMax = mid;
      }
    }

    isEven = !isEven;

    // Five bits to a base-32 character.
    if (bit < 4) {
      bit++;
    } else {
      out.write(_base32[charIndex]);
      bit = 0;
      charIndex = 0;
    }
  }

  return out.toString();
}

/// A decoded geohash: the centre of the cell, and how big the cell is.
///
/// The error bounds travel with the point because a geohash is an area, not a
/// position, and a map that draws a 5-character geohash as a pin is claiming
/// 5 km of precision it does not have. A caller that knows the half-height and
/// half-width can draw a circle instead, or decline to draw a pin at all.
class GeohashArea {
  const GeohashArea({
    required this.latitude,
    required this.longitude,
    required this.latitudeError,
    required this.longitudeError,
  });

  /// Centre of the cell.
  final double latitude;
  final double longitude;

  /// Half the cell's height and width, in degrees.
  final double latitudeError;
  final double longitudeError;
}

/// Decodes a geohash back to the centre of the cell it names.
///
/// The counterpart of [encodeGeohash], and needed because the delivery backend
/// stores hop endpoints as geohashes and nothing else: `FromGeohash` and
/// `ToGeohash` on a hop are all the courier app has to put a pickup and a
/// dropoff on a map.
///
/// Returns null for anything that is not a geohash — an empty string, or a
/// character outside the alphabet. A caller gets to decide what to do with a
/// hop it cannot place, and that is better than a pin in the Atlantic, which
/// is where `(0, 0)` would put it.
GeohashArea? decodeGeohash(String geohash) {
  if (geohash.isEmpty) return null;

  var latMin = -90.0;
  var latMax = 90.0;
  var lonMin = -180.0;
  var lonMax = 180.0;

  var isEven = true; // Longitude first, matching the encoder.

  for (final char in geohash.toLowerCase().split('')) {
    final charIndex = _base32.indexOf(char);
    if (charIndex < 0) return null;

    // Most significant bit first, five bits to a character.
    for (var mask = 16; mask > 0; mask >>= 1) {
      final isHigh = (charIndex & mask) != 0;
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (isHigh) {
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (isHigh) {
          latMin = mid;
        } else {
          latMax = mid;
        }
      }
      isEven = !isEven;
    }
  }

  return GeohashArea(
    latitude: (latMin + latMax) / 2,
    longitude: (lonMin + lonMax) / 2,
    latitudeError: (latMax - latMin) / 2,
    longitudeError: (lonMax - lonMin) / 2,
  );
}
