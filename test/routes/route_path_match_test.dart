import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_path_match.dart';

void main() {
  test('a pattern without parameters still matches as a prefix', () {
    expect(routePathMatches('/settings/privacy', '/settings'), isTrue);
    expect(routePathMatches('/home', '/home'), isTrue);
    expect(routePathMatches('/cart', '/home'), isFalse);
  });

  test('a parameter matches any one segment', () {
    expect(routePathMatches('/product/p-1', '/product/:productId'), isTrue);
    expect(
      routePathMatches('/creator-profile/acc-7', '/creator-profile/:accountId'),
      isTrue,
    );
    expect(routePathMatches('/reels/r-9', '/reels/:reelId'), isTrue);
  });

  test('the location may continue below the pattern', () {
    expect(
      routePathMatches('/product/p-1/reviews', '/product/:productId'),
      isTrue,
    );
  });

  test('query strings and fragments are ignored', () {
    expect(
      routePathMatches('/product/p-1?from=mall#top', '/product/:productId'),
      isTrue,
    );
  });

  test('different literals or a missing segment never match', () {
    expect(routePathMatches('/products', '/product/:productId'), isFalse);
    expect(routePathMatches('/product', '/product/:productId'), isFalse);
    expect(routePathMatches('/product/', '/product/:productId'), isFalse);
    expect(routePathMatches('/cart/p-1', '/product/:productId'), isFalse);
  });
}
