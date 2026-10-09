import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/push_destination.dart';

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
  });
}
