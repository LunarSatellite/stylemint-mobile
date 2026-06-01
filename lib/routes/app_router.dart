import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/email_login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/magic_link_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/oauth_callback_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/passkey_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/register_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/otp_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/sign_in_method_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/mfa_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/devices_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/handle_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/blocked_users_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/linked_accounts_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/marketing_consents_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/pause_account_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/follow_creators_discovery_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/cancel_order_screen.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/screens/payment_methods_screen.dart';
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
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/creator_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/screens/reach_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/screens/reel_details_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/import_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/screens/create_draft_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/screens/reel_studio_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/screens/social_connect_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/add_product_wizard_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/screens/vendor_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/screens/brand_studio_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/screens/creator_performance_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/screens/vendor_inquiries_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/screens/matchmaking_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_orders_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/invite_creators_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/vendor_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/vendor_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_session_screen.dart';
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
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/follow_creators_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/onboarding_carousel_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/pick_interests_screen.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/following_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/language_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/notification_prefs_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/about_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/terms_conditions_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/help_center_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/my_tickets_screen.dart';
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
  RouteNames.userTypeSelection,
  RouteNames.rolePicker,
  RouteNames.pickInterests,
  RouteNames.followCreators,
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
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    redirect: (ctx, state) {
      final path = state.matchedLocation;
      final isPublic = _publicPaths.any((p) => path.startsWith(p));
      final isAuthOnly = _authOnlyPaths.any((p) => path.startsWith(p));

      return session.when(
        unknown: () => path == RouteNames.splash ? null : RouteNames.splash,
        authenticated: (_) => isAuthOnly ? RouteNames.home : null,
        unauthenticated: () => isPublic ? null : RouteNames.signInMethod,
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
      GoRoute(
        path: RouteNames.register,
        builder: (ctx, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpScreen(
            phone: extra['phone'] as String,
            otpId: extra['otpId'] as String,
            identifierType: (extra['identifierType'] as String?) ?? 'phone',
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
          return OAuthCallbackScreen(
            provider: provider,
            code: code,
            state: oauthState,
          );
        },
      ),
      GoRoute(
        path: RouteNames.userTypeSelection,
        builder: (ctx, state) => UserTypeSelectionScreen(
          authData: state.extra as AuthResponseDto,
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
        path: RouteNames.rolePicker,
        builder: (ctx, state) => UserTypeSelectionScreen(
          authData: state.extra as AuthResponseDto,
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
      ),
      GoRoute(
        path: RouteNames.creatorDash,
        builder: (ctx, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.socialConnect,
        builder: (ctx, state) => const SocialConnectScreen(),
      ),
      GoRoute(
        path: RouteNames.reelImport,
        builder: (ctx, state) => const ImportReelScreen(),
      ),
      GoRoute(
        path: RouteNames.reelImportTagProducts,
        builder: (ctx, state) => const TagProductsScreen(),
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
        path: RouteNames.partnerships,
        builder: (ctx, state) => const PartnershipsScreen(),
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
