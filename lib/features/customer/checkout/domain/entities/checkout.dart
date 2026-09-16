import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A shipping address as checkout sees it.
///
/// Customers no longer type a street, city, state or postal code — they save
/// a point (GPS, a dragged pin, or a pasted Maps link) plus a note explaining
/// how to find the door. Every postal field below is therefore **nullable**:
/// they survive only on legacy addresses, and rendering must never turn a
/// null city into a blank line or the text "null".
class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.countryCode,
    required this.isDefault,
    this.locationNote = '',
    this.mapsLink,
    this.latitude,
    this.longitude,
    this.line1,
    this.line2,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.rowVersion = '',
  });

  /// Sentinel "nothing selected yet" address — a checkout session doesn't
  /// carry a default address the way the old flat summary did, so callers
  /// use this until the customer picks one from [availableAddresses].
  /// Emptiness is keyed off [id]: a location-captured address has no `line1`
  /// at all, so the old "blank line1 means no address" test would have hidden
  /// every new address from checkout.
  const ShippingAddress.empty()
      : id = '',
        label = '',
        countryCode = '',
        isDefault = false,
        locationNote = '',
        mapsLink = null,
        latitude = null,
        longitude = null,
        line1 = null,
        line2 = null,
        city = null,
        stateProvince = null,
        postalCode = null,
        rowVersion = '';

  final String id;
  final String label;
  final String countryCode;
  final bool isDefault;

  /// "How do we find it?" — the customer's own directions. Optional.
  final String locationNote;

  /// The Maps link the customer pasted, stored verbatim.
  final String? mapsLink;

  final double? latitude;
  final double? longitude;

  // ── Legacy postal fields — never collected, often null. ──────────────────
  final String? line1;
  final String? line2;
  final String? city;
  final String? stateProvince;
  final String? postalCode;

  final String rowVersion;

  /// True for the [ShippingAddress.empty] sentinel.
  bool get isEmpty => id.trim().isEmpty;

  bool get hasPoint => latitude != null && longitude != null;

  bool get hasMapsLink => (mapsLink ?? '').trim().isNotEmpty;

  bool get hasLocation => hasPoint || hasMapsLink;

  /// Legacy postal text as one line, with every null/blank part dropped.
  String get legacyPostalLine => [
        line1,
        line2,
        city,
        stateProvince,
        postalCode,
      ].map((p) => p?.trim() ?? '').where((p) => p.isNotEmpty).join(', ');

  String get pointLabel => hasPoint
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : '';

  /// The single line to render for this address anywhere in checkout. Never
  /// blank, never "null".
  String get summaryLine {
    final note = locationNote.trim();
    if (note.isNotEmpty) return note;
    final postal = legacyPostalLine;
    if (postal.isNotEmpty) return postal;
    if (hasPoint) return pointLabel;
    if (hasMapsLink) return mapsLink!.trim();
    return 'Location saved';
  }

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? countryCode,
    bool? isDefault,
    String? locationNote,
    String? mapsLink,
    double? latitude,
    double? longitude,
    String? line1,
    String? line2,
    String? city,
    String? stateProvince,
    String? postalCode,
    String? rowVersion,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      countryCode: countryCode ?? this.countryCode,
      isDefault: isDefault ?? this.isDefault,
      locationNote: locationNote ?? this.locationNote,
      mapsLink: mapsLink ?? this.mapsLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      stateProvince: stateProvince ?? this.stateProvince,
      postalCode: postalCode ?? this.postalCode,
      rowVersion: rowVersion ?? this.rowVersion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShippingAddress &&
      other.id == id &&
      other.label == label &&
      other.locationNote == locationNote &&
      other.mapsLink == mapsLink &&
      other.latitude == latitude &&
      other.longitude == longitude &&
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
        locationNote,
        mapsLink,
        latitude,
        longitude,
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

/// The four v1 payment rails supported by Style Mint. A saved card only
/// enriches the card row with its display data; it must never hide the other
/// payment choices at checkout.
List<PaymentMethod> checkoutPaymentMethods({PaymentMethod? savedCard}) {
  final card = savedCard?.type == PaymentMethodType.card ? savedCard : null;
  return [
    PaymentMethod(
      id: card?.id ?? 'card',
      type: PaymentMethodType.card,
      label: card?.label ?? 'Visa / Mastercard',
      lastFour: card?.lastFour,
      isDefault: card?.isDefault ?? false,
    ),
    const PaymentMethod(
      id: 'paypal',
      type: PaymentMethodType.paypal,
      label: 'PayPal',
      isDefault: false,
    ),
    const PaymentMethod(
      id: 'esewa',
      type: PaymentMethodType.eSewa,
      label: 'eSewa',
      isDefault: false,
    ),
    const PaymentMethod(
      id: 'cod',
      type: PaymentMethodType.cod,
      label: 'Cash on Delivery',
      isDefault: false,
    ),
  ];
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

/// Result of placing an order. Cash on Delivery has nothing further for the
/// customer to do ([requiresPaymentAction] is false). PayPal/eSewa/Card come
/// back with [requiresPaymentAction] true and a [paymentRedirectUrl] the
/// customer must complete — the payment is NOT captured yet just because
/// this call returned; the provider's webhook is what actually marks the
/// order paid. Showing an unconditional "Payment successful" screen for
/// every payment method (as this app used to) falsely confirms purchases
/// that were never actually charged.
class PlaceOrderResult {
  const PlaceOrderResult({
    required this.orderNumber,
    required this.requiresPaymentAction,
    this.paymentRedirectUrl,
  });

  final String orderNumber;
  final bool requiresPaymentAction;
  final String? paymentRedirectUrl;
}
