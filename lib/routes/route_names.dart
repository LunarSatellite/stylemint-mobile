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
  static String productDetailPath(String productId) =>
      productDetail.replaceFirst(':productId', Uri.encodeComponent(productId));

  /// `?replaceLine=` on [productDetail]: a stay or trip opened from its cart
  /// line to change dates, rooms or guests. Adding the new choice removes
  /// that line (a service line's options are fixed once added).
  static const productReplaceLineParam = 'replaceLine';
  /// `?tag=` on [productDetail]: the reel tag a stay or trip was opened
  /// from, so adding it to the cart credits the reel's creator as a product
  /// added from the reel would (service items contract v1 §6).
  static const productReelTagParam = 'tag';
  static String serviceItemPath(String productId, {String? reelTagId}) =>
      reelTagId == null || reelTagId.isEmpty
      ? productDetailPath(productId)
      : '${productDetailPath(productId)}?$productReelTagParam='
            '${Uri.encodeComponent(reelTagId)}';
  static String serviceItemEditPath(String productId, String cartLineId) =>
      '${productDetailPath(productId)}?$productReplaceLineParam='
      '${Uri.encodeComponent(cartLineId)}';

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

  /// `?focus=rate-rider` on [orderDetail]: bring "How was your rider?" into
  /// view — set when the buyer opens the order right after confirming a
  /// rider's delivery.
  static const orderDetailFocusRiderRating = 'rate-rider';

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

  /// Buyer identity verification (KYC Tier 2) for EMI: the status screen,
  /// and the form it opens. Where a `kyc.decided` push lands.
  static const customerKyc = '/verify-identity';
  static const customerKycSubmit = '/verify-identity/submit';

  /// Payment plans (EMI, pay later, pay now buy later): the buyer's list, the
  /// review of a signed quote, and one plan. [paymentPlanReview] is
  /// registered before [paymentPlanDetail] so `review` is never read as an
  /// agreement id.
  static const paymentPlans = '/payment-plans';
  static const paymentPlanReview = '/payment-plans/review';

  /// Applying for EMI from the product page (seller-approved, with
  /// documents). Registered before [paymentPlanDetail].
  static const paymentPlanApplyEmi = '/payment-plans/apply-emi';
  static const paymentPlanDetail = '/payment-plans/:agreementId';
  static String paymentPlanDetailPath(String agreementId) => paymentPlanDetail
      .replaceFirst(':agreementId', Uri.encodeComponent(agreementId));

  /// Checking out an approved plan: its one item, an address, Place.
  /// Virtual try-on (premium AR): the paywall, the buyer's plan, and the
  /// try-on screen for one product. `plans` and `my-plan` are literal
  /// segments, so the product route lives under `/try-on/product/`.
  static const tryOnPaywall = '/try-on/plans';
  static const myTryOnPlan = '/try-on/my-plan';
  static const tryOn = '/try-on/product/:productId';
  static String tryOnPath(String productId) =>
      tryOn.replaceFirst(':productId', Uri.encodeComponent(productId));

  static const paymentPlanCheckout = '/payment-plans/:agreementId/checkout';
  static String paymentPlanCheckoutPath(String agreementId) =>
      paymentPlanCheckout.replaceFirst(
        ':agreementId',
        Uri.encodeComponent(agreementId),
      );
  // ─── Services bought like items: bookings, bank requests (buyer) ─────────
  //
  // There is no Services tab (owner change, 2026-10-19): a stay, a trip or a
  // bank product is an item, found through reels and opened on the product
  // page. What the buyer booked or asked for lives under Orders.

  /// The buyer's bookings, and one booking (dates, reference, cancel per
  /// policy). Registered before [orderDetail] so `bookings` is never read as
  /// an order number.
  static const myBookings = '/orders/bookings';
  static const bookingDetail = '/orders/bookings/:bookingId';
  static String bookingDetailPath(String bookingId) =>
      bookingDetail.replaceFirst(':bookingId', Uri.encodeComponent(bookingId));

  /// The buyer's bank enquiries and branch appointments, and one of each.
  /// Registered before [orderDetail] for the same reason.
  static const myBankRequests = '/orders/bank-requests';
  static const bankEnquiryDetail = '/orders/bank-enquiries/:leadId';
  static String bankEnquiryDetailPath(String leadId) =>
      bankEnquiryDetail.replaceFirst(':leadId', Uri.encodeComponent(leadId));
  static const bankAppointmentDetail =
      '/orders/bank-appointments/:appointmentId';
  static String bankAppointmentDetailPath(String appointmentId) =>
      bankAppointmentDetail.replaceFirst(
        ':appointmentId',
        Uri.encodeComponent(appointmentId),
      );

  /// Signed-in forms opened from a bank item's page: an enquiry about one
  /// bank product, an appointment at one of the bank's branches
  /// (`?productId=` optional).
  static const bankEnquiryForm = '/bank-requests/enquire/:productId';
  static String bankEnquiryFormPath(String productId) =>
      bankEnquiryForm.replaceFirst(':productId', Uri.encodeComponent(productId));
  static const bankAppointmentForm = '/bank-requests/appointment/:bankId';
  static String bankAppointmentFormPath(String bankId, {String? productId}) {
    final path = bankAppointmentForm.replaceFirst(
      ':bankId',
      Uri.encodeComponent(bankId),
    );
    return productId == null
        ? path
        : '$path?productId=${Uri.encodeComponent(productId)}';
  }

  /// Under the public `/orders` prefix (an order page opens signed out from
  /// a tracking link), but only for a signed-in buyer. [myBookings] covers
  /// every booking below it.
  static const servicesSignedInOnly = {
    myBookings,
    myBankRequests,
    bankEnquiryDetail,
    bankAppointmentDetail,
  };

  /// The v1 Services paths (2026-10-18). Notifications already sent, and a
  /// v1 server, still link here; the router forwards each to where it lives
  /// now, and the old browse pages to Home.
  static const legacyServices = '/services';
  static const legacyMyBookings = '/services/bookings';
  static const legacyBookingDetail = '/services/bookings/:bookingId';
  static const legacyBookingConfirmed =
      '/services/bookings/:bookingId/confirmed';
  static const legacyBankEnquiryDetail = '/services/banks/enquiries/:leadId';
  static const legacyBankAppointmentDetail =
      '/services/banks/appointments/:appointmentId';
  static const legacyServiceBrowse = [
    '/services/stays/results',
    '/services/stays/:listingId',
    '/services/travel/results',
    '/services/travel/:listingId',
    '/services/banks/:bankId',
    '/services/bank-products/:productId',
  ];

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

  /// The delivery-partner role. One route: CourierGateScreen decides what to
  /// show from the courier's profile state, so callers never have to know
  /// whether this account has applied, is in review, or is live.
  static const courier = '/courier';

  /// The rider's offers. Nested under [courier] so a notification that opens
  /// it still has the dashboard beneath it to go back to.
  static const courierOffers = '/courier/offers';

  /// One job on the in-app map, with the parcel's details and the next
  /// action. Nested under [courier] for the same reason as [courierOffers].
  static const courierJob = '/courier/jobs/:hopId';

  /// [courierJob] for [hopId].
  static String courierJobPath(String hopId) =>
      '/courier/jobs/${Uri.encodeComponent(hopId)}';

  /// The recipient's side of proof of delivery: the rider's QR is the link
  /// `https://<StyleMint host>/dc/{token}`, opened here from the scanner or
  /// as an app link. Signed in only — only the order's buyer can confirm.
  static const deliveryConfirm = '/dc/:token';

  /// [deliveryConfirm] for [token].
  static String deliveryConfirmPath(String token) =>
      '/dc/${Uri.encodeComponent(token)}';
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

  /// Query flag on [vendorOrderDetail] that opens the delivery-partner sheet
  /// once the order has loaded — where a "rider is interested" push lands.
  static const partnerSheetQuery = 'partnerSheet';
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
  /// Try-on & sizes for one product: size chart + overlay image.
  static const vendorProductTryOn = '/vendor/products/:productId/try-on';
  static String vendorProductTryOnPath(String productId) => vendorProductTryOn
      .replaceFirst(':productId', Uri.encodeComponent(productId));
  static const vendorProductAnalytics = '/vendor/products/analytics';
  static const vendorTopProducts = '/vendor/products/top';

  /// "Offer EMI" for one listing (optional extra: VendorProduct, for its
  /// name). The terms themselves are read by id.
  static const vendorProductEmi = '/vendor/products/:productId/emi';

  /// The vendor's EMI settings: exposure limit and the listings offering EMI.
  static const vendorEmi = '/vendor/emi';

  /// The vendor's payment plans: the requests waiting for a decision, and one
  /// plan to approve or decline.
  static const vendorPaymentPlans = '/vendor/payment-plans';
  static const vendorPaymentPlanDetail = '/vendor/payment-plans/:agreementId';
  static String vendorPaymentPlanDetailPath(String agreementId) =>
      vendorPaymentPlanDetail.replaceFirst(
        ':agreementId',
        Uri.encodeComponent(agreementId),
      );

  /// The seller's running EMI plans (after approval): collections, what is
  /// left, what is next — and one plan with its full schedule. Seller EMI
  /// notifications (`plan.vendor.*`) open the detail.
  static const vendorEmiPlans = '/vendor/emi-plans';
  static const vendorEmiPlanDetail = '/vendor/emi-plans/:agreementId';
  static String vendorEmiPlanDetailPath(String agreementId) =>
      vendorEmiPlanDetail.replaceFirst(
        ':agreementId',
        Uri.encodeComponent(agreementId),
      );

  static String vendorProductEmiPath(String productId) => vendorProductEmi
      .replaceFirst(':productId', Uri.encodeComponent(productId));
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

  /// Authoring the terms every creator reads before accepting. Must be
  /// published once before any invite or application is accepted.
  static const vendorPartnershipTerms = '/vendor/partnerships/terms';
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
