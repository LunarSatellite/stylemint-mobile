import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    this.stateProvince,
    this.postalCode,
    required this.countryCode,
    required this.isDefault,
    this.rowVersion = '',
  });

  /// Sentinel "nothing selected yet" address — a checkout session doesn't
  /// carry a default address the way the old flat summary did, so callers
  /// use this until the customer picks one from [availableAddresses].
  /// [CheckoutScreen] already treats an empty `line1` as "no address".
  const ShippingAddress.empty()
      : id = '',
        label = '',
        line1 = '',
        line2 = null,
        city = '',
        stateProvince = null,
        postalCode = null,
        countryCode = '',
        isDefault = false,
        rowVersion = '';

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String? stateProvince;
  final String? postalCode;
  final String countryCode;
  final bool isDefault;
  final String rowVersion;

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? countryCode,
    bool? isDefault,
    String? rowVersion,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      stateProvince: stateProvince ?? this.stateProvince,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode ?? this.countryCode,
      isDefault: isDefault ?? this.isDefault,
      rowVersion: rowVersion ?? this.rowVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShippingAddress &&
      other.id == id &&
      other.label == label &&
      other.line1 == line1 &&
      other.line2 == line2 &&
      other.city == city &&
      other.stateProvince == stateProvince &&
      other.postalCode == postalCode &&
      other.countryCode == countryCode &&
      other.isDefault == isDefault;

  @override
  int get hashCode => Object.hash(
        id,
        label,
        line1,
        line2,
        city,
        stateProvince,
        postalCode,
        countryCode,
        isDefault,
      );
}

enum PaymentMethodType { card, eSewa, cod, paypal }

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

  /// Sentinel "nothing selected yet" payment method — see [ShippingAddress.empty].
  const PaymentMethod.empty()
      : id = '',
        type = PaymentMethodType.cod,
        label = '',
        lastFour = null,
        isDefault = false;

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
    this.availableAddresses = const [],
    this.availablePaymentMethods = const [],
  });

  final ShippingAddress shippingAddress;
  final PaymentMethod paymentMethod;
  final List<CheckoutItem> items;
  final Money subtotal;
  final Money shipping;
  final Money tax;
  final Money discount;
  final Money total;
  /// Saved addresses from the addresses API. First entry is always [shippingAddress].
  final List<ShippingAddress> availableAddresses;
  /// Saved payment methods from the payment-methods API. First entry is always [paymentMethod].
  final List<PaymentMethod> availablePaymentMethods;

  CheckoutSummary copyWith({
    ShippingAddress? shippingAddress,
    PaymentMethod? paymentMethod,
    List<CheckoutItem>? items,
    Money? subtotal,
    Money? shipping,
    Money? tax,
    Money? discount,
    Money? total,
    List<ShippingAddress>? availableAddresses,
    List<PaymentMethod>? availablePaymentMethods,
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
      availableAddresses: availableAddresses ?? this.availableAddresses,
      availablePaymentMethods:
          availablePaymentMethods ?? this.availablePaymentMethods,
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
      other.total == total &&
      _listEquals(other.availableAddresses, availableAddresses) &&
      _listEquals(other.availablePaymentMethods, availablePaymentMethods);

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
        Object.hashAll(availableAddresses),
        Object.hashAll(availablePaymentMethods),
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
