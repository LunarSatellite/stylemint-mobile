abstract class RouteNames {
  // Splash & Onboarding intro
  static const splash = '/splash';
  static const onboarding = '/onboarding';

  // Auth
  static const signInMethod = '/signin-method';
  static const login = '/login';
  static const email = '/email';
  static const passkey = '/passkey';
  static const passkeyFace = '/passkey/face';
  static const passkeyFingerprint = '/passkey/fingerprint';
  static const socialLogin = '/social/:provider';
  // OAuth redirect deep link: stylemint://auth/oauth/callback?code=&state=
  static const oauthCallback = '/auth/oauth/callback';
  // Alias: prod backend redirects to /oauth-callback (no /auth prefix).
  static const oauthCallbackAlias = '/oauth-callback';
  static const otp = '/otp';
  static const magicLink = '/auth/magic';
  // Post-sign-in name capture (magic-link / accounts with no confirmed name).
  static const completeName = '/auth/complete-name';
  static const userTypeSelection = '/user-type-selection';
  static const rolePicker = '/role-picker';
  static const register = '/register';
  static const passwordLogin = '/signin-method/password';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // Onboarding
  static const pickInterests = '/pick-interests';
  static const followCreators = '/follow-creators';
  static const followBrands = '/follow-brands';

  // Customer
  static const home = '/home';
  static const search = '/search';
  static const searchResults = '/search-results';
  static const searchTrending = '/trending-products';
  static const searchCategory = '/browse-category/:categoryId';
  static const reelsFeed = '/reels';
  static const reelDetail = '/reels/:reelId';
  static const reelComments = '/reels/:reelId/comments';
  static const discoverCreators = '/discover/creators';
  static const productDetail = '/product/:productId';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const checkoutPayment = '/checkout/payment';
  static const orders = '/orders';
  static const orderDetail = '/orders/:orderId';
  static const orderSuccess = '/order-success/:orderId';
  static const orderCancel = '/orders/:orderId/cancel';
  static const orderInvoice = '/orders/:orderId/invoice';
  static const orderFedEx = '/orders/:orderId/fedex';
  static const productReviews = '/product/:productId/reviews';
  static const savedItems = '/saved-items';
  static const shippingAddresses = '/shipping';
  static const shippingAddEdit = '/shipping/edit';
  static const shippingView = '/shipping/view';
  static const paymentMethods = '/payment-methods';
  static const paymentAddCard = '/payment/add-card';
  static const paymentEditCard = '/payment/edit-card';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const qrScan = '/qr-login/scan';
  static const profileFollowing = '/profile/following';
  static const profileSavedItems = '/profile/saved-items';
  static const wallet = '/wallet';

  // Creator
  static const creatorHome = '/creator/home';
  static const creatorApply = '/creator/apply';
  static const creatorApplySubmitted = '/creator/apply/submitted';
  static const creatorApplyUnderReview = '/creator/apply/under-review';
  static const creatorApplyApproved = '/creator/apply/approved';
  static const creatorApplyRejected = '/creator/apply/rejected';
  static const creatorDash = '/creator/dashboard';
  static const creatorTopReels = '/creator/reels/top';
  static const reelImport = '/creator/import';
  static const reelImportPreview = '/creator/import/preview';
  static const reelImportTagProducts = '/creator/import/tag/:postId';
  static const reelImportReview = '/creator/import/review';
  static const reelPublished = '/creator/import/published';
  static const earnings = '/creator/earnings';
  static const earningsPayout = '/creator/earnings/payout';
  static const creatorPayoutHistory = '/creator/earnings/all-history';
  static const creatorPayoutInvoice = '/creator/earnings/invoice';
  static const creatorPaymentMethods = '/creator/payment-methods';
  static const creatorAddPaymentMethod = '/creator/payment-methods/add';
  static const creatorBankVerification = '/creator/payment-methods/verify';
  static const creatorReelDetail = '/creator/reels/:reelId';
  static const socialConnect = '/creator/social-connect';
  static const reelStudio = '/creator/reel-studio';
  static const reelStudioCreateDraft = '/creator/reel-studio/create';
  static const partnerships = '/creator/partnerships';
  static const brandDetail = '/creator/partnerships/:partnershipId';
  static const partnershipApply = '/creator/partnerships/:partnershipId/apply';
  static const activePartnerships = '/creator/partnerships/active';
  static const partnershipRequests = '/creator/partnerships/requests';
  static const brandMessaging = '/creator/brand-messaging';
  static const brandInfo = '/creator/brand-info';
  static const reach = '/creator/reach';

  // Vendor
  static const vendorHome = '/vendor/home';
  static const vendorApply = '/vendor/apply';
  static const vendorApplyStep2 = '/vendor/apply/step2';
  static const vendorApplyStep3 = '/vendor/apply/step3';
  static const vendorApplyStep4 = '/vendor/apply/step4';
  static const vendorApplyStep5 = '/vendor/apply/step5';
  static const vendorApplyStep6 = '/vendor/apply/step6';
  static const vendorApplySubmitted = '/vendor/apply/submitted';
  static const vendorApplyRejected = '/vendor/apply/rejected';
  static const vendorApplyUnderReview = '/vendor/apply/under-review';
  static const vendorApplyApproved = '/vendor/apply/approved';
  static const vendorDash = '/vendor/dashboard';
  static const addProduct = '/vendor/add-product';
  static const vendorOrders = '/vendor/orders';
  static const vendorOrderDetail = '/vendor/orders/:orderId';
  static const vendorOrdersReadyToShip = '/vendor/orders/ready-to-ship';
  static const vendorOrdersWaitingTracking = '/vendor/orders/waiting-tracking';
  static const vendorPendingInquiries = '/vendor/orders/pending-inquiries';
  static const vendorCreatorPartnershipRequests =
      '/vendor/partnerships/requests';
  static const vendorProducts = '/vendor/products';
  static const vendorUpdateStock = '/vendor/products/update-stock';
  static const vendorEditProductImages = '/vendor/products/edit-images';
  static const vendorEditProductDetails = '/vendor/products/edit-details';
  static const vendorProductAnalytics = '/vendor/products/analytics';
  static const vendorTopProducts = '/vendor/products/top';
  static const vendorRecentActivity = '/vendor/activity';
  static const vendorPartnerships = '/vendor/partnerships';
  static const vendorSendPartnershipRequest = '/vendor/partnerships/send';
  static const vendorPartnershipsInvite =
      '/vendor/partnerships/:campaignId/invite';
  static const vendorBrandStudio = '/vendor/brand-studio';
  static const vendorCampaignBriefs = '/vendor/briefs';
  static const vendorCreateCampaign = '/vendor/briefs/new';
  static const vendorCampaignBriefDetail = '/vendor/briefs/:briefId';
  static const vendorMatchmaking = '/vendor/matchmaking';
  static const vendorEarnings = '/vendor/earnings';
  static const vendorEarningsPayout = '/vendor/earnings/payout';
  static const vendorPayoutHistory = '/vendor/earnings/history';
  static const vendorStatementDetails = '/vendor/earnings/statement';
  static const vendorPaymentMethods = '/vendor/payment-methods';
  static const vendorChangePaymentMethod = '/vendor/payment-methods/select';
  static const vendorAddBankAccount = '/vendor/payment-methods/add-bank';
  static const vendorBankVerification = '/vendor/payment-methods/verify';
  static const vendorInquiries = '/vendor/inquiries';
  static const vendorCreatorPerformance = '/vendor/creator-performance';
  static const vendorCreatorAnalytics = '/vendor/creator-analytics';
  static const vendorAnalytics = '/vendor/analytics';
  static const vendorMessageCreator = '/vendor/message-creator';
  static const vendorAdjustCommission = '/vendor/adjust-commission';
  static const vendorSupportContact = '/vendor/support/contact';

  // Social
  static const creatorProfile = '/creator-profile/:accountId';
  static const creatorProfileSettings = '/creator/profile-settings';
  static const creatorEditProfile = '/creator/edit-profile';
  static const creatorProfileBadges = '/creator/edit-profile-badges';
  static const creatorProfileTags = '/creator/edit-profile-tags';
  static const creatorCategoryNiche = '/creator/edit-category-niche';
  static const creatorUpgradeSubscription = '/creator/upgrade-subscription';
  static const feed = '/feed';
  static const feedCreatePost = '/feed/create';
  static const stories = '/stories';
  static const storyViewer = '/stories/:userId';
  static const recommendations = '/recommendations';
  static const recommendationsThread = '/recommendations/:requestId';
  static const groups = '/groups';
  static const groupsDetail = '/groups/:groupId';
  static const friends = '/friends';
  static const dropParty = '/drop/:dropPartyId';
  static const dropPartiesList = '/drops';
  static const dropPartyScan = '/drop/scan';
  static const groupCart = '/group-cart/:groupCartId';
  static const groupCartsList = '/group-carts';
  static const coWatch = '/co-watch';
  static const coWatchSession = '/co-watch/:sessionId';
  static const tips = '/tips';
  static const tipsSend = '/tips/send';

  // Settings / Support
  static const settings = '/settings';
  static const settingsNotifications = '/settings/notifications';
  static const settingsLanguage = '/settings/language';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsTerms = '/settings/terms';
  static const settingsAbout = '/settings/about';
  static const settingsChangePassword = '/settings/change-password';
  static const accountSettings = '/account';
  static const sessions = '/account/sessions';

  // Auth account management
  static const mfaSetup = '/account/mfa';
  static const devices = '/account/devices';
  static const handleSetup = '/account/handle';
  static const blockedUsers = '/account/blocked';
  static const linkedAccounts = '/account/linked-accounts';
  static const marketingConsents = '/account/marketing-consents';
  static const pauseAccount = '/account/pause';

  static const support = '/support';
  static const supportContact = '/support/contact';
  static const supportTickets = '/support/tickets';
  static const supportTopic = '/support/topic';
  static const supportArticle = '/support/article';

  static const creatorSupportContact = '/creator/support/contact';
  static const creatorActivity = '/creator/activity';
  static const creatorAnalytics = '/creator/analytics';
  static const creatorReelAnalyticsDetail = '/creator/analytics/reel-detail/:reelId';
  static const creatorFullAnalyticsReport = '/creator/analytics/full-report';
  static const creatorSearch = '/creator/search';
}
