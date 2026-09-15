import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/navigation/in_app_link.dart';

void main() {
  test('StyleMint product links map to the in-app product route', () {
    const links = {
      '/product/abc-123': '/product/abc-123',
      'stylemint://product/abc': '/product/abc',
      'https://stylemint.voyageritnepal.com/product/abc': '/product/abc',
      'https://stylemint.voyageritnepal.com/products/abc?ref=reco':
          '/product/abc',
      ' /product/9f1c2d ': '/product/9f1c2d',
    };
    links.forEach((link, route) {
      expect(styleMintProductRoute(link), route, reason: link);
    });
  });

  test('every other link is not followed', () {
    const links = [
      null,
      '',
      '   ',
      'https://www.daraz.com.np/product/abc',
      'https://www.tiktok.com/@miko/video/1',
      'https://stylemint.voyageritnepal.com/reels/abc',
      '//evil.example/product/abc',
      'intent://product/abc#Intent;end',
      'product/abc',
      '/product/abc/reviews',
      '/product/',
      '/product/a%20b',
    ];
    for (final link in links) {
      expect(styleMintProductRoute(link), isNull, reason: '$link');
    }
  });
}
