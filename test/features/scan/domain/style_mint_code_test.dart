import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
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
      'https://stylemint.voyageritnepal.com/products/prod_1': '/product/prod_1',
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

  test('reads StyleMint code links as /c routes', () {
    const cases = {
      'https://stylemint.voyageritnepal.com/c/ABCD2345': '/c/ABCD2345',
      // Codes are case-insensitive.
      'https://stylemint.voyageritnepal.com/c/abcd2345': '/c/ABCD2345',
      'https://stylemint.app/c/7K9M2PQR/': '/c/7K9M2PQR',
      'stylemint://c/7k9m2pqr': '/c/7K9M2PQR',
      // An NFC tag's via=nfc is kept, in any casing.
      'https://stylemint.voyageritnepal.com/c/ABCD2345?via=nfc':
          '/c/ABCD2345?via=Nfc',
      'https://stylemint.voyageritnepal.com/c/ABCD2345?via=NFC':
          '/c/ABCD2345?via=Nfc',
      // Anything else in `via` is ignored: the link counts as a link.
      'https://stylemint.voyageritnepal.com/c/ABCD2345?via=Qr': '/c/ABCD2345',
    };
    for (final MapEntry(key: raw, value: route) in cases.entries) {
      final code = StyleMintCode.parse(raw);
      expect(code, isA<StyleMintShortCode>(), reason: raw);
      expect((code! as StyleMintShortCode).route, route, reason: raw);
    }

    final fromTag =
        StyleMintCode.parse(
              'https://stylemint.voyageritnepal.com/c/abcd2345?via=nfc',
            )!
            as StyleMintShortCode;
    expect(fromTag.code, 'ABCD2345');
    expect(fromTag.via, CodeScanVia.nfc);
    expect(
      (StyleMintCode.parse('stylemint://c/ABCD2345')! as StyleMintShortCode)
          .via,
      isNull,
    );
  });

  test('code links that are not StyleMint codes open nothing', () {
    for (final raw in [
      // Wrong length.
      'https://stylemint.voyageritnepal.com/c/ABCD234',
      'https://stylemint.voyageritnepal.com/c/ABCD23456',
      'stylemint://c/',
      // I, L, O and U are not in the code alphabet.
      'https://stylemint.voyageritnepal.com/c/ABCI2345',
      'https://stylemint.voyageritnepal.com/c/ABCL2345',
      'stylemint://c/ABCO2345',
      'stylemint://c/abcu2345',
      'https://stylemint.voyageritnepal.com/c/ABCD-234',
      // Not a StyleMint host.
      'https://example.com/c/ABCD2345',
      'https://stylemint.voyageritnepal.com.evil.com/c/ABCD2345',
      'ftp://stylemint.voyageritnepal.com/c/ABCD2345',
      // Extra segments.
      'stylemint://c/ABCD2345/extra',
      // A bare code isn't a link.
      'ABCD2345',
    ]) {
      expect(StyleMintCode.parse(raw), isNull, reason: raw);
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
