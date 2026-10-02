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
