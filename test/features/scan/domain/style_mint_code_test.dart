import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/scan/domain/style_mint_code.dart';

void main() {
  test('reads a web login code', () {
    for (final raw in [
      'stylemint://qr-login?token=pub-123&app=brand',
      '  stylemint://qr-login?token=pub-123  ',
      'https://stylemint.voyageritnepal.com/qr-login?token=pub-123',
    ]) {
      final code = StyleMintCode.parse(raw);
      expect(code, isA<QrLoginCode>(), reason: raw);
      expect((code! as QrLoginCode).token, 'pub-123', reason: raw);
    }
  });

  test('reads a drop party join code', () {
    final code = StyleMintCode.parse('AB12cd');
    expect(code, isA<DropPartyInviteCode>());
    expect((code! as DropPartyInviteCode).joinCode, 'AB12cd');
  });

  test('turns StyleMint links into in-app routes', () {
    const cases = {
      'stylemint://product/prod-1': '/product/prod-1',
      'https://stylemint.voyageritnepal.com/products/prod_1':
          '/product/prod_1',
      'https://stylemint.voyageritnepal.com/reels/reel-9': '/reels/reel-9',
      'https://stylemint.app/reels/reel-9/': '/reels/reel-9',
      'stylemint://creator-profile/acc-7': '/creator-profile/acc-7',
      'stylemint://drop/party-2': '/drop/party-2',
      'stylemint://group-cart/cart-4': '/group-cart/cart-4',
    };
    for (final MapEntry(key: raw, value: route) in cases.entries) {
      final code = StyleMintCode.parse(raw);
      expect(code, isA<StyleMintLinkCode>(), reason: raw);
      expect((code! as StyleMintLinkCode).route, route, reason: raw);
    }
  });

  test('anything else is not a StyleMint code', () {
    for (final raw in [
      null,
      '',
      '   ',
      'hello world',
      'ABC12',
      'ABC1234',
      'https://example.com/product/prod-1',
      'https://example.com/qr-login?token=pub-123',
      'https://stylemint.voyageritnepal.com.evil.com/product/prod-1',
      'stylemint://qr-login',
      'stylemint://qr-login?token=',
      // StyleMint links that do more than browse.
      'stylemint://auth/magic?token=abc',
      'https://stylemint.voyageritnepal.com/settings/delete-account',
      'stylemint://social-connected?status=ok',
      'stylemint://drop/scan',
      // Malformed ids and extra segments.
      'stylemint://product/prod%201',
      'stylemint://product/prod-1/reviews',
      'javascript:alert(1)',
      'tel:9800000000',
    ]) {
      expect(StyleMintCode.parse(raw), isNull, reason: '$raw');
    }
  });
}
