import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/deep_links.dart';

const _vendorId = '3f2504e0-4f89-11d3-9a0c-0305e82c3301';
const _accountId = 'b1e7c9d2-8a44-4c31-9f10-6d5b2a7e4c88';

void main() {
  test('shared brand web links open the brand storefront', () {
    final links = {
      'https://stylemint.voyageritnepal.com/brands/$_vendorId':
          '/brands/$_vendorId',
      'https://stylemint.voyageritnepal.com/brands/$_vendorId?ref=share':
          '/brands/$_vendorId',
      'https://stylemint.voyageritnepal.com/brands/${_vendorId.toUpperCase()}':
          '/brands/${_vendorId.toUpperCase()}',
      ' https://stylemint.voyageritnepal.com/brands/$_vendorId ':
          '/brands/$_vendorId',
      '/brands/$_vendorId': '/brands/$_vendorId',
    };
    for (final entry in links.entries) {
      expect(
        styleMintStorefrontRoute(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('shared creator web links open the creator storefront', () {
    final links = {
      'https://stylemint.voyageritnepal.com/creator-profile/$_accountId':
          '/creator-profile/$_accountId',
      'https://stylemint.voyageritnepal.com/creator-profile/$_accountId#reels':
          '/creator-profile/$_accountId',
      '/creator-profile/$_accountId': '/creator-profile/$_accountId',
    };
    for (final entry in links.entries) {
      expect(
        styleMintStorefrontRoute(entry.key),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('the app-dock stylemint:// forms resolve to the same routes', () {
    expect(
      styleMintStorefrontRoute('stylemint://brands/$_vendorId'),
      '/brands/$_vendorId',
    );
    expect(
      styleMintStorefrontRoute('stylemint://creator-profile/$_accountId'),
      '/creator-profile/$_accountId',
    );
  });

  test('a malformed id falls back to home instead of an empty storefront', () {
    const links = [
      'https://stylemint.voyageritnepal.com/brands/not-a-guid',
      'https://stylemint.voyageritnepal.com/brands/123',
      'https://stylemint.voyageritnepal.com/creator-profile/%20',
      'stylemint://brands/undefined',
      'stylemint://creator-profile/null',
      '/brands/abc',
    ];
    for (final link in links) {
      expect(styleMintStorefrontRoute(link), '/home', reason: link);
    }
  });

  test('every other link is left to the caller', () {
    final links = [
      null,
      '',
      '   ',
      // Other hosts must never open a StyleMint storefront.
      'https://evil.example/brands/$_vendorId',
      '//evil.example/brands/$_vendorId',
      'intent://brands/$_vendorId#Intent;end',
      // Not storefront links.
      'https://stylemint.voyageritnepal.com/reels/r-9',
      'https://stylemint.voyageritnepal.com/c/AB12CD34',
      'https://stylemint.voyageritnepal.com/brands',
      'https://stylemint.voyageritnepal.com/brands/$_vendorId/products',
      // Dot segments are not a storefront link either; go_router's own
      // not-found handling takes it from here.
      'https://stylemint.voyageritnepal.com/creator-profile/../admin',
      'stylemint://social-connected?status=ok',
      'brands/$_vendorId',
    ];
    for (final link in links) {
      expect(styleMintStorefrontRoute(link), isNull, reason: '$link');
    }
  });
}
