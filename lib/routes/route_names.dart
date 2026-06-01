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
  static const otp = '/otp';
  static const magicLink = '/auth/magic';
  static const userTypeSelection = '/user-type-selection';
  static const rolePicker = '/role-picker';
  static const register = '/register';
  static const passwordLogin = '/signin-method/password';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';

  // Onboarding
  static const pickInterests = '/pick-interests';
  static const followCreators = '/follow-creators';

  // Customer
  static const home = '/home';
  static const search = '/search';
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
  static const orderCancel = '/orders/:orderId/cancel';
  static const productReviews = '/product/:productId/reviews';
  static const savedItems = '/saved-items';
  static const shippingAddresses = '/shipping';
  static const shippingAddEdit = '/shipping/edit';
  static const paymentMethods = '/payment-methods';
  static const paymentAddCard = '/payment/add-card';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const profileFollowing = '/profile/following';
  static const profileSavedItems = '/profile/saved-items';

  // Creator
  static const creatorHome = '/creator/home';
  static const creatorApply = '/creator/apply';
  static const creatorDash = '/creator/dashboard';
  static const reelImport = '/creator/import';
  static const reelImportTagProducts = '/creator/import/tag/:postId';
  static const earnings = '/creator/earnings';
  static const earningsPayout = '/creator/earnings/payout';
  static const creatorPaymentMethods = '/creator/payment-methods';
  static const creatorReelDetail = '/creator/reels/:reelId';
  static const socialConnect = '/creator/social-connect';
  static const reelStudio = '/creator/reel-studio';
  static const reelStudioCreateDraft = '/creator/reel-studio/create';
  static const partnerships = '/creator/partnerships';
  static const brandDetail = '/creator/partnerships/:partnershipId';
  static const reach = '/creator/reach';

  // Vendor
  static const vendorHome = '/vendor/home';
  static const vendorApply = '/vendor/apply';
  static const vendorDash = '/vendor/dashboard';
  static const addProduct = '/vendor/add-product';
  static const vendorOrders = '/vendor/orders';
  static const vendorOrderDetail = '/vendor/orders/:orderId';
  static const vendorProducts = '/vendor/products';
  static const vendorPartnerships = '/vendor/partnerships';
  static const vendorPartnershipsInvite = '/vendor/partnerships/:campaignId/invite';
  static const vendorBrandStudio = '/vendor/brand-studio';
  static const vendorMatchmaking = '/vendor/matchmaking';
  static const vendorEarnings = '/vendor/earnings';
  static const vendorEarningsPayout = '/vendor/earnings/payout';
  static const vendorPaymentMethods = '/vendor/payment-methods';
  static const vendorInquiries = '/vendor/inquiries';
  static const vendorCreatorPerformance = '/vendor/creator-performance';

  // Social
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
}
