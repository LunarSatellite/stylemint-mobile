import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/push_destination.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

void main() {
  group('pushDestinationUri', () {
    test('a bare path becomes a stylemint:// link the router can read', () {
      // The first segment has to land in the host, not the path: _navigate
      // rebuilds `stylemint://orders/42` as /orders/42, while a third slash
      // would give an empty host and swallow the segment.
      final uri = pushDestinationUri({'route': '/orders/42'});
      expect(uri, isNotNull);
      expect(uri!.scheme, 'stylemint');
      expect(uri.host, 'orders');
      expect(uri.path, '/42');
    });

    test('an https link is passed through untouched', () {
      final uri = pushDestinationUri({
        'deepLink': 'https://stylemint.voyageritnepal.com/c/ABC123',
      });
      expect(uri.toString(), 'https://stylemint.voyageritnepal.com/c/ABC123');
    });

    test('a stylemint:// link is passed through untouched', () {
      final uri = pushDestinationUri({'link': 'stylemint://c/ABC123'});
      expect(uri.toString(), 'stylemint://c/ABC123');
    });

    test('the documented spellings are all accepted', () {
      for (final key in ['deepLink', 'deep_link', 'link', 'url', 'route']) {
        expect(
          pushDestinationUri({key: 'stylemint://orders'}),
          isNotNull,
          reason: key,
        );
      }
    });

    test('earlier keys win, so a server sending two is not ambiguous', () {
      final uri = pushDestinationUri({
        'deepLink': 'stylemint://first',
        'url': 'stylemint://second',
      });
      expect(uri!.host, 'first');
    });

    test('no destination is null, not a guess', () {
      // A notification that only tells the user something — "your parcel was
      // delivered" — carries no route, and opening the app is correct.
      expect(pushDestinationUri({}), isNull);
      expect(pushDestinationUri({'title': 'Delivered'}), isNull);
    });

    test('blank and whitespace-only values are ignored', () {
      expect(pushDestinationUri({'route': ''}), isNull);
      expect(pushDestinationUri({'route': '   '}), isNull);
    });

    test('a value with no scheme is ignored rather than half-resolved', () {
      // "orders/42" without a leading slash is not a path this can place, and
      // inventing one would navigate somewhere nobody asked for.
      expect(pushDestinationUri({'route': 'orders/42'}), isNull);
    });

    test('non-string values are tolerated', () {
      expect(pushDestinationUri({'route': 42}), isNull);
    });
  });

  group('deepLinkLocation', () {
    test('a custom-scheme link gets its host back in front of the path', () {
      expect(
        deepLinkLocation(Uri.parse('stylemint://orders/SM-1')),
        '/orders/SM-1',
      );
    });

    test('the site root (the email button) opens home', () {
      expect(
        deepLinkLocation(Uri.parse('https://stylemint.voyageritnepal.com')),
        RouteNames.home,
      );
      expect(
        deepLinkLocation(Uri.parse('https://stylemint.voyageritnepal.com/')),
        RouteNames.home,
      );
    });

    test('an https link is its path, with the query kept', () {
      expect(
        deepLinkLocation(
          Uri.parse('https://stylemint.voyageritnepal.com/orders?tab=open'),
        ),
        '/orders?tab=open',
      );
    });

    test('a StyleMint code opens the resolve screen', () {
      expect(
        deepLinkLocation(Uri.parse('stylemint://c/ABCD2345')),
        startsWith('/c/'),
      );
    });

    group('email links (https://<host>/app/<app route>)', () {
      const site = 'https://stylemint.voyageritnepal.com';
      const returnId = '0f8fad5b-d9cb-469f-a165-70867728950e';

      test('drop the /app prefix and open the app route', () {
        expect(
          deepLinkLocation(Uri.parse('$site/app/orders/NK2026-00041')),
          '/orders/NK2026-00041',
        );
        expect(
          deepLinkLocation(Uri.parse('$site/app/orders/returns/$returnId')),
          '/orders/returns/$returnId',
        );
        expect(deepLinkLocation(Uri.parse('$site/app/cart')), RouteNames.cart);
        expect(
          deepLinkLocation(Uri.parse('$site/app/creator/earnings')),
          RouteNames.earnings,
        );
      });

      test('/app on its own opens home', () {
        expect(deepLinkLocation(Uri.parse('$site/app')), RouteNames.home);
        expect(deepLinkLocation(Uri.parse('$site/app/')), RouteNames.home);
        expect(deepLinkLocation(Uri.parse('stylemint://app')), RouteNames.home);
        expect(
          deepLinkLocation(Uri.parse('stylemint://app/')),
          RouteNames.home,
        );
      });

      test('the query is kept', () {
        expect(
          deepLinkLocation(Uri.parse('$site/app/orders?tab=open')),
          '/orders?tab=open',
        );
      });

      test('a StyleMint code under /app still opens the resolve screen', () {
        expect(
          deepLinkLocation(Uri.parse('$site/app/c/ABCD2345')),
          startsWith('/c/'),
        );
      });

      test('only a whole leading /app segment is the prefix', () {
        expect(deepLinkLocation(Uri.parse('$site/apple')), '/apple');
        expect(
          deepLinkLocation(Uri.parse('$site/orders/app')),
          '/orders/app',
        );
      });

      test('stylemint://app/... and a bare /app push path unwrap too', () {
        expect(
          deepLinkLocation(Uri.parse('stylemint://app/orders/NK2026-00041')),
          '/orders/NK2026-00041',
        );
        final pushed = pushDestinationUri({
          'deepLink': '/app/orders/NK2026-00041',
        });
        expect(deepLinkLocation(pushed!), '/orders/NK2026-00041');
      });
    });

    test("the web page's button, stylemint://<app route>, routes too", () {
      // The /app page in a browser hands over to the custom scheme: the first
      // segment lands in the host and is rebuilt in front of the path.
      expect(
        deepLinkLocation(Uri.parse('stylemint://orders/NK2026-00041')),
        '/orders/NK2026-00041',
      );
      expect(
        deepLinkLocation(
          Uri.parse(
            'stylemint://orders/returns/0f8fad5b-d9cb-469f-a165-70867728950e',
          ),
        ),
        '/orders/returns/0f8fad5b-d9cb-469f-a165-70867728950e',
      );
      expect(deepLinkLocation(Uri.parse('stylemint://cart')), RouteNames.cart);
    });
  });
}
