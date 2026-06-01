import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final bool isDefault;

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShippingAddress &&
      other.id == id &&
      other.label == label &&
      other.fullName == fullName &&
      other.phone == phone &&
      other.addressLine1 == addressLine1 &&
      other.addressLine2 == addressLine2 &&
      other.city == city &&
      other.state == state &&
      other.zipCode == zipCode &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        fullName,
        phone,
        addressLine1,
        addressLine2,
        city,
        state,
        zipCode,
        isDefault,
      );
}

enum PaymentMethodType { card, eSewa, cod }

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.lastFour,
    required this.isDefault,
  });

  final String id;
  final PaymentMethodType type;
  final String label;
  final String? lastFour;
  final bool isDefault;

  PaymentMethod copyWith({
    String? id,
    PaymentMethodType? type,
    String? label,
    String? lastFour,
    bool? isDefault,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      lastFour: lastFour ?? this.lastFour,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentMethod &&
      other.id == id &&
      other.type == type &&
      other.label == label &&
      other.lastFour == lastFour &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(id, type, label, lastFour, isDefault);
}

class CheckoutItem {
  const CheckoutItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final String variantName;
  final int quantity;
  final Money unitPrice;

  CheckoutItem copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    String? variantName,
    int? quantity,
    Money? unitPrice,
  }) {
    return CheckoutItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      variantName: variantName ?? this.variantName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CheckoutItem &&
      other.productId == productId &&
      other.productName == productName &&
      other.imageUrl == imageUrl &&
      other.variantName == variantName &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice;

  @override
  int get hashCode => Object.hash(
        productId,
        productName,
        imageUrl,
        variantName,
        quantity,
        unitPrice,
      );
}

class CheckoutSummary {
  const CheckoutSummary({
    required this.shippingAddress,
    required this.paymentMethod,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.discount,
    required this.total,
  });

  final ShippingAddress shippingAddress;
  final PaymentMethod paymentMethod;
  final List<CheckoutItem> items;
  final Money subtotal;
  final Money shipping;
  final Money tax;
  final Money discount;
  final Money total;

  CheckoutSummary copyWith({
    ShippingAddress? shippingAddress,
    PaymentMethod? paymentMethod,
    List<CheckoutItem>? items,
    Money? subtotal,
    Money? shipping,
    Money? tax,
    Money? discount,
    Money? total,
  }) {
    return CheckoutSummary(
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CheckoutSummary &&
      other.shippingAddress == shippingAddress &&
      other.paymentMethod == paymentMethod &&
      _listEquals(other.items, items) &&
      other.subtotal == subtotal &&
      other.shipping == shipping &&
      other.tax == tax &&
      other.discount == discount &&
      other.total == total;

  @override
  int get hashCode => Object.hash(
        shippingAddress,
        paymentMethod,
        Object.hashAll(items),
        subtotal,
        shipping,
        tax,
        discount,
        total,
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
