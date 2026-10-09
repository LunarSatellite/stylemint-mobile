import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart' show RemoteMessage;
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/device/push_destination.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/kyc_push.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/scan/domain/style_mint_code.dart';
import 'package:stylemint_mobile_frontend/routes/deep_links.dart';
import 'package:stylemint_mobile_frontend/theme/font_licenses.dart';
import 'core/auth/jwt_roles.dart';
import 'core/network/network_exceptions.dart';
import 'core/utils/format_date.dart';
import 'app.dart';
import 'features/auth/presentation/providers/auth_state_provider.dart';
import 'core/config/api_config.dart';
import 'core/device/device_push_registration.dart';
import 'core/device/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'features/messaging/shared/providers.dart';
import 'features/vendor/orders/presentation/notifiers/vendor_delivery_refresh.dart';
import 'features/creator/social_connect/shared/providers.dart';
import 'features/customer/cart/domain/entities/basket_scenarios.dart';
import 'features/customer/cart/domain/entities/cart.dart';
import 'features/customer/cart/domain/entities/cart_offer.dart';
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
  getBasketOptimization() async =>
      right(const BasketOptimization(insights: []));

  @override
  Future<Either<NetworkExceptions, CartOfferAdvice>> getOfferAdvice() async =>
      right(
        const CartOfferAdvice(
          inControlGroup: false,
          headline: '',
          offers: [],
          fairnessNote: '',
        ),
      );
  @override
  Future<Either<NetworkExceptions, BasketScenarios>> getScenarios({
    double? budget,
    List<String> keepLineIds = const [],
    List<String> excludeProductIds = const [],
  }) async => right(const BasketScenarios(currency: _npr, scenarios: []));

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
  Future<Either<NetworkExceptions, DeliveryChoices>>
  getDeliveryChoices() async => right(
    const DeliveryChoices(
      choices: [
        DeliveryChoice(
          kind: DeliveryChoiceKind.homeDelivery,
          title: 'Home delivery',
          detail: 'Delivered to your selected address.',
          deliveries: 1,
          readyInDays: 2,
          selected: true,
        ),
        DeliveryChoice(
          kind: DeliveryChoiceKind.pickupFromSeller,
          title: 'Pick up from StyleMint',
          detail: 'Collect your order when it is ready.',
          deliveries: 0,
          readyInDays: 1,
          sellerAccountId: 'seller-1',
          sellerName: 'StyleMint',
          selected: false,
        ),
      ],
      emissionsNote: 'Consolidated delivery reduces unnecessary trips.',
      pickupNote: 'Bring your order confirmation when collecting.',
    ),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> selectDeliveryChoice(
    DeliveryChoice choice,
  ) async => right(unit);

  @override
  Future<Either<NetworkExceptions, Unit>> selectPickupLocation({
    required String sellerId,
    required String locationId,
  }) async => right(unit);

  @override
  Future<Either<NetworkExceptions, DeliveryPreference>>
  updateDeliveryPreference(DeliveryPreference preference) async =>
      right(preference);

  @override
  Future<Either<NetworkExceptions, PlaceOrderResult>> placeOrder({
    required String? addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async => right(
    const PlaceOrderResult(
      orderNumber: 'mock-order-001',
      requiresPaymentAction: false,
    ),
  );
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
  // OFL licence texts for the bundled Poppins + Instrument Serif fonts.
  registerFontLicenses();
  // Portrait only: the reel feed, its right-hand rail and the bottom bar are
  // laid out for a tall screen (owner decision, 2026-09-15). The Android
  // manifest and iOS Info.plist lock it before Flutter starts too.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  initTimezone();
  await PushNotificationService.initialise();

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
  runApp(const _SessionScope());
}

/// Owns the app's [ProviderScope] and swaps in a fresh one whenever a signed-in
/// session ends. Logout only resets a handful of notifiers, so every other
/// cached provider (creator studio, feed, social accounts, orders, …) used to
/// keep the previous account's data until the app was closed and reopened.
class _SessionScope extends StatefulWidget {
  const _SessionScope();

  @override
  State<_SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<_SessionScope> {
  int _generation = 0;

  void _restart() {
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    key: ValueKey(_generation),
    child: _AppWithDeepLinks(onSignedOut: _restart),
  );
}

/// Wraps [StyleMintApp] and listens for incoming deep links so that magic-link
/// and OAuth callback URIs are routed to the correct screen.
///
/// Deep-link format:
///   `stylemint://auth/magic?token=<token>`
///   `https://stylemint.voyageritnepal.com/auth/magic?token=<token>`
class _AppWithDeepLinks extends ConsumerStatefulWidget {
  const _AppWithDeepLinks({required this.onSignedOut});

  /// Called once a signed-in session ends, to rebuild the provider graph.
  final VoidCallback onSignedOut;

  @override
  ConsumerState<_AppWithDeepLinks> createState() => _AppWithDeepLinksState();
}

class _AppWithDeepLinksState extends ConsumerState<_AppWithDeepLinks> {
  /// The link that cold-launched the app is handled once per process, so a
  /// provider scope rebuilt after sign-out never replays an old magic link or
  /// OAuth callback.
  static bool _initialLinkHandled = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<RemoteMessage>? _pushTapSubscription;
  StreamSubscription<RemoteMessage>? _pushForegroundSubscription;

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
    _listenPushTaps();
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
      unawaited(_syncPushRegistration(next));
    });

    // Signing out (or the session expiring) starts the next account from a
    // clean provider graph instead of the previous account's cached state.
    ref.listenManual<AuthSessionState>(sessionControllerProvider, (prev, next) {
      final wasSignedIn =
          prev?.maybeWhen(authenticated: (_) => true, orElse: () => false) ??
          false;
      final signedOut = next.maybeWhen(
        unauthenticated: () => true,
        orElse: () => false,
      );
      if (wasSignedIn && signedOut) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.onSignedOut(),
        );
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _pushTapSubscription?.cancel();
    _pushForegroundSubscription?.cancel();
    super.dispose();
  }

  /// Registers this device's push token for the signed-in account, and stops
  /// following token rotations on sign-out.
  ///
  /// Sits alongside the realtime sync because it answers the same question —
  /// "who is signed in on this device" — and because the push token is only
  /// meaningful once there is an account to attach it to. Until this ran, the
  /// token was fetched by the profile screen's toggle and discarded, so the
  /// server had no address for any notification it routed.
  Future<void> _syncPushRegistration(AuthSessionState session) async {
    final registration = ref.read(devicePushRegistrationProvider);
    final isAuthed = session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
    if (isAuthed) {
      await registration.start();
    } else {
      await registration.stop();
    }
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
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (e) {
        // ignore: avoid_print
        print('[OAUTH-DEBUG] uriLinkStream error: $e');
      },
    );
    // Also handle the initial link that launched the app cold.
    if (_initialLinkHandled) return;
    _initialLinkHandled = true;
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

  /// A tapped notification goes through the same door as a deep link.
  ///
  /// Registration was the only half of push that existed: the token reached
  /// the server, so a notification could be delivered and shown, but tapping
  /// it did nothing — there was no listener. These three cases are distinct in
  /// FCM and all three were missing:
  ///
  ///  * tapped while the app was backgrounded -> onMessageOpenedApp
  ///  * tapped from terminated -> getInitialMessage, which reads once
  ///  * arriving in the foreground -> the OS shows nothing on iOS unless asked
  ///
  /// [_handleUri] already resolves StyleMint codes, storefront links and plain
  /// routes, and defers anything that arrives before the session does, so a
  /// cold launch from a notification lands correctly rather than on splash.
  void _listenPushTaps() {
    unawaited(PushNotificationService.enableForegroundPresentation());

    _pushTapSubscription = PushNotificationService.onMessageOpenedApp.listen(
      _handlePushMessage,
    );

    _pushForegroundSubscription = PushNotificationService.onMessage.listen(
      _handleForegroundPush,
    );

    // One-shot: this is the notification that launched the app, and asking
    // twice returns null.
    unawaited(
      PushNotificationService.initialMessage().then((message) {
        if (message != null) _handlePushMessage(message);
      }),
    );
  }

  /// Pulls a destination out of a notification payload.
  ///
  /// The server's FCM data keys are not documented in this repo — the
  /// notifications contract here covers the inbox API, not the push payload —
  /// so this accepts the forms a backend plausibly sends and ignores anything
  /// it does not recognise rather than guessing a route. A payload with no
  /// destination still opens the app, which is the sensible default for a
  /// notification that is only telling the user something.
  void _handlePushMessage(RemoteMessage message) {
    // A KYC decision carries a `type` and a status, no link: refresh what
    // depends on it and open the verification screen, which re-reads it.
    final kyc = KycDecidedPush.fromData(message.data);
    if (kyc != null) {
      _refreshAfterKycDecision();
      _handleUri(Uri.parse('stylemint:/${kyc.route}'));
      return;
    }
    // Delivery notifications carry a `type`, not a link — the contract pins
    // that — so they are routed by type before the generic key guess runs.
    final delivery = DeliveryPushEvent.fromData(message.data);
    if (delivery != null) {
      ref.read(deliveryPushBusProvider).publish(delivery);
      refreshVendorOrdersOnDelivered(ref, delivery);
      unawaited(
        _deliveryRoute(delivery).then((route) {
          // Through _handleUri rather than straight to the router, so a cold
          // launch from the notification is deferred until the session is
          // known.
          if (route != null && mounted) {
            _handleUri(Uri.parse('stylemint:/$route'));
          }
        }),
      );
      return;
    }
    final uri = pushDestinationUri(message.data);
    if (uri == null) return;
    _handleUri(uri);
  }

  /// A KYC review was decided: the buyer's EMI eligibility and the
  /// verification record are stale, wherever they are on screen.
  void _refreshAfterKycDecision() {
    ref
      ..invalidate(emiEligibilityProvider)
      ..invalidate(customerKycNotifierProvider);
  }

  /// An in-app banner with a way to [route], for a push that arrived while
  /// the app is open — FCM draws nothing itself in the foreground on Android.
  void _showPushBanner(String text, String route) {
    final router = ref.read(appRouterProvider);
    final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    final messenger = ScaffoldMessenger.maybeOf(navigatorContext);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(text),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => router.push(route),
          ),
        ),
      );
  }

  /// Where a tapped delivery notification goes.
  ///
  /// Only `delivery.delivered` needs thought: the vendor and the rider get it
  /// with the same payload. Whichever side of the app is on screen decides;
  /// failing that, an account with the vendor role is taken to the order.
  Future<String?> _deliveryRoute(DeliveryPushEvent event) async {
    if (event.type != DeliveryPushType.delivered) return event.route;
    final location = ref
        .read(appRouterProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    if (location.startsWith(RouteNames.courier)) {
      return event.routeFor(vendor: false);
    }
    if (location.startsWith('/vendor')) return event.routeFor(vendor: true);
    final token = await ref.read(tokenStorageProvider).accessToken;
    final roles = rolesFromJwt(token);
    return event.routeFor(vendor: roles.contains('vendor'));
  }

  /// A notification that arrived while the app is open.
  ///
  /// Delivery ones are time-critical — a request is open for minutes, and a
  /// vendor is waiting on the rider — so the screens showing them refresh at
  /// once via [DeliveryPushBus], and anything not on screen gets an in-app
  /// banner with a way to it. FCM draws nothing itself in the foreground on
  /// Android, so without this the rider would learn of it on the next poll.
  Future<void> _handleForegroundPush(RemoteMessage message) async {
    final kyc = KycDecidedPush.fromData(message.data);
    if (kyc != null) {
      _refreshAfterKycDecision();
      _showPushBanner(
        message.notification?.title ??
            message.notification?.body ??
            kyc.message,
        kyc.route,
      );
      return;
    }
    final delivery = DeliveryPushEvent.fromData(message.data);
    if (delivery == null) return;
    ref.read(deliveryPushBusProvider).publish(delivery);
    refreshVendorOrdersOnDelivered(ref, delivery);

    final route = await _deliveryRoute(delivery);
    if (!mounted) return;
    final router = ref.read(appRouterProvider);
    final navigatorContext = router.routerDelegate.navigatorKey.currentContext;
    if (route == null || navigatorContext == null) return;
    final messenger = ScaffoldMessenger.maybeOf(navigatorContext);
    if (messenger == null) return;

    final text =
        message.notification?.title ??
        message.notification?.body ??
        switch (delivery.type) {
          DeliveryPushType.request => 'A vendor near you needs a rider',
          DeliveryPushType.interest => 'A rider is ready to take your parcel',
          DeliveryPushType.selected => "You've got the delivery",
          DeliveryPushType.notSelected => 'Another rider was chosen',
          DeliveryPushType.confirmRequest =>
            'Your parcel is at the door — confirm delivery',
          DeliveryPushType.delivered => 'Delivered — the recipient confirmed',
        };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Text(text),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => router.go(route),
          ),
        ),
      );
  }

  void _handleUri(Uri uri) {
    // ignore: avoid_print
    // Never log the query: OAuth returns carry a one-time code and state.
    print(
      '[OAUTH-DEBUG] _handleUri: scheme=${uri.scheme} host=${uri.host} path=${uri.path} queryKeys=${uri.queryParameters.keys.toList()}',
    );
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
    // StyleMint codes — stylemint://c/{code} and
    // https://<StyleMint host>/c/{code}, from printed QR codes, NFC tags and
    // shared links — open the resolve screen. A tag's via=nfc is kept;
    // anything else counts as a link.
    final styleMintCode = StyleMintCode.parse(uri.toString());
    if (styleMintCode is StyleMintShortCode) {
      router.go(styleMintCode.route);
      return;
    }
    // Shared brand and creator storefront links — the web pages
    // (https://<StyleMint host>/brands/{id}, /creator-profile/{id}) and the
    // stylemint:// forms their app-dock buttons use — open the storefront
    // in-app. An id that is not a GUID lands on home instead of a storefront
    // that can never load.
    final storefront = styleMintStorefrontRoute(uri.toString());
    if (storefront != null) {
      router.go(storefront);
      return;
    }
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
    print(
      '[OAUTH-DEBUG] _navigate: router.go(\'$path\') queryKeys=${uri.queryParameters.keys.toList()}',
    );
    router.go('$path$query');
  }

  @override
  Widget build(BuildContext context) => const StyleMintApp();
}
