import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/notifiers/role_notifier.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/shared/providers.dart'
    show roleNotifierProvider;
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/account_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/blocked_users_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/devices_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/email_login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/handle_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/linked_accounts_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/complete_name_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/magic_link_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/marketing_consents_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/mfa_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/oauth_callback_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/otp_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/passkey_setup_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/pause_account_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/sessions_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/sign_in_method_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/user_type_selection_screen.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/screens/code_resolve_screen.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/screens/my_style_mint_code_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/full_analytics_report_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/screens/reel_detail_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_activate_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_approved_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_rejected_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_submitted_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/screens/creator_under_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/creator_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/presentation/screens/creator_search_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/screens/top_reels_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/add_payment_method_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/bank_verification_screen.dart'
    as creator_verify;
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/all_payout_history_screen.dart'
    as creator_history;
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/screens/payout_invoice_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/active_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_messaging_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brands_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/rate_card_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/screens/reach_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/import_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/preview_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/reel_published_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/review_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/screens/create_draft_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/screens/reel_studio_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/screens/reel_details_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/screens/social_connect_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/support/presentation/screens/creator_contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/screens/assistant_conversation_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/screens/assistant_conversations_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_scenarios_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/screens/evidence_answer_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/follow_creators_discovery_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/mission_shopping_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/screens/mission_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/screens/missions_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/outcome_contracts/presentation/outcome_contracts_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/lifecycle/presentation/lifecycle_steward_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/screens/connected_assistants_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_negotiations/presentation/agent_negotiations_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/in_store_locations.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/screens/in_store_product_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/screens/in_store_store_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/screens/brand_storefront_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/collection_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/product_listing_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/buy_it_again_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/cancel_order_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/delivery_recovery_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/fedex_tracking_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/my_returns_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_invoice_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/refill_plan_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/replenishment_rules_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/return_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/track_orders_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/screens/add_card_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/presentation/screens/payment_methods_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/presentation/screens/customer_shell_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/presentation/widgets/swipeable_branch_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reel_comments_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/screens/reel_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/screens/product_reviews_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/screens/saved_items_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/add_edit_address_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/shipping_addresses_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/screens/view_address_screen.dart';
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
import 'package:stylemint_mobile_frontend/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/following_screen.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/screens/profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/qr_login/presentation/qr_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/about_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/language_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/memory_vault_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/notification_prefs_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/privacy_policy_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/settings_screen.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/terms_conditions_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_session_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/community/presentation/screens/community_hub_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_edit_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/screens/creator_profile_gate.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/screens/change_password_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/edit_category_niche_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/upgrade_subscription_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/edit_profile_badges_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/edit_profile_tags_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/profile_settings_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_list_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/scan_invite_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/screens/barcode_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/screens/screenshot_search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/screens/voice_search_screen.dart';
import 'package:stylemint_mobile_frontend/features/scan/presentation/screens/style_mint_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/screens/live_room_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/screens/live_sessions_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/presentation/screens/referrals_screen.dart';
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
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/help_article_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/help_center_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/help_topic_screen.dart';
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
import 'package:stylemint_mobile_frontend/features/vendor/profile/presentation/screens/vendor_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/add_bank_account_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/all_payout_history_screen.dart'
    as vendor_history;
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/bank_verification_screen.dart'
    as vendor_verify;
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/change_payment_method_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/statement_details_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_earnings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/vendor_payout_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/screens/product_in_store_codes_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/screens/vendor_inquiries_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/screens/matchmaking_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/order_waiting_tracking_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/orders_ready_to_ship_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/pending_customer_inquiries_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_orders_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/adjust_commission_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/campaign_brief_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/campaign_workspace_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/campaign_briefs_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/create_campaign_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/creator_partnership_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/invite_creators_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/message_creator_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/send_partnership_request_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/vendor_partnerships_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/presentation/screens/vendor_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/presentation/screens/vendor_demand_signals_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/presentation/screens/vendor_sponsored_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/presentation/screens/vendor_store_actions_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/screens/vendor_store_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/screens/vendor_store_form_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/screens/vendor_stores_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/support/vendor_contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/product_analytics_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/top_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/edit_product_images_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/update_product_stock_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/screens/vendor_products_screen.dart';

import 'route_names.dart';
import 'route_path_match.dart';

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
  RouteNames.completeName,
  RouteNames.socialLogin,
  RouteNames.oauthCallback,
  RouteNames.oauthCallbackAlias,
  RouteNames.userTypeSelection,
  RouteNames.rolePicker,
  RouteNames.pickInterests,
  RouteNames.followCreators,
  RouteNames.creatorApply,
  RouteNames.creatorApplySubmitted,
  RouteNames.followBrands,
  RouteNames.creatorApplyUnderReview,
  RouteNames.creatorApplyApproved,
  RouteNames.creatorApplyRejected,
  RouteNames.vendorApply,
  RouteNames.vendorApplySubmitted,
  RouteNames.vendorApplyUnderReview,
  RouteNames.vendorApplyApproved,
  RouteNames.vendorApplyRejected,
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
  // Public creator storefronts browse signed out; follow and save ask to sign in.
  RouteNames.creatorProfile,
  // Brand storefronts browse signed out; follow asks to sign in.
  RouteNames.brandStorefront,
  // Mall listing and collections browse signed out.
  RouteNames.productListing,
  RouteNames.collectionRoot,
  // Scanning is open to guests; login and drop party codes ask to sign in.
  RouteNames.scan,
  // StyleMint codes (printed QR, NFC tags, /c/ links) and the in-store pages
  // they open work signed out.
  RouteNames.styleMintCodeRoot,
  RouteNames.inStoreRoot,
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

// Vendor management screens (dashboard, orders, products, earnings, ...) all
// live under /vendor/ but are distinct from the /vendor/apply status flow,
// which owns routing an unapproved vendor to the correct pending/rejected/
// under-review screen. Gate the former on approval so a vendor can't reach
// the dashboard by deep-linking or by holding a stale nav stack from before
// their application was reviewed.
String? _vendorManagementRedirect(Ref ref, String path) {
  final isVendorManagementRoute =
      path.startsWith('/vendor/') && !path.startsWith(RouteNames.vendorApply);
  if (!isVendorManagementRoute) return null;

  // Source of truth is identity.role_profiles (the same check the Profile
  // screen and UserTypeSelectionScreen use to decide "Vendor Dashboard" vs
  // "Sell on Style Mint"/apply-status routing) — NOT vendorApplyNotifierProvider,
  // which tracks the KYC application separately and is a different cache that
  // may never have been populated this session. Confirmed live: a caller that
  // had already verified an active vendor role_profile and pushed
  // RouteNames.vendorHome was bounced straight back to the apply form here,
  // because this redirect's own (unrelated, unpopulated) provider defaulted
  // to false — a real duplicate-onboarding bug, not a one-off.
  final rolesState = ref.read(roleNotifierProvider);
  final isActiveVendor = rolesState.maybeWhen(
    loadSuccess: (roles) => roles.any((r) => r.role == 3 && r.isActivated),
    orElse: () => true, // not loaded yet — don't second-guess the caller.
  );
  return isActiveVendor ? null : RouteNames.vendorApply;
}

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
      // The Android engine independently forwards a fresh incoming Intent's
      // data URI to GoRouter's platform route channel (on top of the
      // app_links-driven `_navigate()` call in main.dart), so a
      // `stylemint://host/path` deep link can reach here as the RAW uri
      // instead of a normal `/path`. GoRouter can't match a uri with a
      // custom scheme against any route, matchedLocation falls back to `/`,
      // and the redirect below then bounces straight to sign-in — dropping
      // the OAuth/magic-link callback. Normalize it the same way
      // `_navigate()` does before falling through to the normal logic.
      if (state.uri.scheme == 'stylemint' && state.uri.host.isNotEmpty) {
        final normalizedPath = '/${state.uri.host}${state.uri.path}';
        final query = state.uri.query.isEmpty ? '' : '?${state.uri.query}';
        return '$normalizedPath$query';
      }

      final session = ref.read(sessionControllerProvider);
      final path = state.matchedLocation;
      // ignore: avoid_print
      print(
        // Path only: the query can carry an OAuth code and state.
        '[OAUTH-DEBUG] router.redirect: path=${state.uri.path} matchedLocation=$path session=$session',
      );
      // Patterns with :parameters (e.g. /product/:productId) match real
      // locations segment by segment; a plain startsWith never matched them,
      // so guests were sent to sign in from product and creator pages.
      final isPublic = _publicPaths.any((p) => routePathMatches(path, p));
      final isAuthOnly = _authOnlyPaths.any((p) => routePathMatches(path, p));
      final atSplash = path == RouteNames.splash;

      // The redirect OWNS splash routing: once the session resolves, send the
      // user off splash. Splash itself only kicks off bootstrap().
      return session.when(
        unknown: () => atSplash ? null : RouteNames.splash,
        authenticated: (_) {
          if (atSplash || isAuthOnly) return RouteNames.home;
          return _vendorManagementRedirect(ref, path);
        },
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
        path: RouteNames.completeName,
        builder: (ctx, state) {
          final extra = (state.extra as Map?) ?? const {};
          return CompleteNameScreen(
            accountId: (extra['accountId'] as String?) ?? '',
          );
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
      // Alias: prod backend redirects to /oauth-callback (without the
      // /auth prefix). Mirror the canonical route so the HTTPS deep
      // link lands on OAuthCallbackScreen.
      GoRoute(
        path: RouteNames.oauthCallbackAlias,
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
      GoRoute(
        path: RouteNames.cartScenarios,
        builder: (ctx, state) => const CartScenariosScreen(),
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
          paymentPending: state.uri.queryParameters['paymentPending'] == '1',
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

      // Mall product listing: Home "See all", brands and categories. The
      // query carries the listing filters and the title.
      GoRoute(
        path: RouteNames.productListing,
        builder: (ctx, state) {
          final params = state.uri.queryParameters;
          return ProductListingScreen(
            query: ProductListingQuery.fromQueryParameters(params),
            title: params[MallRoutes.titleParam],
          );
        },
      ),

      // Editorial collection or look.
      GoRoute(
        path: RouteNames.collection,
        builder: (ctx, state) => CollectionScreen(
          slug: state.pathParameters['slug']!,
          // Shared-element tag when opened from tagged artwork such as the
          // Mall's campaign hero; absent on a deep link, which just skips
          // the flight.
          heroTag: state.uri.queryParameters[MallRoutes.heroParam],
        ),
      ),

      // A brand's public flagship storefront.
      GoRoute(
        path: RouteNames.brandStorefront,
        builder: (ctx, state) => BrandStorefrontScreen(
          vendorAccountId: state.pathParameters['vendorAccountId']!,
        ),
      ),

      // Orders list: opened from Profile's "My Orders" (not a bar tab since
      // 2026-09-15).
      GoRoute(
        path: RouteNames.orders,
        builder: (ctx, state) => const TrackOrdersScreen(),
      ),

      // My returns and one return. Keep above Order Detail, or
      // `/orders/:orderId` reads "returns" as an order number.
      GoRoute(
        path: RouteNames.myReturns,
        builder: (ctx, state) => const MyReturnsScreen(),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.myReturns, RouteNames.returnDetail),
            builder: (ctx, state) => ReturnDetailScreen(
              returnId: state.pathParameters['returnId']!,
            ),
          ),
        ],
      ),

      // "Buy it again" — the Orders module's replenishment estimates. Keep
      // above Order Detail, or `/orders/:orderId` reads "buy-it-again" as an
      // order number.
      GoRoute(
        path: RouteNames.buyItAgain,
        builder: (ctx, state) => const BuyItAgainScreen(),
      ),

      // The Prepare stage: the verified, assembled refill basket, and the
      // rules the customer sets over it. Both keep above Order Detail for the
      // same reason "buy-it-again" does. The rules path is registered first so
      // `/orders/refill-plan/rules` is never read as the plan screen.
      GoRoute(
        path: RouteNames.replenishmentRules,
        builder: (ctx, state) => const ReplenishmentRulesScreen(),
      ),
      GoRoute(
        path: RouteNames.refillPlan,
        builder: (ctx, state) => const RefillPlanScreen(),
      ),

      // Order Detail
      GoRoute(
        path: RouteNames.orderDetail,
        builder: (ctx, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
          focusDeliveryRecovery:
              state.uri.queryParameters['focus'] ==
              RouteNames.orderDetailFocusRecovery,
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
          GoRoute(
            path: _subPath(RouteNames.orderDetail, RouteNames.orderInvoice),
            builder: (ctx, state) => OrderInvoiceScreen(
              order: state.extra! as OrderDetail,
            ),
          ),
          GoRoute(
            path: _subPath(RouteNames.orderDetail, RouteNames.orderFedEx),
            builder: (ctx, state) => FedExTrackingScreen(
              order: state.extra! as OrderDetail,
            ),
          ),
        ],
      ),

      // "Your delivery is at risk" push notification
      // (stylemint://delivery/{trackingNumber}/recovery). Resolves the
      // tracking number to the customer's order and forwards to order
      // detail with the recovery offers in view. Not public: the offers
      // are the customer's own, so a signed-out tap goes to sign-in.
      GoRoute(
        path: RouteNames.deliveryRecovery,
        builder: (ctx, state) => DeliveryRecoveryScreen(
          trackingNumber: state.pathParameters['trackingNumber']!,
        ),
      ),

      // Discover creators (follow)
      GoRoute(
        path: RouteNames.discoverCreators,
        builder: (ctx, state) => const FollowCreatorsDiscoveryScreen(),
      ),

      // Search results
      GoRoute(
        path: RouteNames.searchResults,
        builder: (ctx, state) => SearchResultsScreen(
          query: state.uri.queryParameters['q'] ?? '',
          initialResults: state.extra is CustomerSearchResults
              ? state.extra! as CustomerSearchResults
              : null,
        ),
      ),

      // Multimodal search inputs (voice, barcode). Both sit beside the
      // photo search on Discover and hand their result back to it.
      GoRoute(
        path: RouteNames.searchVoice,
        builder: (ctx, state) =>
            VoiceSearchScreen(initialQuery: state.extra as String?),
      ),
      GoRoute(
        path: RouteNames.searchBarcode,
        builder: (ctx, state) => const BarcodeScanScreen(),
      ),
      // Screenshot search. `extra` is the raw bytes when another app shared
      // a picture in; null when the buyer came from Discover and will pick
      // one. Both land on the same confirm step.
      GoRoute(
        path: RouteNames.searchScreenshot,
        builder: (ctx, state) =>
            ScreenshotSearchScreen(sharedBytes: state.extra as Uint8List?),
      ),

      // Trending products
      GoRoute(
        path: RouteNames.searchTrending,
        // One product listing serves the whole Mall. Trending is that
        // listing sorted by the server's bestselling order — there is no
        // second list screen with its own cards, empty state and signals.
        builder: (ctx, state) => const ProductListingScreen(
          query: ProductListingQuery(sort: ProductSort.bestselling),
          title: 'Trending',
        ),
      ),

      // Mission-Based Shopping — the one-shot public planner.
      GoRoute(
        path: RouteNames.missionShopping,
        builder: (ctx, state) => const MissionShoppingScreen(),
      ),

      // Minty, the personal shopping assistant. `/minty/new` is declared
      // before `/minty/:conversationId` so "new" is never read as an id.
      GoRoute(
        path: RouteNames.assistant,
        builder: (ctx, state) => const AssistantConversationsScreen(),
      ),
      GoRoute(
        path: RouteNames.assistantNewConversation,
        builder: (ctx, state) => const AssistantConversationScreen(),
      ),
      GoRoute(
        path: RouteNames.evidenceAnswers,
        builder: (ctx, state) => const EvidenceAnswerScreen(),
      ),
      GoRoute(
        path: RouteNames.assistantConversation,
        builder: (ctx, state) => AssistantConversationScreen(
          conversationId: state.pathParameters['conversationId'],
        ),
      ),

      // Mission shopping that persists: the shopper's own checklists.
      GoRoute(
        path: RouteNames.missions,
        builder: (ctx, state) => const MissionsScreen(),
      ),
      GoRoute(
        path: RouteNames.mission,
        builder: (ctx, state) =>
            MissionDetailScreen(missionId: state.pathParameters['missionId']!),
      ),

      GoRoute(
        path: RouteNames.outcomeContracts,
        builder: (ctx, state) => const OutcomeContractsScreen(),
      ),

      GoRoute(
        path: RouteNames.lifecycleSteward,
        builder: (ctx, state) => const LifecycleStewardScreen(),
      ),

      GoRoute(
        path: RouteNames.agentNegotiations,
        builder: (ctx, state) => const AgentNegotiationsScreen(),
      ),

      // Category products
      GoRoute(
        path: RouteNames.searchCategory,
        // Same listing again, filtered to the category, so a category page
        // has the filter sheet, the sort chips, paging and the Mall's tiles
        // instead of a private photo list.
        builder: (ctx, state) {
          final label = state.uri.queryParameters['label'] ?? 'Products';
          return ProductListingScreen(
            query: ProductListingQuery(
              categoryId: state.pathParameters['categoryId']!,
            ),
            title: label,
          );
        },
      ),

      // Reel comments
      GoRoute(
        path: RouteNames.reelComments,
        builder: (ctx, state) => ReelCommentsScreen(
          reelId: state.pathParameters['reelId']!,
        ),
      ),

      // Single reel: StyleMint share links (/reels/{id}) and search results.
      GoRoute(
        path: RouteNames.reelDetail,
        builder: (ctx, state) => ReelDetailScreen(
          reelId: state.pathParameters['reelId']!,
        ),
      ),

      // StyleMint Codes: /c/{code} resolves (counting the scan), then replaces
      // itself with the in-store product, the store or the person's profile.
      GoRoute(
        path: RouteNames.styleMintCode,
        builder: (ctx, state) => CodeResolveScreen(
          code: state.pathParameters['code']!,
          via: CodeScanVia.parse(state.uri.queryParameters['via']),
        ),
      ),
      GoRoute(
        path: RouteNames.inStoreProduct,
        builder: (ctx, state) {
          final query = state.uri.queryParameters;
          return InStoreProductScreen(
            productId: state.pathParameters['productId']!,
            storeId: query[InStoreQuery.storeId],
            code: query[InStoreQuery.code],
            via: CodeScanVia.parse(query[InStoreQuery.via]),
            storeName: query[InStoreQuery.store],
            storeCity: query[InStoreQuery.city],
          );
        },
      ),
      GoRoute(
        path: RouteNames.inStoreStore,
        builder: (ctx, state) {
          final query = state.uri.queryParameters;
          return InStoreStoreScreen(
            storeId: state.pathParameters['storeId']!,
            code: query[InStoreQuery.code],
            storeName: query[InStoreQuery.store],
            storeCity: query[InStoreQuery.city],
            vendorName: query[InStoreQuery.vendor],
            vendorId: query[InStoreQuery.vendorId],
          );
        },
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
          address: state.extra is ShippingAddress
              ? state.extra as ShippingAddress
              : null,
        ),
      ),
      GoRoute(
        path: RouteNames.shippingView,
        builder: (ctx, state) => ViewAddressScreen(
          address: state.extra! as ShippingAddress,
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
      GoRoute(
        path: RouteNames.paymentEditCard,
        builder: (ctx, state) =>
            AddCardScreen(card: state.extra! as PaymentMethod),
      ),

      // Creator
      GoRoute(
        path: RouteNames.creatorHome,
        builder: (ctx, state) => const CreatorDashboardScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorApply,
        // Instant, one-step onboarding. The status sub-routes below only
        // serve accounts that applied through the retired review flow.
        builder: (ctx, state) => const CreatorActivateScreen(),
        routes: [
          GoRoute(
            path: _subPath(
              RouteNames.creatorApply,
              RouteNames.creatorApplySubmitted,
            ),
            builder: (ctx, state) => const CreatorSubmittedScreen(),
          ),
          GoRoute(
            path: _subPath(
              RouteNames.creatorApply,
              RouteNames.creatorApplyUnderReview,
            ),
            builder: (ctx, state) => const CreatorUnderReviewScreen(),
          ),
          GoRoute(
            path: _subPath(
              RouteNames.creatorApply,
              RouteNames.creatorApplyApproved,
            ),
            builder: (ctx, state) => const CreatorApprovedScreen(),
          ),
          GoRoute(
            path: _subPath(
              RouteNames.creatorApply,
              RouteNames.creatorApplyRejected,
            ),
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
        path: RouteNames.creatorSearch,
        builder: (ctx, state) => const CreatorSearchScreen(),
      ),
      GoRoute(
        path: RouteNames.socialConnect,
        builder: (ctx, state) => SocialConnectScreen(
          isOnboarding: state.uri.queryParameters['onboarding'] == 'true',
        ),
      ),
      // The social-connect return link (stylemint://social-connected?...) is
      // handled in main.dart. If it ever reaches the router, land on the
      // social accounts screen instead of "Page not found".
      GoRoute(
        path: '/social-connected',
        redirect: (ctx, state) => RouteNames.socialConnect,
      ),
      GoRoute(
        path: RouteNames.reelImport,
        builder: (ctx, state) => const ImportReelScreen(),
      ),
      GoRoute(
        path: RouteNames.reelImportPreview,
        builder: (ctx, state) {
          final reel = state.extra! as ImportableReel;
          return PreviewReelScreen(reel: reel);
        },
      ),
      GoRoute(
        path: RouteNames.reelImportTagProducts,
        builder: (ctx, state) => const TagProductsScreen(),
      ),
      GoRoute(
        path: RouteNames.reelImportReview,
        builder: (ctx, state) => ReviewReelScreen(
          args: state.extra! as ReviewReelArgs,
        ),
      ),
      GoRoute(
        path: RouteNames.reelPublished,
        builder: (ctx, state) => ReelPublishedScreen(
          args: state.extra! as ReviewReelArgs,
        ),
      ),
      GoRoute(
        path: RouteNames.creatorAnalytics,
        builder: (ctx, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorReelAnalyticsDetail,
        builder: (ctx, state) => ReelDetailAnalyticsScreen(
          reelId: state.pathParameters['reelId']!,
        ),
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
        path: RouteNames.creatorPayoutHistory,
        builder: (ctx, state) => const creator_history.AllPayoutHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorPayoutInvoice,
        builder: (ctx, state) => PayoutInvoiceScreen(
          args: state.extra! as PayoutInvoiceArgs,
        ),
      ),
      GoRoute(
        path: RouteNames.creatorPaymentMethods,
        builder: (ctx, state) =>
            const PayoutMethodsScreen(role: PayeeKind.creator),
      ),
      GoRoute(
        path: RouteNames.creatorAddPaymentMethod,
        builder: (ctx, state) => const AddPaymentMethodScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorBankVerification,
        builder: (ctx, state) => const creator_verify.BankVerificationScreen(),
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
                  accountId: accountId,
                  displayName: '',
                  handle: '',
                );
          // The creator gets their own profile (owner tools); everyone else
          // gets the public storefront.
          return CreatorProfileGate(args: extra);
        },
      ),
      GoRoute(
        path: RouteNames.creatorProfileSettings,
        builder: (ctx, state) {
          final extra = state.extra is CreatorProfileArgs
              ? state.extra! as CreatorProfileArgs
              : const CreatorProfileArgs(
                  accountId: '',
                  displayName: '',
                  handle: '',
                );
          return ProfileSettingsScreen(
            displayName: extra.displayName,
            handle: extra.handle,
            avatarUrl: extra.avatarUrl,
          );
        },
      ),
      GoRoute(
        path: RouteNames.creatorEditProfile,
        builder: (ctx, state) {
          final extra = state.extra is CreatorProfileArgs
              ? state.extra! as CreatorProfileArgs
              : const CreatorProfileArgs(
                  accountId: '',
                  displayName: '',
                  handle: '',
                );
          return CreatorEditProfileScreen(
            initialDisplayName: extra.displayName,
            initialHandle: extra.handle,
          );
        },
      ),
      GoRoute(
        path: RouteNames.creatorProfileBadges,
        builder: (ctx, state) => const EditProfileBadgesScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorProfileTags,
        builder: (ctx, state) {
          final tags = state.extra is List<String>
              ? state.extra! as List<String>
              : <String>[];
          return EditProfileTagsScreen(initialTags: tags);
        },
      ),
      GoRoute(
        path: RouteNames.creatorCategoryNiche,
        builder: (ctx, state) => const EditCategoryNicheScreen(),
      ),
      GoRoute(
        path: RouteNames.creatorUpgradeSubscription,
        builder: (ctx, state) => const UpgradeSubscriptionScreen(),
      ),
      GoRoute(
        path: RouteNames.settingsChangePassword,
        builder: (ctx, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.partnerships,
        builder: (ctx, state) => const BrandsScreen(),
        routes: [
          GoRoute(
            path: _subPath(
              RouteNames.partnerships,
              RouteNames.activePartnerships,
            ),
            builder: (ctx, state) => const ActivePartnershipsScreen(),
          ),
          GoRoute(
            path: _subPath(
              RouteNames.partnerships,
              RouteNames.partnershipRequests,
            ),
            builder: (ctx, state) => const PartnershipRequestsScreen(),
          ),
          GoRoute(
            path: _subPath(RouteNames.partnerships, RouteNames.brandDetail),
            builder: (ctx, state) => BrandDetailScreen(
              partnershipId: state.pathParameters['partnershipId']!,
            ),
            routes: [
              GoRoute(
                path: _subPath(
                  RouteNames.brandDetail,
                  RouteNames.partnershipApply,
                ),
                builder: (ctx, state) => PartnershipRequestScreen(
                  args: state.extra! as PartnershipApplyArgs,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.brandMessaging,
        builder: (ctx, state) =>
            BrandMessagingScreen(args: state.extra! as BrandMessagingArgs),
      ),
      GoRoute(
        path: RouteNames.brandInfo,
        builder: (ctx, state) =>
            BrandInfoScreen(data: state.extra! as BrandInfoData),
      ),
      GoRoute(
        path: RouteNames.creatorRateCard,
        builder: (ctx, state) => const RateCardScreen(),
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
        path: RouteNames.vendorProfile,
        builder: (ctx, state) => const VendorProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.addProduct,
        builder: (ctx, state) => const AddProductWizardScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorProducts,
        builder: (ctx, state) => const VendorProductsScreen(),
      ),
      // StyleMint Codes for vendors: a product's shelf codes per store, and
      // the stores themselves. "new" is listed before ":storeId".
      GoRoute(
        path: RouteNames.vendorProductInStoreCodes,
        builder: (ctx, state) => ProductInStoreCodesScreen(
          productId: state.pathParameters['productId']!,
          product: state.extra is VendorProduct
              ? state.extra! as VendorProduct
              : null,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorStores,
        builder: (ctx, state) => const VendorStoresScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorStoreNew,
        builder: (ctx, state) => const VendorStoreFormScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorStoreEdit,
        builder: (ctx, state) => VendorStoreFormScreen(
          storeId: state.pathParameters['storeId'],
          store: state.extra is VendorStore
              ? state.extra! as VendorStore
              : null,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorStoreDetail,
        builder: (ctx, state) => VendorStoreDetailScreen(
          storeId: state.pathParameters['storeId']!,
          store: state.extra is VendorStore
              ? state.extra! as VendorStore
              : null,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorUpdateStock,
        builder: (ctx, state) => UpdateProductStockScreen(
          product: state.extra as VendorProduct,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorEditProductImages,
        builder: (ctx, state) => EditProductImagesScreen(
          productId: state.extra as String,
        ),
      ),
      GoRoute(
        // /vendor/products/:productId/edit - primary path for editing.
        // productId is the path parameter; the wizard fetches the
        // product and pre-populates every step.
        path: RouteNames.vendorEditProduct,
        builder: (ctx, state) => AddProductWizardScreen(
          productId: state.pathParameters['productId'],
        ),
      ),
      GoRoute(
        // Legacy /vendor/products/edit-details - kept for any callers that
        // still push the product id via extra. Same screen as the new
        // /:productId/edit route.
        path: RouteNames.vendorEditProductDetails,
        builder: (ctx, state) => AddProductWizardScreen(
          productId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorProductAnalytics,
        builder: (ctx, state) => ProductAnalyticsScreen(
          product: state.extra as VendorProduct,
        ),
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
        path: RouteNames.vendorCampaignBriefs,
        builder: (ctx, state) => const CampaignBriefsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorCreateCampaign,
        builder: (ctx, state) => const CreateCampaignScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorCampaignBriefDetail,
        builder: (ctx, state) => CampaignBriefDetailScreen(
          briefId: state.pathParameters['briefId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorCampaignWorkspace,
        builder: (ctx, state) => CampaignWorkspaceScreen(
          briefId: state.pathParameters['briefId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.vendorMatchmaking,
        builder: (ctx, state) => const MatchmakingScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorAnalytics,
        builder: (ctx, state) => const VendorAnalyticsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorDemandSignals,
        builder: (ctx, state) => const VendorDemandSignalsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorStoreActions,
        builder: (ctx, state) => const VendorStoreActionsScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorSponsoredProducts,
        builder: (ctx, state) => const VendorSponsoredProductsScreen(),
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
        builder: (ctx, state) => const vendor_history.AllPayoutHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.vendorStatementDetails,
        builder: (ctx, state) => StatementDetailsScreen(
          payoutId: state.extra as String,
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
        builder: (ctx, state) => const vendor_verify.BankVerificationScreen(),
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
      GoRoute(
        path: RouteNames.vendorSupportContact,
        builder: (ctx, state) => const VendorContactSupportScreen(),
      ),

      // Social
      GoRoute(
        path: RouteNames.community,
        builder: (ctx, state) => const CommunityHubScreen(),
      ),
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
        path: RouteNames.dropPartyScan,
        builder: (ctx, state) => const ScanInviteScreen(),
      ),
      // Keep the static scanner path before /drop/:dropPartyId so incoming
      // stylemint://drop/scan links cannot treat "scan" as a party id.
      GoRoute(
        path: RouteNames.dropParty,
        builder: (ctx, state) => DropPartyDetailScreen(
          partyId: state.pathParameters['dropPartyId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.liveSessions,
        builder: (ctx, state) => const LiveSessionsScreen(),
      ),
      GoRoute(
        path: RouteNames.liveRoom,
        builder: (ctx, state) => LiveRoomScreen(
          sessionId: state.pathParameters['sessionId']!,
        ),
      ),
      GoRoute(
        path: RouteNames.referrals,
        builder: (ctx, state) => const ReferralsScreen(),
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
        path: RouteNames.wallet,
        builder: (ctx, state) => const WalletScreen(),
      ),
      GoRoute(
        path: RouteNames.profileFollowing,
        builder: (ctx, state) => const FollowingScreen(),
      ),
      GoRoute(
        path: RouteNames.qrScan,
        builder: (ctx, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: RouteNames.scan,
        builder: (ctx, state) => const StyleMintScanScreen(),
      ),
      GoRoute(
        path: RouteNames.myStyleMintCode,
        builder: (ctx, state) => const MyStyleMintCodeScreen(),
      ),

      // Settings
      GoRoute(
        path: RouteNames.settings,
        builder: (ctx, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: _subPath(
              RouteNames.settings,
              RouteNames.settingsNotifications,
            ),
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
          GoRoute(
            path: _subPath(RouteNames.settings, RouteNames.settingsMemory),
            builder: (ctx, state) => const MemoryVaultScreen(),
          ),
          GoRoute(
            path: _subPath(
              RouteNames.settings,
              RouteNames.settingsConnectedAssistants,
            ),
            builder: (ctx, state) => const ConnectedAssistantsScreen(),
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
          GoRoute(
            path: _subPath(RouteNames.support, RouteNames.supportTopic),
            builder: (ctx, state) =>
                HelpTopicScreen(category: state.extra! as HelpCenterCategory),
          ),
          GoRoute(
            path: _subPath(RouteNames.support, RouteNames.supportArticle),
            builder: (ctx, state) =>
                HelpArticleScreen(article: state.extra! as HelpArticleSummary),
          ),
        ],
      ),

      // Auth account management
      GoRoute(
        path: RouteNames.accountSettings,
        builder: (ctx, state) => const AccountScreen(),
        routes: [
          GoRoute(
            path: _subPath(RouteNames.accountSettings, RouteNames.sessions),
            builder: (ctx, state) => const SessionsScreen(),
          ),
        ],
      ),
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
      StatefulShellRoute(
        builder: (ctx, state, navigationShell) =>
            CustomerShellScreen(navigationShell: navigationShell),
        navigatorContainerBuilder: (ctx, navigationShell, children) =>
            SwipeableBranchView(
              navigationShell: navigationShell,
              branches: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                // "Mall | Reels": the Mall by default, the reels feed on
                // the switch.
                builder: (ctx, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.search,
                builder: (ctx, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.profile,
                builder: (ctx, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Customer — recent activity (notifications)
      GoRoute(
        path: RouteNames.customerRecentActivity,
        builder: (ctx, state) =>
            const notifications_activity.RecentActivityScreen(),
      ),
    ],
  );
}

String _subPath(String parent, String full) {
  final prefix = parent.endsWith('/') ? parent : '$parent/';
  return full.startsWith(prefix) ? full.substring(prefix.length) : full;
}
