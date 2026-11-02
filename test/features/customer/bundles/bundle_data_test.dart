import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/push_destination.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/data/bundle_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_pricing.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_routes.dart';

import 'bundle_fixtures.dart';

void main() {
  group('bundle pricing (contract §B7)', () {
    test('discount is rounded to 2 places, halves away from zero', () {
      expect(bundleUnitPrice(12000, 10), 10800);
      // 999.99 × 15% = 149.9985 → 150.00 → 849.99
      expect(bundleUnitPrice(999.99, 15), 849.99);
      // 0.05 × 50% = 0.025 → 0.03 (away from zero) → 0.02
      expect(bundleUnitPrice(0.05, 50), 0.02);
      expect(bundleUnitPrice(500, 0), 500);
    });

    test('a quote follows the picked variants and item quantities', () {
      final bundle = readBundleDetail(bundleDetailWire());
      final initial = quoteBundle(bundle, {
        for (final i in bundle.items)
          if (i.initialVariant case final v?) i.id: v.id,
      });
      // jacket 12000 ×1 + socks 500 ×2 = 13000 list, 10% off.
      expect(initial.listTotal.amount, 13000);
      expect(initial.bundleTotal.amount, 11700);
      expect(initial.saving.amount, 1300);
      expect(initial.complete, isTrue);

      // The L jacket costs more.
      final large = quoteBundle(bundle, {
        'bi-jacket': 'v-jacket-l',
        'bi-socks': 'v-socks',
      });
      expect(large.listTotal.amount, 14000);
      expect(large.bundleTotal.amount, 12600);
    });

    test('a variant that cannot cover the quantity leaves it incomplete', () {
      final bundle = readBundleDetail(bundleDetailWire());
      final quote = quoteBundle(bundle, {
        'bi-jacket': 'v-jacket-xl', // out of stock
        'bi-socks': 'v-socks',
      });
      expect(quote.complete, isFalse);
    });
  });

  group('readers', () {
    test('BundleDetailDto: items grouped by shop, curator, terms', () {
      final bundle = readBundleDetail(bundleDetailWire());
      expect(bundle.title, 'Trekking kit');
      expect(bundle.termsVersion, 3);
      expect(bundle.discountPercent, 10);
      expect(bundle.isPurchasable, isTrue);
      expect(bundle.curator?.byline, 'Picked by @asha');
      expect(bundle.shops.map((s) => s.shopName), ['Peak Gear', 'Sock Co']);
      final jacket = bundle.items.first;
      expect(jacket.variants, hasLength(3));
      expect(jacket.needsChoice, isTrue);
      expect(jacket.initialVariant?.id, 'v-jacket-m');
      expect(bundle.items.last.quantity, 2);
    });

    test('unavailable reasons read from snake or camel case', () {
      final paused = readBundleDetail(
        bundleDetailWire(purchasable: false, reason: 'paused'),
      );
      expect(paused.isPurchasable, isFalse);
      expect(paused.unavailableReason, BundleUnavailableReason.paused);
      expect(
        BundleUnavailableReason.fromWire('item_out_of_stock'),
        BundleUnavailableReason.itemOutOfStock,
      );
      expect(BundleUnavailableReason.fromWire(null), isNull);
    });

    test('a reel taggedBundles entry becomes a card with totals', () {
      final tags = readReelTaggedBundles([
        {
          'taggedBundleId': 'tb-1',
          'x': 0.4,
          'y': 0.7,
          'bundle': {
            'id': 'b-1',
            'title': 'Trekking kit',
            'discountPercent': 10,
            'totals': {'listTotal': 20000, 'bundleTotal': 18000},
            'itemCount': 4,
            'shopCount': 2,
          },
        },
        {'taggedBundleId': '', 'bundle': <String, dynamic>{}},
        'junk',
      ]);
      expect(tags, hasLength(1));
      expect(tags.single.bundle.saving.amount, 2000);
      expect(tags.single.bundle.shopCount, 2);
      expect(tags.single.x, 0.4);
      expect(readReelTaggedBundles(null), isEmpty);
    });

    test('a card built from a detail payload prices its default variants', () {
      final card = readBundleCard(bundleDetailWire());
      expect(card.itemCount, 2);
      expect(card.shopCount, 2);
      expect(card.bundleTotal.amount, 11700);
    });
  });

  group('failures', () {
    DioException http(int status, [Map<String, dynamic>? body]) =>
        DioException(
          requestOptions: RequestOptions(path: '/v1/public/bundles/x'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/v1/public/bundles/x'),
            statusCode: status,
            data: body,
          ),
        );

    test('a bare 404 means bundles are not deployed', () {
      final failure = mapBundleFailure(http(404));
      expect(failure.isNotDeployed, isTrue);
      expect(bundlesNotDeployed(BundleLoadException(failure)), isTrue);
    });

    test('a coded 409 keeps its code and body', () {
      final failure = mapBundleFailure(
        http(409, {'errorCode': 'bundle_terms_changed', 'termsVersion': 4}),
      );
      expect(failure.isTermsChanged, isTrue);
      expect(failure.isNotDeployed, isFalse);
      expect(failure.body['termsVersion'], 4);
      expect(bundleFailureMessage(failure), contains('changed'));
    });
  });

  group('links', () {
    test('/app/bundles/{id} and stylemint://bundles/{id} open the page', () {
      expect(
        deepLinkLocation(
          Uri.parse('https://stylemint.voyageritnepal.com/app/bundles/b-1'),
        ),
        '/bundles/b-1',
      );
      expect(deepLinkLocation(Uri.parse('stylemint://bundles/b-1')), '/bundles/b-1');
      expect(
        BundleRoutes.detailPath('b-1', taggedBundleId: 'tb-1'),
        '/bundles/b-1?t=tb-1',
      );
    });
  });
}
