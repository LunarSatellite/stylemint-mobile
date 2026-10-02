/// Whether this build may offer digital goods for sale inside the app.
///
/// Google Play and the Apple App Store both require their own billing for
/// digital content bought inside an app. StyleMint charges through eSewa and
/// cards, which is a policy violation for digital content — Play removes the
/// listing rather than warning first. The owner's decision (2026-10-02) is to
/// **hide digital goods** on the stores that require store billing rather than
/// integrate Play Billing / StoreKit now.
///
/// This is one object so no call site has to know which store is involved:
/// each surface asks [canOfferDigitalGoods] or [blocksPurchaseOf], and the
/// platform decision lives in [DigitalGoodsPolicy.forPlatform] alone.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Catalog `ProductKind` (StyleMint.Modules.Catalog.Enums.ProductKind).
///
/// Kept as plain ints because that is what the wire carries, and because an
/// unknown value has to stay representable — see [isDigitalProductKind].
abstract final class ProductKinds {
  static const int physical = 1;
  static const int digital = 2;
  static const int service = 3;
  static const int subscription = 4;
  static const int bundle = 5;
}

/// The kinds that are digital content for store-billing purposes: a download
/// ([ProductKinds.digital]) and recurring access ([ProductKinds.subscription]).
///
/// Physical goods, services and bundles are not. Bundles are composites and
/// are priced as one line; the server does not say what a bundle contains on
/// the card payloads, so a bundle is treated as it always was.
const Set<int> digitalProductKinds = {
  ProductKinds.digital,
  ProductKinds.subscription,
};

/// Whether [productKind] is known to be digital content.
///
/// `null` means the payload did not carry a kind — the public product card and
/// detail reads only started sending one with this change, and older servers
/// send nothing. Unknown is **not** treated as digital: guessing "digital"
/// would empty the catalogue, which is a far worse failure than a kind that
/// slips through. The gate only ever acts on a kind the server stated.
bool isDigitalProductKind(int? productKind) =>
    productKind != null && digitalProductKinds.contains(productKind);

/// The app stores whose billing rules this policy covers.
enum StoreBillingRule {
  /// Google Play Billing is required for digital content.
  googlePlay,

  /// Apple StoreKit in-app purchase is required for digital content.
  appStore,

  /// No store rule applies (desktop, web, tests).
  none,
}

/// Whether digital goods may be offered, and why not when they may not.
@immutable
class DigitalGoodsPolicy {
  const DigitalGoodsPolicy({
    required this.canOfferDigitalGoods,
    required this.rule,
  });

  /// Digital goods may be offered — the state every non-store build is in,
  /// and the state an Android build returns to once Play Billing lands.
  const DigitalGoodsPolicy.allowed()
    : canOfferDigitalGoods = true,
      rule = StoreBillingRule.none;

  /// Digital goods are hidden because [rule] requires store billing this app
  /// does not implement.
  const DigitalGoodsPolicy.blockedBy(this.rule) : canOfferDigitalGoods = false;

  /// Whether this build may show a price, a plan or a buy control for digital
  /// content.
  final bool canOfferDigitalGoods;

  /// The store rule that caused the block, or [StoreBillingRule.none].
  final StoreBillingRule rule;

  /// The policy for [platform].
  ///
  /// Android is blocked now. iOS is **the seam**: the App Store has the same
  /// rule and this app already ships to TestFlight, so switching iOS off is
  /// one line here — `TargetPlatform.iOS => const
  /// DigitalGoodsPolicy.blockedBy(StoreBillingRule.appStore)` — and no call
  /// site changes. It is left allowed today because the owner asked only for
  /// Android.
  factory DigitalGoodsPolicy.forPlatform(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android => const DigitalGoodsPolicy.blockedBy(
          StoreBillingRule.googlePlay,
        ),
        _ => const DigitalGoodsPolicy.allowed(),
      };

  /// The policy for the platform this code is running on. Web is never a
  /// store build, so it is allowed regardless of the reported platform.
  factory DigitalGoodsPolicy.forCurrentPlatform() => kIsWeb
      ? const DigitalGoodsPolicy.allowed()
      : DigitalGoodsPolicy.forPlatform(defaultTargetPlatform);

  /// Whether a product of [productKind] must not be purchasable here.
  ///
  /// False for every kind when [canOfferDigitalGoods], and false for a kind
  /// the server did not state — see [isDigitalProductKind].
  bool blocksPurchaseOf(int? productKind) =>
      !canOfferDigitalGoods && isDigitalProductKind(productKind);

  /// The policy in scope at [context], or the platform's own policy when no
  /// [DigitalGoodsScope] is installed.
  ///
  /// Plain widgets read the policy this way; Riverpod screens read
  /// `digitalGoodsPolicyProvider`. Both resolve to the same platform default,
  /// so a widget test asserts either state by wrapping in a
  /// [DigitalGoodsScope] without faking the platform.
  static DigitalGoodsPolicy of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DigitalGoodsScope>()?.policy ??
      DigitalGoodsPolicy.forCurrentPlatform();

  @override
  bool operator ==(Object other) =>
      other is DigitalGoodsPolicy &&
      other.canOfferDigitalGoods == canOfferDigitalGoods &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(canOfferDigitalGoods, rule);
}

/// Overrides the [DigitalGoodsPolicy] for a subtree. The app does not install
/// one — the platform default is the production answer — so this exists for
/// tests and for a future per-surface override.
class DigitalGoodsScope extends InheritedWidget {
  const DigitalGoodsScope({
    required this.policy,
    required super.child,
    super.key,
  });

  final DigitalGoodsPolicy policy;

  @override
  bool updateShouldNotify(DigitalGoodsScope oldWidget) =>
      oldWidget.policy != policy;
}
