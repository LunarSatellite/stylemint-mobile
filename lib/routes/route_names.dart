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

  /// Speak a search, correct the transcript, then search. Pops the
  /// confirmed query back to whoever opened it.
  static const searchVoice = '/search/voice';

  /// Scan a product barcode. Navigates to the product on a match; pops
  /// the scanned digits back as a text query when the buyer asks for it.
  static const searchBarcode = '/search/barcode';

  /// Search with a screenshot of another app. Reached from Discover, and
  /// from the system share sheet with the shared bytes as `extra`.
  static const searchScreenshot = '/search/screenshot';
  static const searchTrending = '/trending-products';
  static const searchCategory = '/browse-category/:categoryId';
  static const missionShopping = '/mission-shopping';

  // Minty, the personal shopping assistant. Conversations persist, so the
  // history list is the entry point and a thread has its own address.
  static const assistant = '/minty';
  static const assistantNewConversation = '/minty/new';
  static const assistantConversation = '/minty/:conversationId';

  // Evidence-backed, time-aware answers — the `commerce-intelligence` route
  // family. Declared before `/minty/:conversationId` in the router so
  // "evidence" is never read as a conversation id.
  static const evidenceAnswers = '/minty/evidence';

  // Mission shopping that persists: a checklist the shopper works through.
  // Distinct from [missionShopping], which is the one-shot public planner.
  static const missions = '/missions';
  static const mission = '/missions/:missionId';

  static const outcomeContracts = '/outcome-promises';
  static const lifecycleSteward = '/wardrobe-life';
  static const agentNegotiations = '/agent-negotiations';
  static const reelsFeed = '/reels';
  static const reelDetail = '/reels/:reelId';
  static const reelComments = '/reels/:reelId/comments';
  static const discoverCreators = '/discover/creators';
  static const productDetail = '/product/:productId';

  /// Mall product listing. Query = the `GET v1/public/products` filters
  /// (sort, categoryId, categorySlug, vendorAccountId, minPrice, maxPrice,
  /// inStock, onSale, minRating, q) plus `title`.
  static const productListing = '/products';

  /// An editorial collection or a look.
  static const collection = '/collections/:slug';

  /// Prefix of [collection] locations; open to guests.
  static const collectionRoot = '/collections/';

  /// A brand's public flagship storefront; open to guests.
  static const brandStorefront = '/brands/:vendorAccountId';
  static const cart = '/cart';
  static const cartScenarios = '/cart/scenarios';
  static const checkout = '/checkout';
  static const checkoutPayment = '/checkout/payment';
  static const orders = '/orders';
  static const orderDetail = '/orders/:orderId';
  static const orderSuccess = '/order-success/:orderId';
  static const orderCancel = '/orders/:orderId/cancel';
  static const orderInvoice = '/orders/:orderId/invoice';
  static const orderFedEx = '/orders/:orderId/fedex';

  /// Where the "your delivery is at risk" push notification lands
  /// (`stylemint://delivery/{trackingNumber}/recovery`). Resolves the
  /// tracking number to the customer's own order and forwards to
  /// [orderDetail] with [orderDetailFocusRecovery] set, so the AI Delivery
  /// Guardian banner and its recovery offers are scrolled into view.
  /// Signed-in only — the offers are the customer's own.
  static const deliveryRecovery = '/delivery/:trackingNumber/recovery';

  /// `?focus=delivery-recovery` on [orderDetail]: scroll to the delivery
  /// recovery offers on open instead of starting at the top of the order.
  static const orderDetailFocusRecovery = 'delivery-recovery';

  /// The buyer's returns and one return. Registered before [orderDetail] so
  /// `returns` is never read as an order number.
  static const myReturns = '/orders/returns';
  static const returnDetail = '/orders/returns/:returnId';

  /// "Buy it again" — the replenishment estimates the Orders module already
  /// computed. Registered before [orderDetail] so `buy-it-again` is never
  /// read as an order number.
  static const buyItAgain = '/orders/buy-it-again';

  /// The prepared refill basket and the rules that govern it. Registered
  /// before [orderDetail] so `refill-plan` is never read as an order number.
  static const refillPlan = '/orders/refill-plan';
  static const replenishmentRules = '/orders/refill-plan/rules';
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

  /// The customer bar's Scan action: reads any StyleMint QR code.
  static const scan = '/scan';
  static const profileFollowing = '/profile/following';
  static const profileSavedItems = '/profile/saved-items';
  static const wallet = '/wallet';

  // StyleMint Codes
  /// Opens a StyleMint code: `/c/{code}?via=Qr|Nfc|Link` (no `via` = Link).
  static const styleMintCode = '/c/:code';

  /// Prefix of [styleMintCode] locations; open to guests.
  static const styleMintCodeRoot = '/c/';

  /// A product scanned in a store: `?storeId=&code=&store=&city=`.
  static const inStoreProduct = '/in-store/product/:productId';

  /// A store's code: `?code=&store=&city=&vendor=`.
  static const inStoreStore = '/in-store/store/:storeId';

  /// Prefix of the in-store routes; open to guests.
  static const inStoreRoot = '/in-store/';

  /// The signed-in person's own Profile code.
  static const myStyleMintCode = '/account/stylemint-code';

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
  /// Campaigns a vendor published and opened to creators, the one a creator is
  /// reading, and the creator's own applications. The detail path carries the
  /// brief id, not the root id: a creator applies to a specific version, and
  /// the application records which one.
  static const creatorCampaigns = '/creator/campaigns';
  static const creatorCampaignDetail = '/creator/campaigns/:briefId';
  static const creatorMyApplications = '/creator/campaigns/applications';

  static const partnerships = '/creator/partnerships';
  static const brandDetail = '/creator/partnerships/:partnershipId';
  static const partnershipApply = '/creator/partnerships/:partnershipId/apply';
  static const activePartnerships = '/creator/partnerships/active';
  static const partnershipRequests = '/creator/partnerships/requests';
  static const brandMessaging = '/creator/brand-messaging';
  static const brandInfo = '/creator/brand-info';
  static const creatorRateCard = '/creator/rate-card';
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
  static const vendorProfile = '/vendor/profile';
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
  // /vendor/products/:productId/edit - unified edit form, replaces the
  // legacy edit-details route now that the form handles both Create
  // and Edit modes.
  static const vendorEditProduct = '/vendor/products/:productId/edit';
  static const vendorProductAnalytics = '/vendor/products/analytics';
  static const vendorTopProducts = '/vendor/products/top';
  // Per-product StyleMint shelf codes (extra: VendorProduct).
  static const vendorProductInStoreCodes =
      '/vendor/products/:productId/in-store-codes';

  /// Per-unit tags for one listing (extra: VendorProduct). Mints a print run
  /// and reveals each tag's code once. The code itself never appears in this
  /// route or in any other — it is a credential, and a credential in a URL
  /// lands in every access log on the way.
  static const vendorProductUnitMarkers =
      '/vendor/products/:productId/unit-markers';

  /// Binds the tag a packer is holding to one order line
  /// (extra: UnitMarkerBindArgs). The order line id is in the path; the
  /// marker is not.
  static const vendorUnitMarkerBind = '/vendor/unit-markers/bind/:lineId';

  /// The seller's register of minted tags. Optional `?productId=` narrows it
  /// to one listing; `extra: VendorProduct` additionally supplies the name,
  /// which the list response does not carry.
  static const vendorUnitMarkerRegister = '/vendor/unit-markers';

  /// One tag's full binding trail, corrections included.
  ///
  /// The path segment is the non-secret `UMxxxxxxxxxx` **reference** — the
  /// same handle the backend's own route takes. The tag's code is a
  /// credential and appears in no route, here or anywhere else.
  static const vendorUnitMarkerBindings =
      '/vendor/unit-markers/:reference/bindings';

  /// One tag's recorded readings. Reference in the path, never the code.
  static const vendorUnitMarkerScans = '/vendor/unit-markers/:reference/scans';

  /// A scanned item's passport: `/unit-tag/{unitMarkerId}`.
  ///
  /// The path carries the **opaque marker id** the scan returned, never the
  /// marker itself. The id is not a credential — the passport re-checks the
  /// binding, so a guessed id is simply unbound.
  static const unitTagPassport = '/unit-tag/:unitMarkerId';

  // Physical stores/branches and their codes.
  static const vendorStores = '/vendor/stores';
  static const vendorStoreNew = '/vendor/stores/new';
  static const vendorStoreDetail = '/vendor/stores/:storeId';
  static const vendorStoreEdit = '/vendor/stores/:storeId/edit';
  static const vendorRecentActivity = '/vendor/activity';
  /// Campaign reels waiting on this vendor's answer.
  static const vendorReelApprovals = '/vendor/reel-approvals';

  static const vendorPartnerships = '/vendor/partnerships';
  static const vendorSendPartnershipRequest = '/vendor/partnerships/send';
  static const vendorPartnershipsInvite =
      '/vendor/partnerships/:campaignId/invite';
  static const vendorBrandStudio = '/vendor/brand-studio';
  static const vendorCampaignBriefs = '/vendor/briefs';
  static const vendorCreateCampaign = '/vendor/briefs/new';
  static const vendorCampaignBriefDetail = '/vendor/briefs/:briefId';
  static const vendorCampaignWorkspace = '/vendor/briefs/:briefId/workspace';
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
  static const vendorDemandSignals = '/vendor/demand-signals';
  static const vendorStoreActions = '/vendor/store-actions';
  static const vendorSponsoredProducts = '/vendor/sponsored';
  static const vendorMessageCreator = '/vendor/message-creator';

  static const vendorAdjustCommission = '/vendor/adjust-commission';
  static const vendorSupportContact = '/vendor/support/contact';

  // Social
  static const community = '/community';
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
  static const liveSessions = '/live';
  static const liveRoom = '/live/:sessionId';
  static const referrals = '/referrals';
  static const coWatch = '/co-watch';
  static const coWatchSession = '/co-watch/:sessionId';
  static const tips = '/tips';
  static const tipsSend = '/tips/send';

  // Settings / Support
  static const settings = '/settings';
  static const settingsNotifications = '/settings/notifications';
  static const customerRecentActivity = '/customer/recent-activity';
  static const settingsLanguage = '/settings/language';
  static const settingsPrivacy = '/settings/privacy';
  static const settingsTerms = '/settings/terms';

  /// Top-level aliases for the same two documents, for the "by continuing you
  /// agree" links on the auth screens. The settings paths are nested under
  /// `/settings`, so pushing one from sign-in puts the Settings screen on the
  /// back stack underneath it — from a login footer that reads as a wrong
  /// turn. These land on the document and pop straight back.
  static const legalTerms = '/terms';
  static const legalPrivacy = '/privacy';
  static const settingsAbout = '/settings/about';
  static const settingsMemory = '/settings/memory';

  /// Outside AI shopping assistants: issue, read and revoke their mandates,
  /// confirm the baskets they prepare, and read what they did.
  ///
  /// The route carries nothing. The mandate credential is shown once inside a
  /// modal sheet and never becomes navigator state, a path or a query string.
  static const settingsConnectedAssistants = '/settings/connected-assistants';

  /// Shopping plans: a stated intent compiled into steps, and the shopper's
  /// go-ahead for them. It sits beside [settingsConnectedAssistants] because
  /// it is the same kind of surface — StyleMint proposes, the shopper
  /// decides, and nothing on either screen buys, holds or pays.
  static const settingsShoppingPlans = '/settings/shopping-plans';
  static const settingsShoppingPlan = '/settings/shopping-plans/:planId';
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
  static const creatorReelAnalyticsDetail =
      '/creator/analytics/reel-detail/:reelId';
  static const creatorFullAnalyticsReport = '/creator/analytics/full-report';
  static const creatorSearch = '/creator/search';

  // ─── Clienteling (v1/clienteling/*) ───────────────────────────────────────

  /// A store associate's client book. Not a role in this app: the backend
  /// gates it on an active vendor team membership plus a live per-customer
  /// assignment, so an account with neither sees an empty book.
  static const associateClientBook = '/associate/clients';

  /// One permitted customer's workspace: `/associate/clients/:customerAccountId`.
  static const associateClientBrief = '/associate/clients/:customerAccountId';

  /// The shopper's own record of who served them, and the confirm/reject
  /// control that is the only path to an associate's credit.
  static const myClienteling = '/settings/in-store-assistance';
}
