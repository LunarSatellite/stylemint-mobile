import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'core/network/network_exceptions.dart';
import 'core/utils/format_date.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'core/config/api_config.dart';
import 'core/storage/token_storage.dart';
import 'features/messaging/shared/providers.dart';
import 'features/creator/social_connect/shared/providers.dart';
import 'features/customer/cart/domain/entities/cart.dart';
import 'features/customer/cart/domain/repositories/cart_repository.dart';
import 'features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'features/customer/cart/presentation/screens/cart_screen.dart';
import 'features/customer/cart/shared/providers.dart';
import 'features/customer/checkout/domain/entities/checkout.dart';
import 'features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'features/customer/checkout/presentation/screens/checkout_screen.dart';
import 'features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'features/customer/checkout/presentation/screens/payment_method_screen.dart';
import 'features/customer/checkout/shared/providers.dart';
import 'routes/app_router.dart';
import 'routes/route_names.dart';
import 'shared/domain/entities/money.dart';
import 'theme/app_theme.dart';

// ─── MOCK DATA for CartScreen UI preview ────────────────────────────────────
const _npr = 'NPR';

final _mockCart = Cart(
  id: 'mock-cart-001',
  supportedCreatorsCount: 2,
  items: [
    CartItem(
      id: 'item-1',
      productId: 'prod-1',
      productName: 'Oversized Linen Co-ord Set',
      productImageUrl: 'https://picsum.photos/seed/item1/64/64',
      variantName: 'Beige / Size M',
      quantity: 1,
      unitPrice: const Money(amount: 3499, currency: _npr),
      isInStock: true,
      creatorHandle: 'priya.styles',
      commissionRate: 0.15,
    ),
    CartItem(
      id: 'item-2',
      productId: 'prod-2',
      productName: 'Vintage Wash Denim Jacket',
      productImageUrl: 'https://picsum.photos/seed/item2/64/64',
      variantName: 'Light Blue / Size L',
      quantity: 2,
      unitPrice: const Money(amount: 5199, currency: _npr),
      isInStock: true,
    ),
  ],
  subtotal: const Money(amount: 13897, currency: _npr),
  shippingTotal: const Money(amount: 0, currency: _npr),
  taxTotal: const Money(amount: 1807, currency: _npr),
  total: const Money(amount: 15704, currency: _npr),
);

// Stateful mock so +/- buttons actually update quantities in the preview.
class _MockCartRepository implements CartRepository {
  Cart _cart = _mockCart;

  @override
  Future<Either<NetworkExceptions, Cart>> getCart() async => right(_cart);

  @override
  Future<Either<NetworkExceptions, BasketOptimization>>
  getBasketOptimization() async => right(const BasketOptimization(insights: []));

  @override
  Future<Either<NetworkExceptions, Cart>> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
    String? reelTagContextId,
    required String idempotencyKey,
  }) async => right(_cart);

  @override
  Future<Either<NetworkExceptions, Cart>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    _cart = _cart.copyWith(
      items: _cart.items
          .map((i) => i.id == itemId ? i.copyWith(quantity: quantity) : i)
          .toList(),
    );
    return right(_cart);
  }

  @override
  Future<Either<NetworkExceptions, Cart>> removeCartItem(String itemId) async {
    _cart = _cart.copyWith(
      items: _cart.items.where((i) => i.id != itemId).toList(),
    );
    return right(_cart);
  }

  @override
  Future<Either<NetworkExceptions, Cart>> applyPromo(String code) async =>
      right(_cart);

  @override
  Future<Either<NetworkExceptions, Cart>> removePromo() async => right(_cart);

  @override
  Future<Either<NetworkExceptions, Cart>> saveForLater(String lineId) async =>
      right(_cart);
}

// ─── MOCK CHECKOUT REPOSITORY ────────────────────────────────────────────────
class _MockCheckoutRepository implements CheckoutRepository {
  @override
  Future<Either<NetworkExceptions, CheckoutSummary>>
  getCheckoutSummary() async {
    return right(
      CheckoutSummary(
        shippingAddress: const ShippingAddress(
          id: 'addr-1',
          label: 'Home',
          line1: 'Thamel Marg',
          city: 'Kathmandu',
          stateProvince: 'Bagmati',
          postalCode: '44600',
          countryCode: 'NP',
          isDefault: true,
        ),
        paymentMethod: const PaymentMethod(
          id: 'pm-1',
          type: PaymentMethodType.card,
          label: 'Visa',
          lastFour: '4242',
          isDefault: true,
        ),
        items: const [
          CheckoutItem(
            productId: 'prod-1',
            productName: 'Oversized Linen Co-ord Set',
            imageUrl: 'https://picsum.photos/seed/item1/56/56',
            variantName: 'Beige / Size M',
            quantity: 1,
            unitPrice: Money(amount: 3499, currency: _npr),
          ),
          CheckoutItem(
            productId: 'prod-2',
            productName: 'Vintage Wash Denim Jacket',
            imageUrl: 'https://picsum.photos/seed/item2/56/56',
            variantName: 'Light Blue / Size L',
            quantity: 2,
            unitPrice: Money(amount: 5199, currency: _npr),
          ),
        ],
        subtotal: const Money(amount: 13897, currency: _npr),
        shipping: const Money(amount: 0, currency: _npr),
        tax: const Money(amount: 1807, currency: _npr),
        discount: const Money(amount: 0, currency: _npr),
        total: const Money(amount: 15704, currency: _npr),
        availableAddresses: const [
          ShippingAddress(
            id: 'addr-1',
            label: 'Home',
            line1: 'Thamel Marg',
            city: 'Kathmandu',
            stateProvince: 'Bagmati',
            postalCode: '44600',
            countryCode: 'NP',
            isDefault: true,
          ),
          ShippingAddress(
            id: 'addr-2',
            label: 'Office',
            line1: 'Pulchowk-20',
            city: 'Lalitpur',
            stateProvince: 'Bagmati',
            postalCode: '44700',
            countryCode: 'NP',
            isDefault: false,
          ),
        ],
        availablePaymentMethods: const [
          PaymentMethod(
            id: 'pm-1',
            type: PaymentMethodType.card,
            label: 'Visa Card',
            lastFour: '4242',
            isDefault: true,
          ),
          PaymentMethod(
            id: 'pm-2',
            type: PaymentMethodType.paypal,
            label: 'Paypal',
            lastFour: '@shreeteen123',
            isDefault: false,
          ),
          PaymentMethod(
            id: 'pm-3',
            type: PaymentMethodType.eSewa,
            label: 'eSewa',
            lastFour: '9840098522',
            isDefault: false,
          ),
          PaymentMethod(
            id: 'pm-4',
            type: PaymentMethodType.cod,
            label: 'Cash on Delivery',
            isDefault: false,
          ),
        ],
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, List<ShippingAddress>>>
  getShippingAddresses() async => right([
    const ShippingAddress(
      id: 'addr-1',
      label: 'Home',
      line1: 'Thamel Marg',
      city: 'Kathmandu',
      stateProvince: 'Bagmati',
      postalCode: '44600',
      countryCode: 'NP',
      isDefault: true,
    ),
    const ShippingAddress(
      id: 'addr-2',
      label: 'Office',
      line1: 'Pulchowk-20',
      city: 'Lalitpur',
      stateProvince: 'Bagmati',
      postalCode: '44700',
      countryCode: 'NP',
      isDefault: false,
    ),
  ]);

  @override
  Future<Either<NetworkExceptions, ShippingAddress>> addAddress({
    required String label,
    required String receiverName,
    required String receiverPhone,
    required String addressLine1,
    String? landmark,
    required String country,
    required String state,
    required String city,
    required String zipCode,
    bool makeDefault = false,
    required String idempotencyKey,
  }) async => right(
    ShippingAddress(
      id: 'addr-mock',
      label: label,
      line1: addressLine1,
      line2: landmark,
      city: city,
      stateProvince: state,
      postalCode: zipCode,
      countryCode: country,
      isDefault: makeDefault,
    ),
  );

  @override
  Future<Either<NetworkExceptions, List<PaymentMethod>>>
  getPaymentMethods() async => right([
    const PaymentMethod(
      id: 'pm-1',
      type: PaymentMethodType.card,
      label: 'Visa Card',
      lastFour: '4242',
      isDefault: true,
    ),
    const PaymentMethod(
      id: 'pm-3',
      type: PaymentMethodType.eSewa,
      label: 'eSewa',
      lastFour: '9840098522',
      isDefault: false,
    ),
    const PaymentMethod(
      id: 'pm-4',
      type: PaymentMethodType.cod,
      label: 'Cash on Delivery',
      lastFour: null,
      isDefault: false,
    ),
  ]);

  @override
  Future<Either<NetworkExceptions, PlaceOrderResult>> placeOrder({
    required String addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async => right(const PlaceOrderResult(
    orderNumber: 'mock-order-001',
    requiresPaymentAction: false,
  ));
}

// GoRouter for the single-screen preview (cart → checkout flow only).
final _previewRouter = GoRouter(
  initialLocation: RouteNames.cart,
  routes: [
    GoRoute(
      path: RouteNames.cart,
      builder: (_, __) => const CartScreen(),
    ),
    GoRoute(
      path: RouteNames.checkout,
      builder: (_, __) => const CheckoutScreen(),
      routes: [
        GoRoute(
          path: 'payment-method',
          builder: (_, __) => const PaymentMethodScreen(),
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.orderSuccess,
      builder: (_, state) => OrderSuccessScreen(
        orderId: state.pathParameters['orderId'] ?? 'mock-order-001',
      ),
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (_, __) => const CartScreen(),
    ),
  ],
);
// ────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTimezone();

  // ─── SINGLE SCREEN — CartScreen → CheckoutScreen preview (uncomment to use)─
  // runApp(
  //   ProviderScope(
  //     overrides: [
  //       cartNotifierProvider.overrideWith(
  //           (ref) => CartNotifier(_MockCartRepository())),
  //       checkoutNotifierProvider.overrideWith(
  //           (ref) => CheckoutNotifier(_MockCheckoutRepository())),
  //     ],
  //     child: MaterialApp.router(
  //       debugShowCheckedModeBanner: false,
  //       theme: AppTheme.light,
  //       darkTheme: AppTheme.dark,
  //       themeMode: ThemeMode.dark,
  //       routerConfig: _previewRouter,
  //     ),
  //   ),
  // );

  // ─── FULL APP ────────────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: _AppWithDeepLinks(),
    ),
  );
}

/// Wraps [StyleMintApp] and listens for incoming deep links so that magic-link
/// and OAuth callback URIs are routed to the correct screen.
///
/// Deep-link format:
///   `stylemint://auth/magic?token=<token>`
///   `https://stylemint.voyageritnepal.com/auth/magic?token=<token>`
class _AppWithDeepLinks extends ConsumerStatefulWidget {
  const _AppWithDeepLinks();

  @override
  ConsumerState<_AppWithDeepLinks> createState() => _AppWithDeepLinksState();
}

class _AppWithDeepLinksState extends ConsumerState<_AppWithDeepLinks> {
  late final AppLinks _appLinks;

  /// A deep link that arrived while the session was still bootstrapping
  /// (`AuthSessionState.unknown`). The router's redirect bounces every
  /// non-splash path to splash while the session is unknown, which would drop
  /// the link and its token (e.g. a magic-link launched cold). We hold it here
  /// and replay it once the session resolves.
  Uri? _pendingUri;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _listenDeepLinks();
    // Replay any deferred deep link as soon as the session leaves `unknown`.
    ref.listenManual<AuthSessionState>(sessionControllerProvider, (_, next) {
      final stillUnknown = next.maybeWhen(
        unknown: () => true,
        orElse: () => false,
      );
      final pending = _pendingUri;
      if (!stillUnknown && pending != null) {
        _pendingUri = null;
        _navigate(pending);
      }
    });

    // Keep the SignalR connection for /hubs/messaging in sync with the
    // auth session. Connects on authenticated, drops on unauthenticated.
    ref.listenManual<AuthSessionState>(sessionControllerProvider, (_, next) {
      _syncRealtime(next);
    });
  }

  Future<void> _syncRealtime(AuthSessionState session) async {
    final realtime = ref.read(messagingRealtimeServiceProvider);
    final tokenStorage = ref.read(tokenStorageProvider);
    final isAuthed = session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
    if (!isAuthed) {
      await realtime.stop();
      return;
    }
    final token = await tokenStorage.accessToken;
    if (token == null || token.isEmpty) {
      realtime.setAccessToken(null);
      return;
    }
    realtime.setAccessToken(token);
    await realtime.start(hubBaseUrl: ApiConfig.baseUrl, accessToken: token);
  }

  void _listenDeepLinks() {
    // ignore: avoid_print
    print('[OAUTH-DEBUG] _listenDeepLinks: subscribing to uriLinkStream');
    _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (e) {
        // ignore: avoid_print
        print('[OAUTH-DEBUG] uriLinkStream error: $e');
      },
    );
    // Also handle the initial link that launched the app cold.
    _appLinks
        .getInitialLink()
        .then((uri) {
          // ignore: avoid_print
          print('[OAUTH-DEBUG] getInitialLink: $uri');
          if (uri != null) _handleUri(uri);
        })
        .catchError((e) {
          // ignore: avoid_print
          print('[OAUTH-DEBUG] getInitialLink error: $e');
        });
  }

  void _handleUri(Uri uri) {
    // ignore: avoid_print
    print('[OAUTH-DEBUG] _handleUri: $uri scheme=${uri.scheme} host=${uri.host} path=${uri.path} query=${uri.query}');
    // Backend API URLs (e.g. the OAuth callback
    // /v1/social/connect/*/callback) are NOT app routes. They must be handled
    // server-side; if one reaches us (App Links can over-match on the shared
    // domain), ignore it rather than navigating GoRouter to a dead path.
    if (uri.path.startsWith('/v1/')) return;

    // OAuth return from a social-provider connect flow. The backend exchanges
    // the code server-side, then redirects to
    // `stylemint://social-connected?provider=...&status=ok|error`. Hand off to
    // the notifier, which closes the in-app browser and refreshes on success.
    if (uri.scheme == 'stylemint' && uri.host == 'social-connected') {
      final ok = uri.queryParameters['status'] == 'ok';
      // On failure the backend appends `&error=<reason>` (e.g. invalid_grant,
      // provider_unavailable). Pass it through so the reason is logged/surfaced
      // instead of the browser silently closing with no feedback.
      ref
          .read(socialConnectNotifierProvider.notifier)
          .onConnectReturn(
            ok: ok,
            errorCode: uri.queryParameters['error'],
          );
      return;
    }

    // While the session is still bootstrapping, the redirect guard forces every
    // non-splash route to splash — which would discard this link (and any
    // token). Defer it; the session listener replays it once resolved.
    final sessionUnknown = ref
        .read(sessionControllerProvider)
        .maybeWhen(unknown: () => true, orElse: () => false);
    if (sessionUnknown) {
      _pendingUri = uri;
      return;
    }

    _navigate(uri);
  }

  void _navigate(Uri uri) {
    final router = ref.read(appRouterProvider);
    // Convert the incoming deep link to a go_router path.
    //  - https links: the host is the domain, so the route is just `uri.path`
    //    (e.g. https://host/auth/magic -> /auth/magic).
    //  - custom-scheme links: the first path segment lands in `uri.host`, so
    //    rebuild it (e.g. stylemint://auth/magic -> /auth/magic, not /magic).
    final rawPath = uri.scheme == 'stylemint' && uri.host.isNotEmpty
        ? '/${uri.host}${uri.path}'
        : uri.path;
    final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    final query = uri.queryParametersAll.isEmpty
        ? ''
        : '?${uri.queryParameters.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    // ignore: avoid_print
    print('[OAUTH-DEBUG] _navigate: router.go(\'$path$query\')');
    router.go('$path$query');
  }

  @override
  Widget build(BuildContext context) => const StyleMintApp();
}
