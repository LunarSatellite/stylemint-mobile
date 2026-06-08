import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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
  }) {
    return CartItem(
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
      other.commissionRate == commissionRate;

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
    this.supportedCreatorsCount = 0,
  });

  final String id;
  final List<CartItem> items;
  final Money subtotal;
  final Money shippingTotal;
  final Money taxTotal;
  final Money total;

  /// "You are appreciated" — number of distinct creators this order supports
  /// (backend CartAppreciationSummaryDto.supportedCreatorsCount).
  final int supportedCreatorsCount;

  Cart copyWith({
    String? id,
    List<CartItem>? items,
    Money? subtotal,
    Money? shippingTotal,
    Money? taxTotal,
    Money? total,
    int? supportedCreatorsCount,
  }) {
    return Cart(
      id: id ?? this.id,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shippingTotal: shippingTotal ?? this.shippingTotal,
      taxTotal: taxTotal ?? this.taxTotal,
      total: total ?? this.total,
      supportedCreatorsCount:
          supportedCreatorsCount ?? this.supportedCreatorsCount,
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
      other.supportedCreatorsCount == supportedCreatorsCount;

  @override
  int get hashCode => Object.hash(
        id,
        Object.hashAll(items),
        subtotal,
        shippingTotal,
        taxTotal,
        total,
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
