/// All named route constants. Never hardcode path strings in widgets.
abstract class RouteNames {
  // Splash & Onboarding intro
  static const splash             = '/splash';
  static const onboarding         = '/onboarding';

  // Auth
  static const signInMethod       = '/signin-method'; // Entry point - all sign-in methods
  static const login              = '/login';
  static const email              = '/email';
  static const passkey            = '/passkey';
  static const passkeyFace        = '/passkey/face';
  static const passkeyFingerprint = '/passkey/fingerprint';
  static const socialLogin        = '/social/:provider'; // OAuth callbacks
  static const otp                = '/otp';
  static const magicLink          = '/auth/magic';
  static const userTypeSelection  = '/user-type-selection';
  static const rolePicker         = '/role-picker'; // Deprecated, use userTypeSelection

  // Onboarding
  static const pickInterests      = '/pick-interests';
  static const followCreators     = '/follow-creators';

  // Customer
  static const home           = '/home';
  static const search         = '/search';
  static const reelsFeed      = '/reels';
  static const reelDetail     = '/reels/:reelId';
  static const productDetail  = '/product/:productId';
  static const cart           = '/cart';
  static const checkout       = '/checkout';
  static const orders         = '/orders';
  static const orderDetail    = '/orders/:orderId';

  // Creator
  static const creatorHome    = '/creator/home';
  static const creatorApply   = '/creator/apply';
  static const creatorDash    = '/creator/dashboard';
  static const reelImport     = '/creator/import';
  static const earnings       = '/creator/earnings';

  // Vendor
  static const vendorHome     = '/vendor/home';
  static const vendorApply    = '/vendor/apply';
  static const vendorDash     = '/vendor/dashboard';
  static const addProduct     = '/vendor/add-product';
  static const vendorOrders   = '/vendor/orders';
  static const vendorEarnings = '/vendor/earnings';

  // Social
  static const feed           = '/feed';
  static const recommendations = '/recommendations';
  static const groups         = '/groups';
  static const friends        = '/friends';
  static const dropParty      = '/drop/:dropPartyId';
  static const groupCart      = '/group-cart/:groupCartId';

  // Settings / Support
  static const settings       = '/settings';
  static const support        = '/support';
}
