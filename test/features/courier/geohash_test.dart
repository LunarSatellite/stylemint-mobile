import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/geohash.dart';

/// The delivery backend stores hop endpoints as geohashes and nothing else —
/// `FromGeohash` and `ToGeohash` are all the courier app has to put a pickup
/// and a dropoff on a map — so the decoder has to be right, not approximately
/// right. These are the published reference values for the algorithm.
void main() {
  group('decodeGeohash', () {
    test('matches the reference value to full precision', () {
      final area = decodeGeohash('u4pruydqqvj')!;
      expect(area.latitude, closeTo(57.649111, 0.00001));
      expect(area.longitude, closeTo(10.407440, 0.00001));
    });

    test('a five-character hash lands in the right cell', () {
      final area = decodeGeohash('ezs42')!;
      expect(area.latitude, closeTo(42.605, 0.03));
      expect(area.longitude, closeTo(-5.603, 0.03));
    });

    test('is case-insensitive, as the alphabet has no uppercase', () {
      final lower = decodeGeohash('ezs42')!;
      final upper = decodeGeohash('EZS42')!;
      expect(upper.latitude, lower.latitude);
      expect(upper.longitude, lower.longitude);
    });

    test('reports the cell size, because a geohash is an area', () {
      // Five characters is a ~5 km cell. A map that draws this as a pin is
      // claiming precision it does not have, so the bounds travel with it.
      final coarse = decodeGeohash('ezs42')!;
      expect(coarse.latitudeError, closeTo(0.022, 0.001));

      // Eleven characters is centimetres.
      final fine = decodeGeohash('u4pruydqqvj')!;
      expect(fine.latitudeError, lessThan(0.00001));
      expect(fine.latitudeError, lessThan(coarse.latitudeError));
    });

    test('returns null rather than a point in the Atlantic', () {
      // (0, 0) for an unparseable hash would put a courier's pickup off the
      // coast of Africa, and the map would look like it worked.
      expect(decodeGeohash(''), isNull);
      expect(decodeGeohash('a1b2'), isNull); // 'a' is not in the alphabet
      expect(decodeGeohash('ezs4!'), isNull);
      expect(decodeGeohash('ezs4i'), isNull); // i, l, o and a are excluded
      expect(decodeGeohash('ezs4l'), isNull);
      expect(decodeGeohash('ezs4o'), isNull);
    });
  });

  group('round trip', () {
    test('encode then decode lands inside the cell it came from', () {
      // Real-ish coordinates, including the service area this ships in.
      const points = [
        (27.7172, 85.3240), // Kathmandu
        (28.2096, 83.9856), // Pokhara
        (-33.8688, 151.2093), // southern + eastern hemisphere
        (0.0, 0.0),
        (89.9, 179.9), // near the corners the clamp protects
        (-89.9, -179.9),
      ];

      for (final (lat, lon) in points) {
        for (final precision in [5, 9, 12]) {
          final hash = encodeGeohash(lat, lon, precision: precision);
          final area = decodeGeohash(hash)!;

          expect(
            (area.latitude - lat).abs(),
            lessThanOrEqualTo(area.latitudeError),
            reason: '$lat,$lon at precision $precision -> $hash',
          );
          expect(
            (area.longitude - lon).abs(),
            lessThanOrEqualTo(area.longitudeError),
            reason: '$lat,$lon at precision $precision -> $hash',
          );
        }
      }
    });

    test('the precisions the app actually uses survive the trip', () {
      for (final precision in [serviceAreaPrecision, custodyEventPrecision]) {
        final hash = encodeGeohash(27.7172, 85.3240, precision: precision);
        expect(hash.length, precision);
        expect(decodeGeohash(hash), isNotNull);
      }
    });
  });
}
