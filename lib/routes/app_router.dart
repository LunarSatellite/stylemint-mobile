import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/blocked_users_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/devices_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/email_login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/handle_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/linked_accounts_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/magic_link_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/marketing_consents_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/mfa_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/oauth_callback_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/otp_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/passkey_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/pause_account_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/sign_in_method_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/full_analytics_report_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/reel_detail_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_approved_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_rejected_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_social_media_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_submitted_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_under_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/creator_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/top_reels_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/active_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brands_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/screens/reach_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/import_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/preview_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/screens/create_draft_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/screens/reel_studio_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/screens/reel_details_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/screens/social_connect_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/support/presentation/screens/creator_contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/follow_creators_discovery_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/cancel_order_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/track_orders_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/screens/add_card_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/screens/payment_methods_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/presentation/screens/customer_shell_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reel_comments_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reels_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/screens/product_reviews_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/screens/saved_items_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/add_edit_address_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/shipping_addresses_screen.dart';
import 'package:stylemint_mobile_frontend/features/notifications/presentation/screens/recent_activity_screen.dart'
    as notifications_activity;
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/follow_brands_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/follow_creators_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/onboarding_carousel_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/pick_interests_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/screens/payment_methods_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/following_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/presentation/qr_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/about_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/language_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/notification_prefs_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/terms_conditions_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_session_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_list_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/scan_invite_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/create_post_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/friend_feed_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/presentation/screens/friends_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/screens/group_cart_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/screens/group_cart_list_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/presentation/screens/group_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/presentation/screens/groups_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/screens/recommendation_list_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/screens/recommendation_thread_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/stories_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_viewer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/screens/send_tip_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/screens/tips_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/help_center_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/my_tickets_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/add_product_wizard_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_approved_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_rejected_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_step2_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_step3_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_step4_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_step5_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_step6_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_submitted_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_under_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/screens/brand_studio_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_performance_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/screens/recent_activity_screen.dart'
as vendor_dashboard_activity;
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/add_bank_account_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/all_payout_history_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/bank_verification_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/change_payment_method_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/statement_details_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/screens/vendor_inquiries_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/screens/matchmaking_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/order_waiting_tracking_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/orders_ready_to_ship_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/pending_customer_inquiries_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_orders_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/adjust_commission_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/creator_partnership_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/invite_creators_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/message_creator_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/send_partnership_request_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/vendor_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/top_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/vendor_products_screen.dart';

import 'route_names.dart';

part 'app_router.g.dart';

const _publicPaths = {
  RouteNames.splash,
  RouteNames.onboarding,
  RouteNames.signInMethod,
  RouteNames.register,
  RouteNames.login,
  RouteNames.email,
  RouteNames.passkey,
  RouteNames.passkeyFace,
  RouteNames.passkeyFingerprint,
  RouteNames.otp,
  RouteNames.magicLink,
  RouteNames.socialLogin,
  RouteNames.oauthCallback,
  RouteNames.userTypeSelection,
  RouteNames.rolePicker,
  RouteNames.pickInterests,
  RouteNames.followCreators,
  RouteNames.creatorApply,
  RouteNames.creatorApplySocial,
  RouteNames.creatorApplyReview,
  RouteNames.creatorApplySubmitted,
  RouteNames.followBrands,
  RouteNames.creatorApplyUnderReview,
  RouteNames.creatorApplyApproved,
  RouteNames.creatorApplyRejected,
  RouteNames.creatorSupportContact,
  // Browse-friendly paths — accessible without auth
  RouteNames.home,
  RouteNames.search,
  RouteNames.reelsFeed,
  RouteNames.reelDetail,
  RouteNames.orders,
  RouteNames.orderDetail,
  RouteNames.profile,
  RouteNames.productDetail,
  RouteNames.productReviews,
  // Settings/support readable without auth
  RouteNames.settings,
  RouteNames.settingsPrivacy,
  RouteNames.settingsTerms,
  RouteNames.support,
  // Social browsing
  RouteNames.feed,
  RouteNames.stories,
  RouteNames.storyViewer,
  RouteNames.groups,
  RouteNames.groupsDetail,
  RouteNames.recommendations,
  RouteNames.recommendationsThread,
  RouteNames.dropPartiesList,
};

const _authOnlyPaths = {
  RouteNames.signInMethod,
  RouteNames.login,
  RouteNames.email,
  RouteNames.otp,
  RouteNames.magicLink,
};

@riverpod
GoRouter appRouter(Ref ref) {
  // The router is built ONCE. We do NOT `ref.watch` the session here — that
  // would recreate the whole GoRouter on every login/logout and reset it to
  // `initialLocation` (splash), stranding the user there after sign-in. Instead
  // a refreshListenable re-runs `redirect` on session changes, and the redirect
  // reads the current session via `ref.read`.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<AuthSessionState>(
    sessionControllerProvider,
    (_, __) => refresh.value++,
  );

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (ctx, state) {
      final session = ref.read(sessionControllerProvider);
      final path = state.matchedLocation;
      final isPublic = _publicPaths.any((p) => path.startsWith(p));
      final isAuthOnly = _authOnlyPaths.any((p) => path.startsWith(p));
      final atSplash = path == RouteNames.splash;

      // The redirect OWNS splash routing: once the session resolves, send the
      // user off splash. Splash itself only kicks off bootstrap().
      return session.when(
        unknown: () => atSplash ? null : RouteNames.splash,
        authenticated: (_) =>
            (atSplash || isAuthOnly) ? RouteNames.home : null,
        unauthenticated: () => atSplash
            ? RouteNames.userTypeSelection
            : (isPublic ? null : RouteNames.signInMethod),
      );
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (ctx, state) => const OnboardingCarouselScreen(),
      ),
      GoRoute(
        path: RouteNames.signInMethod,
        builder: (ctx, state) => const SignInMethodSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.email,
        builder: (ctx, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: RouteNames.passkey,
        builder: (ctx, state) =>
            const PasskeySetupScreen(type: PasskeyType.face),
      ),
      GoRoute(
        path: RouteNames.passkeyFace,
        builder: (ctx, state) =>
            const PasskeySetupScreen(type: PasskeyType.face),
      ),
      GoRoute(
        path: RouteNames.passkeyFingerprint,
        builder: (ctx, state) =>
            const PasskeySetupScreen(type: PasskeyType.fingerprint),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      // Legacy multi-step registration is retired in favour of smart-start OTP
      // (an unknown email/phone provisions the account on verify). Any nav to
      // /register now lands on the smart-start email entry. RegisterScreen is
      // kept as deprecated dead code for reference / rollback.
      GoRoute(
        path: RouteNames.register,
        redirect: (ctx, state) => RouteNames.email,
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpScreen(
            phone: extra['phone'] as String,
            otpId: extra['otpId'] as String,
            identifierType: (extra['identifierType'] as String?) ?? 'phone',
            isNewAccount: (extra['isNewAccount'] as bool?) ?? false,
          );
        },
      ),
      GoRoute(
        path: RouteNames.magicLink,
        builder: (ctx, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return MagicLinkScreen(token: token);
        },
      ),
      GoRoute(
        path: RouteNames.socialLogin,
        builder: (ctx, state) {
          final provider = state.pathParameters['provider'] ?? '';
          final code = state.uri.queryParameters['code'] ?? '';
          final oauthState = state.uri.queryParameters['state'] ?? '';
          final error = state.uri.queryParameters['error'];
          return OAuthCallbackScreen(
            provider: provider,
            code: code,
            state: oauthState,
            error: error,
          );
        },
      ),
      // Contract OAuth redirect deep link (no provider in the path; the server
      // resolves the account from the CSRF state).
      GoRoute(
        path: RouteNames.oauthCallback,
        builder: (ctx, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          final oauthState = state.uri.queryParameters['state'] ?? '';
          final error = state.uri.queryParameters['error'];
          return OAuthCallbackScreen(
            code: code,
            state: oauthState,
            error: error,
          );
        },
      ),
      GoRoute(
        path: RouteNames.userTypeSelection,
        builder: (ctx, state) => UserTypeSelectionScreen(
          isNewAccount: state.uri.queryParameters['new'] == 'true',
        ),
      ),
      GoRoute(
        path: RouteNames.pickInterests,
        builder: (ctx, state) => const PickInterestsScreen(),
      ),
      GoRoute(
        path: RouteNames.followCreators,
        builder: (ctx, state) => const FollowCreatorsScreen(),
      ),
      GoRoute(
        path: RouteNames.followBrands,
        builder: (ctx, state) => const FollowBrandsScreen(),
      ),
      GoRoute(
        path: RouteNames.rolePicker,
        builder: (ctx, state) => const UserTypeSelectionScreen(
          // "Manage / add a role" entry — always show, never auto-skip.
          skipIfOnboarded: false,
        ),
      ),

      // Cart
      GoRoute(
        path: RouteNames.cart,
        builder: (ctx, state) => const CartScreen(),
      ),

      // Checkout
      GoRoute(
        path: RouteNames.checkout,
        builder: (ctx, state) => const CheckoutScreen(),
      ),

      // Order success
      GoRoute(
        path: RouteNames.orderSuccess,
        builder: (ctx, state) => OrderSuccessScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),

      // Product Detail
      GoRoute(
        path: RouteNames.productDetail,
        builder: (ctx, state) => ProductDetailScreen(
          productId: state.pathParameters['productId']!,
        ),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.productDetail, RouteNames.productReviews),
            builder: (ctx, state) => ProductReviewsScreen(
              productId: state.pathParameters['productId']!,
            ),
          ),
        ],
      ),

      // Order Detail
      GoRoute(
        path: RouteNames.orderDetail,
        builder: (ctx, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.orderDetail, RouteNames.orderCancel),
            builder: (ctx, state) => CancelOrderScreen(
              orderId: state.pathParameters['orderId']!,
              order: state.extra is OrderDetail
                  ? state.extra! as OrderDetail
                  : null,
            ),
          ),
        ],
      ),

      // Discover creators (follow)
      GoRoute(
        path: RouteNames.discoverCreators,
        builder: (ctx, state) => const FollowCreatorsDiscoveryScreen(),
      ),

      // Reel comments
      GoRoute(
        path: RouteNames.reelComments,
        builder: (ctx, state) => ReelCommentsScreen(
          reelId: state.pathParameters['reelId']!,
        ),
      ),

      // Saved Items
      GoRoute(
        path: RouteNames.savedItems,
        builder: (ctx, state) => const SavedItemsScreen(),
      ),

      // Shipping Addresses
      GoRoute(
        path: RouteNames.shippingAddresses,
        builder: (ctx, state) => const ShippingAddressesScreen(),
      ),
      GoRoute(
        path: RouteNames.shippingAddEdit,
        builder: (ctx, state) => AddEditAddressScreen(
          address: state.extra
              is ShippingAddress
              ? state.extra as ShippingAddress
              : null,
        ),
      ),

      // Payment Methods
      GoRoute(
        path: RouteNames.paymentMethods,
        builder: (ctx, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: RouteNames.paymentAddCard,
        builder: (ctx, state) => const AddCardScreen(),
      ),

      // Creator
      GoRoute(
        path: RouteNames.creatorHome,
        builder: (ctx, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorApply,
        builder: (ctx, state) => const CreatorApplyScreen(),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.creatorApply, RouteNames.creatorApplySocial),
            builder: (ctx, state) => const CreatorSocialMediaScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.creatorApply, RouteNames.creatorApplyReview),
            builder: (ctx, state) => const CreatorReviewScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.creatorApply, RouteNames.creatorApplySubmitted),
            builder: (ctx, state) => const CreatorSubmittedScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.creatorApply, RouteNames.creatorApplyUnderReview),
            builder: (ctx, state) => const CreatorUnderReviewScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.creatorApply, RouteNames.creatorApplyApproved),
            builder: (ctx, state) => const CreatorApprovedScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.creatorApply, RouteNames.creatorApplyRejected),
            builder: (ctx, state) => const CreatorRejectedScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.creatorSupportContact,
        builder: (ctx, state) => const CreatorContactSupportScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorDash,
        builder: (ctx, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorTopReels,
        builder: (ctx, state) => const TopReelsScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorActivity,
        builder: (ctx, state) =>
            const notifications_activity.RecentActivityScreen(),
      ),
      GoRoute(
        path: RouteNames.socialConnect,
        builder: (ctx, state) => SocialConnectScreen(
          isOnboarding: state.uri.queryParameters['onboarding'] == 'true',
        ),
      ),
      GoRoute(
        path: RouteNames.reelImport,
        builder: (ctx, state) => const ImportReelScreen(),
      ),
      GoRoute(
        path: RouteNames.reelImportPreview,
        builder: (ctx, state) {
          final extra = state.extra! as Map<String, dynamic>;
          return PreviewReelScreen(
            url: extra['url'] as String,
            platform: extra['platform'] as SocialPlatform,
          );
        },
      ),
      GoRoute(
        path: RouteNames.reelImportTagProducts,
        builder: (ctx, state) => const TagProductsScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorAnalytics,
        builder: (ctx, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorReelAnalyticsDetail,
        builder: (ctx, state) => const ReelDetailAnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorFullAnalyticsReport,
        builder: (ctx, state) => const FullAnalyticsReportScreen(),
      ),
      GoRoute(
        path: RouteNames.reelStudio,
        builder: (ctx, state) => const ReelStudioScreen(),
      ),
      GoRoute(
        path: RouteNames.reelStudioCreateDraft,
        builder: (ctx, state) => const CreateDraftScreen(),
      ),
      GoRoute(
        path: RouteNames.earnings,
        builder: (ctx, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: RouteNames.earningsPayout,
        builder: (ctx, state) => const PayoutScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorPaymentMethods,
        builder: (ctx, state) =>
            const PayoutMethodsScreen(role: PayeeKind.creator),
      ),
      GoRoute(
        path: RouteNames.creatorReelDetail,
        builder: (ctx, state) => ReelDetailsScreen(
          reelId: state.pathParameters['reelId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.creatorProfile,
        builder: (ctx, state) {
          final accountId = state.pathParameters['accountId']!;
          final extra = state.extra is CreatorProfileArgs
              ? state.extra! as CreatorProfileArgs
              : CreatorProfileArgs(
                  accountId: accountId, displayName: '', handle: '');
          return CreatorProfileScreen(args: extra);
        },
      ),
      GoRoute(
        path: RouteNames.partnerships,
        builder: (ctx, state) => const BrandsScreen(),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.partnerships, RouteNames.brandDetail),
            builder: (ctx, state) => BrandDetailScreen(
              partnershipId: state.pathParameters['partnershipId']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.activePartnerships,
        builder: (ctx, state) => const ActivePartnershipsScreen(),
      ),
      GoRoute(
        path: RouteNames.brandInfo,
        builder: (ctx, state) =>
            BrandInfoScreen(data: state.extra! as BrandInfoData),
      ),
      GoRoute(
        path: RouteNames.reach,
        builder: (ctx, state) => const ReachScreen(),
      ),

      // Vendor
      GoRoute(
        path: RouteNames.vendorHome,
        builder: (ctx, state) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorApply,
        builder: (ctx, state) => const VendorApplyScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorApplyStep2,
        builder: (ctx, state) => const VendorApplyStep2Screen(),
      ),
      GoRoute(
        path: RouteNames.vendorApplyStep3,
        builder: (ctx, state) => const VendorApplyStep3Screen(),
      ),
      GoRoute(
        path: RouteNames.vendorApplyStep4,
        builder: (ctx, state) => const VendorApplyStep4Screen(),
      ),
      GoRoute(
        path: RouteNames.vendorApplyStep5,
        builder: (ctx, state) => const VendorApplyStep5Screen(),
      ),
      GoRoute(
        path: RouteNames.vendorApplyStep6,
        builder: (ctx, state) => const VendorApplyStep6Screen(),
      ),
      GoRoute(
        path: RouteNames.vendorApplySubmitted,
        builder: (ctx, state) => VendorApplySubmittedScreen(
          applicationId: state.uri.queryParameters['applicationId'],
          submittedAt: state.uri.queryParameters['submittedAt'],
          userEmail: state.uri.queryParameters['userEmail'],
        ),
      ),
      GoRoute(
        path: RouteNames.vendorApplyRejected,
        builder: (ctx, state) => VendorApplyRejectedScreen(
          rejectionReason: state.extra as String?,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorApplyUnderReview,
        builder: (ctx, state) => VendorApplyUnderReviewScreen(
          applicationId: state.uri.queryParameters['applicationId'],
          userEmail: state.uri.queryParameters['userEmail'],
        ),
      ),
      GoRoute(
        path: RouteNames.vendorApplyApproved,
        builder: (ctx, state) => const VendorApplyApprovedScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorDash,
        builder: (ctx, state) => const VendorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.addProduct,
        builder: (ctx, state) => const AddProductWizardScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorProducts,
        builder: (ctx, state) => const VendorProductsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorOrders,
        builder: (ctx, state) => const VendorOrdersScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorOrdersReadyToShip,
        builder: (ctx, state) => const OrdersReadyToShipScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorOrdersWaitingTracking,
        builder: (ctx, state) => const OrderWaitingTrackingScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorPendingInquiries,
        builder: (ctx, state) => const PendingCustomerInquiriesScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorCreatorPartnershipRequests,
        builder: (ctx, state) => const CreatorPartnershipRequestsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorTopProducts,
        builder: (ctx, state) => const TopProductsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorRecentActivity,
        builder: (ctx, state) =>
            const vendor_dashboard_activity.RecentActivityScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorOrderDetail,
        builder: (ctx, state) => VendorOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorPartnerships,
        builder: (ctx, state) => const VendorPartnershipsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorSendPartnershipRequest,
        builder: (ctx, state) => const SendPartnershipRequestScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorPartnershipsInvite,
        builder: (ctx, state) => InviteCreatorsScreen(
          campaignId: state.pathParameters['campaignId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorBrandStudio,
        builder: (ctx, state) => const BrandStudioScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorMatchmaking,
        builder: (ctx, state) => const MatchmakingScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorEarnings,
        builder: (ctx, state) => const VendorEarningsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorEarningsPayout,
        builder: (ctx, state) => const VendorPayoutScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorPayoutHistory,
        builder: (ctx, state) => const AllPayoutHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorStatementDetails,
        builder: (ctx, state) => StatementDetailsScreen(
          item: state.extra as VendorPayoutItem,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorChangePaymentMethod,
        builder: (ctx, state) => const ChangePaymentMethodScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorAddBankAccount,
        builder: (ctx, state) => const AddBankAccountScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorBankVerification,
        builder: (ctx, state) => const BankVerificationScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorPaymentMethods,
        builder: (ctx, state) =>
            const PayoutMethodsScreen(role: PayeeKind.vendor),
      ),
      GoRoute(
        path: RouteNames.vendorInquiries,
        builder: (ctx, state) => const VendorInquiriesScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorCreatorPerformance,
        builder: (ctx, state) => const CreatorPerformanceScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorCreatorAnalytics,
        builder: (ctx, state) => CreatorAnalyticsScreen(
          args: state.extra as CreatorAnalyticsArgs,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorMessageCreator,
        builder: (ctx, state) => MessageCreatorScreen(
          args: state.extra as MessageCreatorArgs,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorAdjustCommission,
        builder: (ctx, state) => AdjustCommissionScreen(
          args: state.extra as AdjustCommissionArgs,
        ),
      ),

      // Social
      GoRoute(
        path: RouteNames.feed,
        builder: (ctx, state) => const FriendFeedScreen(),
      ),
      GoRoute(
        path: RouteNames.feedCreatePost,
        builder: (ctx, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: RouteNames.stories,
        builder: (ctx, state) => const StoriesScreen(),
      ),
      GoRoute(
        path: RouteNames.storyViewer,
        builder: (ctx, state) => StoryViewerScreen(
          userId: state.pathParameters['userId']!,
          stories: const [],
        ),
      ),
      GoRoute(
        path: RouteNames.recommendations,
        builder: (ctx, state) => const RecommendationListScreen(),
      ),
      GoRoute(
        path: RouteNames.recommendationsThread,
        builder: (ctx, state) => RecommendationThreadScreen(
          requestId: state.pathParameters['requestId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.groups,
        builder: (ctx, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: RouteNames.groupsDetail,
        builder: (ctx, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.friends,
        builder: (ctx, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: RouteNames.dropPartiesList,
        builder: (ctx, state) => const DropPartyListScreen(),
      ),
      GoRoute(
        path: RouteNames.dropParty,
        builder: (ctx, state) => DropPartyDetailScreen(
          partyId: state.pathParameters['dropPartyId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.dropPartyScan,
        builder: (ctx, state) => const ScanInviteScreen(),
      ),
      GoRoute(
        path: RouteNames.groupCartsList,
        builder: (ctx, state) => const GroupCartListScreen(),
      ),
      GoRoute(
        path: RouteNames.groupCart,
        builder: (ctx, state) => GroupCartDetailScreen(
          cartId: state.pathParameters['groupCartId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.coWatch,
        builder: (ctx, state) => const CoWatchScreen(),
      ),
      GoRoute(
        path: RouteNames.coWatchSession,
        builder: (ctx, state) => CoWatchSessionScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.tips,
        builder: (ctx, state) => const TipsScreen(),
      ),
      GoRoute(
        path: RouteNames.tipsSend,
        builder: (ctx, state) => const SendTipScreen(),
      ),

      // Profile sub-routes
      GoRoute(
        path: RouteNames.profileEdit,
        builder: (ctx, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.profileFollowing,
        builder: (ctx, state) => const FollowingScreen(),
      ),
      GoRoute(
        path: RouteNames.qrScan,
        builder: (ctx, state) => const QrScanScreen(),
      ),

      // Settings
      GoRoute(
        path: RouteNames.settings,
        builder: (ctx, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.settings, RouteNames.settingsNotifications),
            builder: (ctx, state) => const NotificationPrefsScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.settings, RouteNames.settingsLanguage),
            builder: (ctx, state) => const LanguageScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.settings, RouteNames.settingsPrivacy),
            builder: (ctx, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.settings, RouteNames.settingsTerms),
            builder: (ctx, state) => const TermsConditionsScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.settings, RouteNames.settingsAbout),
            builder: (ctx, state) => const AboutScreen(),
          ),
        ],
      ),

      // Support
      GoRoute(
        path: RouteNames.support,
        builder: (ctx, state) => const HelpCenterScreen(),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.support, RouteNames.supportContact),
            builder: (ctx, state) => const ContactSupportScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.support, RouteNames.supportTickets),
            builder: (ctx, state) => const MyTicketsScreen(),
          ),
        ],
      ),

      // Auth account management
      GoRoute(
        path: RouteNames.mfaSetup,
        builder: (ctx, state) => const MfaSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.devices,
        builder: (ctx, state) => const DevicesScreen(),
      ),
      GoRoute(
        path: RouteNames.handleSetup,
        builder: (ctx, state) => const HandleSetupScreen(),
      ),
      GoRoute(
        path: RouteNames.blockedUsers,
        builder: (ctx, state) => const BlockedUsersScreen(),
      ),
      GoRoute(
        path: RouteNames.linkedAccounts,
        builder: (ctx, state) => const LinkedAccountsScreen(),
      ),
      GoRoute(
        path: RouteNames.marketingConsents,
        builder: (ctx, state) => const MarketingConsentsScreen(),
      ),
      GoRoute(
        path: RouteNames.pauseAccount,
        builder: (ctx, state) => const PauseAccountScreen(),
      ),

      // Customer dashboard
      StatefulShellRoute.indexedStack(
        builder: (ctx, state, navigationShell) =>
            CustomerShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.home,
              builder: (ctx, state) => const ReelsFeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.search,
              builder: (ctx, state) => const SearchScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.orders,
              builder: (ctx, state) => const TrackOrdersScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (ctx, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}

String _subPath(String parent, String full) {
  final prefix = parent.endsWith('/') ? parent : '$parent/';
  return full.startsWith(prefix) ? full.substring(prefix.length) : full;
}
