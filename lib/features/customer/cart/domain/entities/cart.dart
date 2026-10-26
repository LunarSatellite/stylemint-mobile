import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_finding.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// AI-generated, cart-grounded observations — backend
/// `BasketOptimizationSummary`.
///
/// [findings] is additive: [insights] and [savingsTip] keep their existing
/// meaning and shape, and a backend that sends no `findings` key simply yields
/// an empty list.
class BasketOptimization {
  const BasketOptimization({
    required this.insights,
    this.savingsTip,
    this.findings = const [],
    this.narrativeDisclosure,
  });

  /// LLM-written observations. The one part of this type that can state
  /// something no record supports, so it is never rendered on its own — see
  /// [canRenderNarrative].
  final List<String> insights;

  /// The LLM-written tip. Same provenance as [insights].
  final String? savingsTip;

  /// Evidence-backed findings, each carrying the records it rests on. Empty
  /// when the basket genuinely has nothing to say — which renders nothing at
  /// all, not an empty state.
  final List<BasketFinding> findings;

  /// Fixed backend copy marking [insights]/[savingsTip] as not evidence.
  ///
  /// Non-null *only* when the narrative actually carries text; null in the
  /// default configuration, where `CartCheckout:BasketNarrative:Enabled` is
  /// off and there is no narrative to mark. Rendered verbatim — it is a fact
  /// about the system, not text this client may reword.
  final String? narrativeDisclosure;

  /// Whether the LLM narrative carries any text at all.
  bool get hasNarrativeText =>
      insights.any((i) => i.trim().isNotEmpty) ||
      (savingsTip?.trim().isNotEmpty ?? false);

  /// Whether the narrative may be shown.
  ///
  /// Only when its disclosure came with it. Narrative text without a
  /// disclosure is dropped: an unmarked ungrounded claim sitting beside
  /// sourced findings is worse than a missing one.
  bool get canRenderNarrative =>
      hasNarrativeText && (narrativeDisclosure?.trim().isNotEmpty ?? false);

  bool get hasContent => canRenderNarrative;
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.isInStock,
    this.creatorHandle,
    this.commissionRate,
    this.variantId,
    this.service,
  });

  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String variantName;
  final int quantity;
  final Money unitPrice;
  final bool isInStock;

  /// Creator attribution from the reel that drove this add-to-cart (backend
  /// CartLineDto.creatorHandleSnapshot / commissionRateSnapshot). Null when the
  /// line had no creator attribution (catalog/PDP add).
  final String? creatorHandle;

  /// Commission rate as a fraction 0.0–1.0 (e.g. 0.15 = 15%).
  final double? commissionRate;

  /// The cart line's product variant (backend CartLineDto.productVariantId).
  /// Payment plans (EMI) are offered per variant, so checkout needs it.
  final String? variantId;

  /// A stay or trip (service cart contract v1 §2.2): its dates, room or
  /// departure, guests, and what is paid now and at the venue. Null for a
  /// product. A service line's quantity is always 1 and cannot be changed;
  /// to change the options the buyer removes it and adds it again.
  final ServiceLine? service;

  bool get isService => service != null;

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? variantName,
    int? quantity,
    Money? unitPrice,
    bool? isInStock,
    String? creatorHandle,
    double? commissionRate,
    String? variantId,
  }) {
    return CartItem(
      service: service,
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      variantName: variantName ?? this.variantName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      isInStock: isInStock ?? this.isInStock,
      creatorHandle: creatorHandle ?? this.creatorHandle,
      commissionRate: commissionRate ?? this.commissionRate,
      variantId: variantId ?? this.variantId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CartItem &&
      other.id == id &&
      other.productId == productId &&
      other.productName == productName &&
      other.productImageUrl == productImageUrl &&
      other.variantName == variantName &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice &&
      other.isInStock == isInStock &&
      other.creatorHandle == creatorHandle &&
      other.commissionRate == commissionRate &&
      other.variantId == variantId &&
      identical(other.service, service);

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    productName,
    productImageUrl,
    variantName,
    quantity,
    unitPrice,
    isInStock,
    creatorHandle,
    commissionRate,
    variantId,
  );
}

class Cart {
  const Cart({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.shippingTotal,
    required this.taxTotal,
    required this.total,
    this.discount = const Money(amount: 0, currency: 'NPR'),
    this.supportedCreatorsCount = 0,
    this.appliedPromoCode,
    this.savedForLater = const <SavedForLaterItem>[],
    this.payNowTotal,
    this.payAtVenueTotal,
    this.hasServiceLines = false,
    this.requiresShippingAddress = true,
  });

  final String id;
  final List<CartItem> items;
  final Money subtotal;
  final Money shippingTotal;
  final Money taxTotal;
  final Money total;
  final Money discount;

  /// "You are appreciated" — number of distinct creators this order supports
  /// (backend CartAppreciationSummaryDto.supportedCreatorsCount).
  final int supportedCreatorsCount;
  final AppliedPromoCode? appliedPromoCode;
  final List<SavedForLaterItem> savedForLater;

  /// What checkout will charge online: products after discount plus each
  /// service line's pay-now part (service cart contract v1 §2.3). Null from
  /// a server before that contract — [total] is then what is paid.
  final Money? payNowTotal;

  /// Paid to hotels and agencies at the venue, never through StyleMint.
  final Money? payAtVenueTotal;
  final bool hasServiceLines;

  /// False for a cart of services only: no address, no delivery.
  final bool requiresShippingAddress;

  /// The cart's service lines.
  List<CartItem> get serviceItems =>
      [for (final i in items) if (i.isService) i];

  /// The product lines (never a stay or trip) of [productId] — of
  /// [variantId] only, when it is known. A line the server sent without a
  /// variant counts for the product as a whole.
  List<CartItem> productLines(String productId, {String? variantId}) => [
    for (final i in items)
      if (!i.isService &&
          i.productId == productId &&
          (variantId == null || i.variantId == null || i.variantId == variantId))
        i,
  ];

  /// Units of [productId] (of [variantId] when known) in the cart.
  int productQuantity(String productId, {String? variantId}) =>
      productLines(productId, variantId: variantId)
          .fold<int>(0, (sum, i) => sum + i.quantity);

  /// The service line already holding exactly [options] for [productId],
  /// or null.
  CartItem? serviceLineFor(String productId, ServiceOptions options) {
    for (final i in items) {
      final line = i.service;
      if (line != null &&
          i.productId == productId &&
          line.sameChoiceAs(options)) {
        return i;
      }
    }
    return null;
  }

  Cart copyWith({
    String? id,
    List<CartItem>? items,
    Money? subtotal,
    Money? shippingTotal,
    Money? taxTotal,
    Money? total,
    Money? discount,
    int? supportedCreatorsCount,
    AppliedPromoCode? appliedPromoCode,
    List<SavedForLaterItem>? savedForLater,
  }) {
    return Cart(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingTotal: shippingTotal ?? this.shippingTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      supportedCreatorsCount:
          supportedCreatorsCount ?? this.supportedCreatorsCount,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      savedForLater: savedForLater ?? this.savedForLater,
      payNowTotal: payNowTotal,
      payAtVenueTotal: payAtVenueTotal,
      hasServiceLines: hasServiceLines,
      requiresShippingAddress: requiresShippingAddress,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Cart &&
      other.id == id &&
      _listEquals(other.items, items) &&
      other.subtotal == subtotal &&
      other.shippingTotal == shippingTotal &&
      other.taxTotal == taxTotal &&
      other.total == total &&
      other.discount == discount &&
      other.supportedCreatorsCount == supportedCreatorsCount;

  @override
  int get hashCode => Object.hash(
    id,
    Object.hashAll(items),
    subtotal,
    shippingTotal,
    taxTotal,
    total,
    discount,
    supportedCreatorsCount,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class AppliedPromoCode {
  const AppliedPromoCode({required this.code, required this.discount});

  final String code;
  final Money discount;
}

class SavedForLaterItem {
  const SavedForLaterItem({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String productName;
  final String variantName;
  final String productImageUrl;
  final int quantity;
  final Money unitPrice;
}
