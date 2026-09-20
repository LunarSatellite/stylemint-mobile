import 'package:flutter/foundation.dart' show immutable;
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

enum DeliveryChoiceKind { homeDelivery, pickupFromSeller }

/// Whether a delivery option's distance could be measured, and when it could
/// not, which end was missing — backend `DeliveryDistanceState`, serialised as
/// a word and never as a number.
///
/// Read this before [DeliveryDistanceSummary.straightLineKm]. The state is the
/// answer; the number is only ever a detail of one state.
enum DeliveryDistanceState {
  /// Every journey had a known start and a known end, so
  /// [DeliveryDistanceSummary.straightLineKm] carries a figure. That figure
  /// may legitimately be `0.0` — two points close enough together round to
  /// zero — and here `0.0` means measured-and-tiny, never unknown.
  measured('Measured'),

  /// At least one seller has no recorded location carrying coordinates.
  originUnknown('OriginUnknown'),

  /// The delivery address on this checkout has no coordinates recorded.
  destinationUnknown('DestinationUnknown'),

  /// Neither end is known.
  bothEndsUnknown('BothEndsUnknown'),

  /// There is no delivery journey to measure — collection is the case. This is
  /// *not* a measured zero distance: the shopper still travels, and this
  /// platform does not know where they would set out from.
  noDeliveryJourney('NoDeliveryJourney');

  const DeliveryDistanceState(this.wire);

  final String wire;

  /// True for every state except [measured]. A withheld figure is unknown,
  /// never zero.
  bool get isWithheld => this != DeliveryDistanceState.measured;
}

/// What this checkout can honestly say about how far a delivery option travels
/// — backend `DeliveryDistanceSummary`.
///
/// [straightLineKm] is a great-circle distance and nothing else. A vehicle
/// travels further, always, so [method] — which says exactly that — is
/// rendered with the figure and never separately from it.
///
/// There is deliberately no "estimated distance" here and no fallback. Null is
/// the only way "we don't know" is expressed, it is never `0`, and a partial
/// sum is never shown: if one journey of three could not be measured the whole
/// figure is withheld, because a sum missing a leg reads as complete *and
/// shorter than the truth*.
@immutable
class DeliveryDistanceSummary {
  const DeliveryDistanceSummary({
    required this.state,
    required this.journeys,
    required this.journeysMeasured,
    required this.method,
    this.straightLineKm,
    this.withheldReason,
  });

  final DeliveryDistanceState state;

  /// Separate delivery journeys this option needs: one per seller for home
  /// delivery, none for collection. A count this platform records rather than
  /// estimates — available whether or not any coordinate is known, which is
  /// why collection is `0` journeys with the distance withheld and not a
  /// distance of zero.
  final int journeys;

  /// How many of [journeys] had both endpoints known.
  final int journeysMeasured;

  /// Total straight-line kilometres, or null whenever [state] is anything
  /// other than [DeliveryDistanceState.measured].
  final double? straightLineKm;

  /// The server's own sentence about how the figure was produced and what it
  /// is not. Always populated, on measured and withheld alike. Rendered
  /// verbatim — paraphrasing it is how a straight line becomes "distance
  /// travelled".
  final String method;

  /// Why no figure is shown, in the server's own words. Null exactly when
  /// [state] is [DeliveryDistanceState.measured]; non-null otherwise, so "we
  /// don't know" is never silent.
  final String? withheldReason;

  /// True only when the state says measured *and* a figure actually arrived.
  /// Anything less renders as an absence with its reason, never as a number.
  bool get hasFigure =>
      state == DeliveryDistanceState.measured && straightLineKm != null;

  @override
  bool operator ==(Object other) =>
      other is DeliveryDistanceSummary &&
      other.state == state &&
      other.journeys == journeys &&
      other.journeysMeasured == journeysMeasured &&
      other.straightLineKm == straightLineKm &&
      other.method == method &&
      other.withheldReason == withheldReason;

  @override
  int get hashCode => Object.hash(
    state,
    journeys,
    journeysMeasured,
    straightLineKm,
    method,
    withheldReason,
  );
}

/// Transport emissions for one delivery option — backend
/// `DeliveryEmissionsEstimate`.
///
/// Null on every response this platform currently produces: turning a distance
/// into a mass needs a reviewed factor, the one place that holds reviewed
/// factors is deliberately blank, and null here means "we are not entitled to
/// state a figure", never "this emits nothing".
///
/// The mass is never renderable on its own. [factorVersion], [factorSourceUri]
/// and [method] are what make it a citation rather than a claim, so
/// [isRenderable] refuses the whole estimate when any of them is missing.
@immutable
class DeliveryEmissionsEstimate {
  const DeliveryEmissionsEstimate({
    required this.kgCo2e,
    required this.factorVersion,
    required this.factorSourceUri,
    required this.method,
    this.factorEffectiveUtc,
  });

  final double kgCo2e;
  final String factorVersion;
  final String factorSourceUri;
  final String method;
  final DateTime? factorEffectiveUtc;

  /// A mass with no factor version, no source and no method is an unsourced
  /// number. It is not shown at all rather than shown bare.
  bool get isRenderable =>
      factorVersion.trim().isNotEmpty &&
      factorSourceUri.trim().isNotEmpty &&
      method.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is DeliveryEmissionsEstimate &&
      other.kgCo2e == kgCo2e &&
      other.factorVersion == factorVersion &&
      other.factorSourceUri == factorSourceUri &&
      other.method == method &&
      other.factorEffectiveUtc == factorEffectiveUtc;

  @override
  int get hashCode => Object.hash(
    kgCo2e,
    factorVersion,
    factorSourceUri,
    method,
    factorEffectiveUtc,
  );
}

class DeliveryChoice {
  const DeliveryChoice({
    required this.kind,
    required this.title,
    required this.detail,
    required this.deliveries,
    required this.readyInDays,
    required this.selected,
    this.recommended = false,
    this.sellerAccountId,
    this.sellerName,
    this.distance,
    this.emissions,
  });
  final DeliveryChoiceKind kind;
  final String title;
  final String detail;
  final int deliveries;
  final int readyInDays;
  final String? sellerAccountId;
  final String? sellerName;
  final bool selected;
  final bool recommended;

  /// How far this option travels, when both ends are recorded, and the
  /// server's explanation when they are not. Null is what every response
  /// carried before the field existed, and it means the same thing a withheld
  /// figure does: unknown, never zero.
  final DeliveryDistanceSummary? distance;

  /// Null on every deployment that holds no reviewed emissions factor, which
  /// is all of them. Never rendered as zero.
  final DeliveryEmissionsEstimate? emissions;

  DeliveryChoice copyWith({bool? selected}) => DeliveryChoice(
    kind: kind,
    title: title,
    detail: detail,
    deliveries: deliveries,
    readyInDays: readyInDays,
    sellerAccountId: sellerAccountId,
    sellerName: sellerName,
    selected: selected ?? this.selected,
    recommended: recommended,
    distance: distance,
    emissions: emissions,
  );
}

class DeliveryPreference {
  const DeliveryPreference({
    this.preferFewerDeliveries = false,
    this.preferPickup = false,
    this.maximumExtraWaitDays = 0,
  });
  final bool preferFewerDeliveries;
  final bool preferPickup;
  final int maximumExtraWaitDays;

  DeliveryPreference copyWith({
    bool? preferFewerDeliveries,
    bool? preferPickup,
    int? maximumExtraWaitDays,
  }) => DeliveryPreference(
    preferFewerDeliveries: preferFewerDeliveries ?? this.preferFewerDeliveries,
    preferPickup: preferPickup ?? this.preferPickup,
    maximumExtraWaitDays: maximumExtraWaitDays ?? this.maximumExtraWaitDays,
  );
}

class DeliveryConsolidationPlan {
  const DeliveryConsolidationPlan({
    required this.itemUnits,
    required this.sellerPackages,
    required this.packagesAvoidedBySellerGrouping,
    required this.readyInDays,
    required this.crossSellerConsolidationAvailable,
    required this.explanation,
  });
  final int itemUnits;
  final int sellerPackages;
  final int packagesAvoidedBySellerGrouping;
  final int readyInDays;
  final bool crossSellerConsolidationAvailable;
  final String explanation;
}

/// How much weight to give a counter's recorded details, as the registry
/// classifies it. Mirrors the server's `PickupLocationConfirmation`.
enum PickupLocationConfirmation { neverConfirmed, confirmed, stale }

/// One collection counter a seller has recorded, exactly as
/// `codes.vendor_stores` holds it.
///
/// Every text field here is nullable-or-blank on purpose. The registry records
/// what a seller typed and nothing more, so a counter can genuinely have no
/// name, no address or no opening hours — and the picker renders each of
/// those absences as an absence rather than substituting a plausible-looking
/// stand-in.
/// There is no "open now" here and there cannot be: [openingHours] is free text
/// with no timezone, holiday or break model behind it, so it can be shown
/// verbatim but never interpreted.
///
/// There is deliberately no distance and no stock field. The server reports
/// stock as `Unknown` for every counter (no per-location inventory exists).
/// Distance is absent for a different reason: the server measures from a
/// seller's recorded store address to the *delivery address* on the checkout,
/// and a counter the shopper travels to is neither of those. The platform does
/// not know where a shopper would set out from, so no counter carries a
/// distance — see [DeliveryDistanceSummary], which withholds for exactly that
/// reason on the collection option itself.
@immutable
class PickupLocation {
  const PickupLocation({
    required this.id,
    this.name,
    this.addressLine,
    this.city,
    this.openingHours,
    this.confirmation = PickupLocationConfirmation.neverConfirmed,
    this.confirmationNote,
    this.selected = false,
  });

  final String id;

  /// What the seller named this counter, or null when they named it nothing.
  final String? name;
  final String? addressLine;
  final String? city;

  /// Free text, exactly as typed; null when no hours were recorded. Never
  /// parsed into an open/closed state.
  final String? openingHours;

  final PickupLocationConfirmation confirmation;

  /// The server's own sentence about [confirmation]; never composed here.
  final String? confirmationNote;

  /// Whether the session is already set to collect from this counter.
  final bool selected;

  /// True when the registry holds nothing a shopper could identify this counter
  /// by. The picker says so plainly instead of rendering a blank row.
  bool get hasNoRecordedDetails =>
      (name == null || name!.trim().isEmpty) &&
      (addressLine == null || addressLine!.trim().isEmpty) &&
      (city == null || city!.trim().isEmpty);

  PickupLocation copyWith({bool? selected}) => PickupLocation(
    id: id,
    name: name,
    addressLine: addressLine,
    city: city,
    openingHours: openingHours,
    confirmation: confirmation,
    confirmationNote: confirmationNote,
    selected: selected ?? this.selected,
  );

  @override
  bool operator ==(Object other) =>
      other is PickupLocation &&
      other.id == id &&
      other.name == name &&
      other.addressLine == addressLine &&
      other.city == city &&
      other.openingHours == openingHours &&
      other.confirmation == confirmation &&
      other.confirmationNote == confirmationNote &&
      other.selected == selected;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    addressLine,
    city,
    openingHours,
    confirmation,
    confirmationNote,
    selected,
  );
}

class DeliveryChoices {
  const DeliveryChoices({
    required this.choices,
    required this.emissionsNote,
    this.pickupNote,
    this.preferences = const DeliveryPreference(),
    this.consolidation,
    this.pickupLocations = const [],
    this.pickupLocationsNote,
  });
  final List<DeliveryChoice> choices;
  final String emissionsNote;
  final String? pickupNote;
  final DeliveryPreference preferences;
  final DeliveryConsolidationPlan? consolidation;

  /// The seller's recorded counters, when collection is on offer and the
  /// server carried any. Empty means "we know of none" — which is the normal,
  /// supported case for a seller who has registered no counter, and collection
  /// still works without one.
  final List<PickupLocation> pickupLocations;

  /// The server's sentence about what the list above does and does not mean.
  final String? pickupLocationsNote;
}

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
    this.deliveryChoices = const [],
    this.emissionsNote = '',
    this.pickupNote,
    this.deliveryPreference = const DeliveryPreference(),
    this.deliveryConsolidation,
    this.pickupLocations = const [],
    this.pickupLocationsNote,
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
  final List<DeliveryChoice> deliveryChoices;
  final String emissionsNote;
  final String? pickupNote;
  final DeliveryPreference deliveryPreference;
  final DeliveryConsolidationPlan? deliveryConsolidation;

  /// The counters the selected seller has recorded. Empty is the ordinary case
  /// for a seller with no registered counter, and nothing downstream requires
  /// an entry here.
  final List<PickupLocation> pickupLocations;
  final String? pickupLocationsNote;

  /// The counter this session is set to collect from, or null when none has
  /// been chosen. Null is a valid, final state — the order records no counter.
  PickupLocation? get selectedPickupLocation {
    for (final location in pickupLocations) {
      if (location.selected) return location;
    }
    return null;
  }

  DeliveryChoice? get selectedDeliveryChoice {
    for (final choice in deliveryChoices) {
      if (choice.selected) return choice;
    }
    return deliveryChoices.isEmpty ? null : deliveryChoices.first;
  }

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
    List<DeliveryChoice>? deliveryChoices,
    String? emissionsNote,
    String? pickupNote,
    DeliveryPreference? deliveryPreference,
    DeliveryConsolidationPlan? deliveryConsolidation,
    List<PickupLocation>? pickupLocations,
    String? pickupLocationsNote,
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
      deliveryChoices: deliveryChoices ?? this.deliveryChoices,
      emissionsNote: emissionsNote ?? this.emissionsNote,
      pickupNote: pickupNote ?? this.pickupNote,
      deliveryPreference: deliveryPreference ?? this.deliveryPreference,
      deliveryConsolidation:
          deliveryConsolidation ?? this.deliveryConsolidation,
      pickupLocations: pickupLocations ?? this.pickupLocations,
      pickupLocationsNote: pickupLocationsNote ?? this.pickupLocationsNote,
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
