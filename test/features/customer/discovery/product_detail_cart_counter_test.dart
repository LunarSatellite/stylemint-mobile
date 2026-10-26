import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/account_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../smoke/fake_api_client.dart';
import '../ai_rails/fake_ai_rails_repository.dart';
import '../checkout/checkout_harness.dart' show testCheckoutLayouts;

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockTokenStorage extends Mock implements TokenStorage {}

class _MockProfileNotifier extends Mock implements ProfileNotifier {}

class _MockRoleNotifier extends Mock implements RoleNotifier {}

class _MockAccountNotifier extends Mock implements AccountNotifier {}

class _MockCartNotifier extends Mock implements CartNotifier {}

class _MockFollowApi extends Mock implements FollowApi {}

/// Signed in, so Add to cart and Buy now go straight through.
class _SignedInSession extends SessionController {
  _SignedInSession()
    : super(
        authRepository: _MockAuthRepository(),
        tokenStorage: _MockTokenStorage(),
        profileNotifier: _MockProfileNotifier(),
        roleNotifier: _MockRoleNotifier(),
        accountNotifier: _MockAccountNotifier(),
        cartNotifier: _MockCartNotifier(),
        followNotifier: FollowNotifier(_MockFollowApi()),
      ) {
    state = const AuthSessionState.authenticated('viewer-1');
  }
}

class _FakeFollowApi implements FollowApi {
  @override
  Future<void> follow(String followeeAccountId) async {}

  @override
  Future<void> unfollow(String followeeAccountId) async {}

  @override
  Future<List<String>> followingIds({int pageSize = 200}) async =>
      const <String>[];

  @override
  Future<FollowStats> stats(String accountId) => throw UnimplementedError();
}

const _zero = Money(amount: 0, currency: 'NPR');

/// An in-memory cart: what the server would hold, with the writes recorded.
class _FakeCartRepository implements CartRepository {
  _FakeCartRepository([List<CartItem> items = const []]) : items = [...items];

  List<CartItem> items;
  bool failWrites = false;
  final updates = <(String, int)>[];
  final removals = <String>[];

  Cart get cart => Cart(
    id: 'cart-1',
    items: List.of(items),
    subtotal: _zero,
    shippingTotal: _zero,
    taxTotal: _zero,
    total: _zero,
  );

  /// What the product page's own add (Discovery's endpoint) puts here.
  void addUnit(String productId, String? variantId) {
    final i = items.indexWhere(
      (l) => l.productId == productId && l.variantId == variantId,
    );
    if (i >= 0) {
      items[i] = items[i].copyWith(quantity: items[i].quantity + 1);
    } else {
      items.add(_line(quantity: 1, variantId: variantId));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> getCart() async => right(cart);

  @override
  Future<Either<NetworkExceptions, Cart>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    updates.add((itemId, quantity));
    if (failWrites) return left(const NetworkExceptions.server('No'));
    items = [
      for (final l in items) l.id == itemId ? l.copyWith(quantity: quantity) : l,
    ];
    return right(cart);
  }

  @override
  Future<Either<NetworkExceptions, Cart>> removeCartItem(String itemId) async {
    removals.add(itemId);
    if (failWrites) return left(const NetworkExceptions.server('No'));
    items = [for (final l in items) if (l.id != itemId) l];
    return right(cart);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CartItem _line({required int quantity, String? variantId = 'var-1'}) =>
    CartItem(
      id: 'line-1',
      productId: 'p1',
      productName: 'Hand-loomed pashmina overcoat',
      productImageUrl: '',
      variantName: 'One size',
      quantity: quantity,
      unitPrice: const Money(amount: 6225, currency: 'NPR'),
      isInStock: true,
      variantId: variantId,
    );

/// A product with nothing to choose: the bar can add it directly.
const _product = ProductDetail(
  id: 'p1',
  name: 'Hand-loomed pashmina overcoat',
  description: 'Woven in Kathmandu.',
  images: [],
  price: Money(amount: 6225, currency: 'NPR'),
  compareAtPrice: Money(amount: 12450, currency: 'NPR'),
  rating: 4.8,
  reviewCount: 214,
  vendorId: 'v1',
  vendorName: 'Himalayan Weaves',
  vendorAvatarUrl: '',
  isInStock: true,
  stockCount: 6,
  variants: [],
  specifications: {},
  shippingInfo: 'Ships in 2 days',
  isSaved: false,
  isInCart: false,
  defaultVariantId: 'var-1',
);

late _MockDiscoveryRepository _discovery;
late _FakeCartRepository _cart;

/// The product page at `/product/p1`, with the cart and checkout as
/// stand-in pages, a signed-in buyer and every rail stubbed.
Future<void> _pump(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: RouteNames.productDetailPath('p1'),
    routes: [
      GoRoute(
        path: RouteNames.productDetail,
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['productId']!),
      ),
      for (final path in [RouteNames.cart, RouteNames.checkout])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('page:$path', key: Key(path))),
        ),
    ],
  );
  addTearDown(router.dispose);
  final overrides = <Override>[
    apiClientProvider.overrideWithValue(FakeApiClient()),
    productDetailNotifierProvider.overrideWith(
      (ref, id) => ProductDetailNotifier(_discovery),
    ),
    cartRepositoryProvider.overrideWithValue(_cart),
    sessionControllerProvider.overrideWith((ref) => _SignedInSession()),
    followApiProvider.overrideWithValue(_FakeFollowApi()),
    aiRailsRepositoryProvider.overrideWithValue(FakeAiRailsRepository()),
    // Nothing is queued, so no flush timer outlives the test.
    engagementOwnerProvider.overrideWithValue(() => null),
  ];
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await _frames(tester);
}

Future<void> _frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.tap(find.byKey(key));
  await _frames(tester);
}

/// Lets the "Added to cart" confirmation run out.
Future<void> _drainSnackBars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
}

String? _count(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(ProductDetailScreen.cartCountKey)).data;

void _verifyNoAdd() => verifyNever(
  () => _discovery.addToCart(
    productId: any(named: 'productId'),
    qty: any(named: 'qty'),
    variantId: any(named: 'variantId'),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _discovery = _MockDiscoveryRepository();
    _cart = _FakeCartRepository();
    when(
      () => _discovery.getProductDetail(any()),
    ).thenAnswer((_) async => right(_product));
    when(
      () => _discovery.addToCart(
        productId: any(named: 'productId'),
        qty: any(named: 'qty'),
        variantId: any(named: 'variantId'),
      ),
    ).thenAnswer((invocation) async {
      _cart.addUnit(
        invocation.namedArguments[#productId] as String,
        invocation.namedArguments[#variantId] as String?,
      );
      return right(unit);
    });
  });

  group('the in-cart counter', () {
    testWidgets('Add to cart turns into a counter showing 1', (tester) async {
      await _pump(tester);
      expect(find.byKey(ProductDetailScreen.cartCountKey), findsNothing);

      await _tap(tester, ProductDetailScreen.addToCartKey);

      expect(tester.takeException(), isNull);
      expect(find.byKey(ProductDetailScreen.addToCartKey), findsNothing);
      expect(_count(tester), '1');
      expect(find.text('Added to cart'), findsOneWidget);
      verify(
        () => _discovery.addToCart(productId: 'p1', qty: 1, variantId: 'var-1'),
      ).called(1);
      await _drainSnackBars(tester);
    });

    testWidgets('+ makes it 2 through the cart line update', (tester) async {
      _cart = _FakeCartRepository([_line(quantity: 1)]);
      await _pump(tester);
      expect(_count(tester), '1');

      await _tap(tester, ProductDetailScreen.cartIncrementKey);

      expect(_cart.updates, [('line-1', 2)]);
      expect(_count(tester), '2');
      _verifyNoAdd();
    });

    testWidgets('- at 1 removes the line and Add to cart comes back', (
      tester,
    ) async {
      _cart = _FakeCartRepository([_line(quantity: 1)]);
      await _pump(tester);

      await _tap(tester, ProductDetailScreen.cartDecrementKey);

      expect(_cart.removals, ['line-1']);
      expect(_cart.updates, isEmpty);
      expect(find.byKey(ProductDetailScreen.cartCountKey), findsNothing);
      expect(find.byKey(ProductDetailScreen.addToCartKey), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets('- above 1 takes one unit off', (tester) async {
      _cart = _FakeCartRepository([_line(quantity: 3)]);
      await _pump(tester);

      await _tap(tester, ProductDetailScreen.cartDecrementKey);

      expect(_cart.updates, [('line-1', 2)]);
      expect(_count(tester), '2');
    });

    testWidgets('a product already in the cart shows its quantity at once', (
      tester,
    ) async {
      _cart = _FakeCartRepository([_line(quantity: 3)]);
      await _pump(tester);

      expect(_count(tester), '3');
      expect(find.byKey(ProductDetailScreen.addToCartKey), findsNothing);
    });

    testWidgets('another variant in the cart does not count for this one', (
      tester,
    ) async {
      _cart = _FakeCartRepository([_line(quantity: 2, variantId: 'var-2')]);
      await _pump(tester);

      expect(find.byKey(ProductDetailScreen.cartCountKey), findsNothing);
      expect(find.byKey(ProductDetailScreen.addToCartKey), findsOneWidget);
    });

    testWidgets('a refused change keeps the number and says so', (
      tester,
    ) async {
      _cart = _FakeCartRepository([_line(quantity: 2)])..failWrites = true;
      await _pump(tester);

      await _tap(tester, ProductDetailScreen.cartIncrementKey);

      expect(_cart.updates, [('line-1', 3)]);
      expect(_count(tester), '2');
      expect(
        find.text("Couldn't update your cart. Please try again."),
        findsOneWidget,
      );
      await _drainSnackBars(tester);
    });
  });

  group('Buy now', () {
    testWidgets('with the item already in the cart, adds nothing and opens '
        'the cart', (tester) async {
      _cart = _FakeCartRepository([_line(quantity: 2)]);
      await _pump(tester);

      await _tap(tester, ProductDetailScreen.buyNowKey);

      _verifyNoAdd();
      expect(_cart.updates, isEmpty);
      expect(find.byKey(const Key(RouteNames.cart)), findsOneWidget);
      expect(find.byKey(const Key(RouteNames.checkout)), findsNothing);
    });

    testWidgets('with an empty cart, adds one unit and opens the cart', (
      tester,
    ) async {
      await _pump(tester);

      await _tap(tester, ProductDetailScreen.buyNowKey);

      verify(
        () => _discovery.addToCart(productId: 'p1', qty: 1, variantId: 'var-1'),
      ).called(1);
      expect(_cart.items.single.quantity, 1);
      expect(find.byKey(const Key(RouteNames.cart)), findsOneWidget);
      expect(find.byKey(const Key(RouteNames.checkout)), findsNothing);
    });

    testWidgets('after Add to cart, adds nothing more', (tester) async {
      await _pump(tester);
      await _tap(tester, ProductDetailScreen.addToCartKey);
      await _drainSnackBars(tester);

      await _tap(tester, ProductDetailScreen.buyNowKey);

      verify(
        () => _discovery.addToCart(
          productId: any(named: 'productId'),
          qty: any(named: 'qty'),
          variantId: any(named: 'variantId'),
        ),
      ).called(1);
      expect(_cart.items.single.quantity, 1);
      expect(find.byKey(const Key(RouteNames.cart)), findsOneWidget);
    });
  });

  testCheckoutLayouts('the in-cart counter fits', (
    tester,
    width,
    textScale,
  ) async {
    _cart = _FakeCartRepository([_line(quantity: 12)]);
    await _pump(tester, width: width, textScale: textScale);

    expect(tester.takeException(), isNull);
    expect(_count(tester), '12');
    expect(find.text('Buy Now'), findsOneWidget);
  });
}
