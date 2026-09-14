import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

void main() {
  group('backFallbackFor', () {
    test('creator pages fall back to the creator studio', () {
      expect(backFallbackFor('/creator/import'), RouteNames.creatorHome);
      expect(backFallbackFor('/creator/reels/abc'), RouteNames.creatorHome);
    });

    test('vendor pages fall back to the vendor dashboard', () {
      expect(backFallbackFor('/vendor/orders'), RouteNames.vendorHome);
    });

    test('studio homes and everything else fall back to the shopping feed', () {
      expect(backFallbackFor(RouteNames.creatorHome), RouteNames.home);
      expect(backFallbackFor(RouteNames.vendorHome), RouteNames.home);
      expect(backFallbackFor('/cart'), RouteNames.home);
      expect(backFallbackFor(''), RouteNames.home);
    });
  });
}
