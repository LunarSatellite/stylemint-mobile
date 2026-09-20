import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/shared/data/option_label.dart';

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // Stores the session ID created by getCheckoutSummary for reuse in placeOrder.
  String? _sessionId;

  // POST /v1/checkout/sessions — creates (or resumes) a checkout session from
  // the current cart. The response carries the same shape as the old GET, plus
  // a `sessionId` field needed for subsequent session-scoped calls.
  Future<CheckoutSummaryDto> getCheckoutSummary() async {
    final response = await apiClient.post(
      '/v1/checkout/sessions',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as Map<String, dynamic>;
    // CheckoutSessionDto's id field is `id`, not `sessionId` — using the
    // wrong key here meant _sessionId was always null, so placeOrder()
    // silently created and operated on a second, different session every
    // time instead of the one the customer was actually looking at.
    _sessionId = data['id'] as String?;
    return CheckoutSummaryDto.fromJson(withOptionLabels(data));
  }

  Future<DeliveryChoices> getDeliveryChoices() async {
    final sessionId = _sessionId ?? await _createSession();
    final response = await apiClient.get(
      '/v1/checkout/sessions/$sessionId/delivery-options',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as Map<String, dynamic>;
    final rawChoices = data['choices'] as List<dynamic>? ?? const [];
    return DeliveryChoices(
      choices: rawChoices
          .map((raw) {
            final item = raw as Map<String, dynamic>;
            final rawKind = item['kind'];
            final isPickup =
                rawKind == 2 ||
                rawKind?.toString().toLowerCase() == 'pickupfromseller';
            return DeliveryChoice(
              kind: isPickup
                  ? DeliveryChoiceKind.pickupFromSeller
                  : DeliveryChoiceKind.homeDelivery,
              title: item['title'] as String? ?? '',
              detail: item['detail'] as String? ?? '',
              deliveries: item['deliveries'] as int? ?? 0,
              readyInDays: item['readyInDays'] as int? ?? 0,
              sellerAccountId: item['sellerAccountId'] as String?,
              sellerName: item['sellerName'] as String?,
              selected: item['selected'] as bool? ?? false,
              recommended: item['recommended'] as bool? ?? false,
              distance: _parseDistance(item['distance']),
              emissions: _parseEmissions(item['emissions']),
            );
          })
          .toList(growable: false),
      emissionsNote: data['emissionsNote'] as String? ?? '',
      pickupNote: data['pickupNote'] as String?,
      preferences: _parseDeliveryPreference(data['preferences']),
      consolidation: _parseConsolidationPlan(data['consolidation']),
      pickupLocations: _parsePickupLocations(data['pickupLocations']),
      pickupLocationsNote: data['pickupLocationsNote'] as String?,
    );
  }

  /// The server's `DeliveryDistanceSummary`, or null when the field is absent
  /// — which is what every response carried before the field existed, and
  /// which means the same thing a withheld figure does: unknown, never zero.
  ///
  /// Two invariants are re-imposed here rather than trusted, because a figure
  /// that escapes its state is the one defect this shape exists to prevent:
  ///
  ///   * a distance is kept **only** when the state is `Measured`. Any figure
  ///     arriving beside a withheld state is dropped, not rounded, not shown.
  ///   * a state that this build cannot read is treated as withheld. An
  ///     unrecognised word is not evidence that something was measured.
  static DeliveryDistanceSummary? _parseDistance(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final state = _parseDistanceState(raw['state']);
    if (state == null) return null;
    final method = _blankToNull(raw['method']);
    // The method never travels separately from the figure. Without it there is
    // nothing honest to render, so the whole summary is dropped.
    if (method == null) return null;
    final rawKm = raw['straightLineKm'];
    final km = rawKm is num ? rawKm.toDouble() : null;
    return DeliveryDistanceSummary(
      state: state,
      journeys: _nonNegativeInt(raw['journeys']),
      journeysMeasured: _nonNegativeInt(raw['journeysMeasured']),
      // Null unless measured. Never 0 in place of null.
      straightLineKm: state == DeliveryDistanceState.measured ? km : null,
      method: method,
      withheldReason: state == DeliveryDistanceState.measured
          ? null
          : _blankToNull(raw['withheldReason']),
    );
  }

  /// A word, per the server's `JsonStringEnumConverter`. The numeric forms are
  /// accepted only because an older serialiser setting could emit them; an
  /// unrecognised value returns null so the caller drops the summary rather
  /// than guessing it into `Measured`.
  static DeliveryDistanceState? _parseDistanceState(Object? raw) {
    if (raw == null) return null;
    final token = raw.toString().toLowerCase();
    for (final value in DeliveryDistanceState.values) {
      if (value.wire.toLowerCase() == token) return value;
    }
    return switch (token) {
      '1' => DeliveryDistanceState.measured,
      '2' => DeliveryDistanceState.originUnknown,
      '3' => DeliveryDistanceState.destinationUnknown,
      '4' => DeliveryDistanceState.bothEndsUnknown,
      '5' => DeliveryDistanceState.noDeliveryJourney,
      _ => null,
    };
  }

  /// Emissions arrive only where a reviewed factor is configured, which is
  /// nowhere. Parsed anyway so that a deployment which configures one is not
  /// silently dropped — and refused outright when the citation is incomplete,
  /// because a mass with no factor version, source or method is a number
  /// nobody can check.
  static DeliveryEmissionsEstimate? _parseEmissions(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final mass = raw['kgCo2e'];
    if (mass is! num) return null;
    final estimate = DeliveryEmissionsEstimate(
      kgCo2e: mass.toDouble(),
      factorVersion: _blankToNull(raw['factorVersion']) ?? '',
      factorSourceUri: _blankToNull(raw['factorSourceUri']) ?? '',
      method: _blankToNull(raw['method']) ?? '',
      factorEffectiveUtc: DateTime.tryParse(
        raw['factorEffectiveUtc']?.toString() ?? '',
      ),
    );
    return estimate.isRenderable ? estimate : null;
  }

  /// A count is a count. A negative or unreadable one is not evidence of a
  /// journey, so it reads as none.
  static int _nonNegativeInt(Object? raw) {
    final value = raw is num ? raw.toInt() : int.tryParse('$raw');
    if (value == null || value < 0) return 0;
    return value;
  }

  /// The server sends `pickupLocations: null` whenever collection is not on
  /// offer, and that is exactly what every response carried before counters
  /// existed — so a null list is an empty list here, never an error.
  static List<PickupLocation> _parsePickupLocations(Object? raw) {
    if (raw is! List) return const [];
    final locations = <PickupLocation>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['locationId'] as String?;
      // A counter with no id cannot be chosen, so it is not offered.
      if (id == null || id.isEmpty) continue;
      locations.add(
        PickupLocation(
          id: id,
          name: _blankToNull(entry['name']),
          addressLine: _blankToNull(entry['addressLine']),
          city: _blankToNull(entry['city']),
          openingHours: _blankToNull(entry['openingHours']),
          confirmation: _parseConfirmation(entry['confirmation']),
          confirmationNote: _blankToNull(entry['confirmationNote']),
          selected: entry['selected'] as bool? ?? false,
        ),
      );
    }
    return List.unmodifiable(locations);
  }

  /// An unrecorded field and a field recorded as whitespace are the same thing
  /// to a reader, and both must render as absent rather than as a blank line.
  static String? _blankToNull(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static PickupLocationConfirmation _parseConfirmation(Object? raw) {
    final token = raw?.toString().toLowerCase();
    return switch (token) {
      'confirmed' || '2' => PickupLocationConfirmation.confirmed,
      'stale' || '3' => PickupLocationConfirmation.stale,
      // Anything unrecognised is not evidence of freshness. Fall to the reading
      // that tells the shopper to check before travelling — the same direction
      // the server's own mapper fails in.
      _ => PickupLocationConfirmation.neverConfirmed,
    };
  }

  Future<DeliveryPreference> updateDeliveryPreference(
    DeliveryPreference preference,
  ) async {
    final response = await apiClient.put(
      '/v1/checkout/delivery-preferences',
      data: {
        'preferFewerDeliveries': preference.preferFewerDeliveries,
        'preferPickup': preference.preferPickup,
        'maximumExtraWaitDays': preference.maximumExtraWaitDays,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key':
              'delivery-preference-'
              '${preference.preferFewerDeliveries}-'
              '${preference.preferPickup}-'
              '${preference.maximumExtraWaitDays}',
        },
      ),
    );
    return _parseDeliveryPreference(response);
  }

  static DeliveryConsolidationPlan? _parseConsolidationPlan(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return DeliveryConsolidationPlan(
      itemUnits: raw['itemUnits'] as int? ?? 0,
      sellerPackages: raw['sellerPackages'] as int? ?? 0,
      packagesAvoidedBySellerGrouping:
          raw['packagesAvoidedBySellerGrouping'] as int? ?? 0,
      readyInDays: raw['readyInDays'] as int? ?? 0,
      crossSellerConsolidationAvailable:
          raw['crossSellerConsolidationAvailable'] as bool? ?? false,
      explanation: raw['explanation'] as String? ?? '',
    );
  }

  static DeliveryPreference _parseDeliveryPreference(Object? raw) {
    if (raw is! Map<String, dynamic>) return const DeliveryPreference();
    return DeliveryPreference(
      preferFewerDeliveries: raw['preferFewerDeliveries'] as bool? ?? false,
      preferPickup: raw['preferPickup'] as bool? ?? false,
      maximumExtraWaitDays: raw['maximumExtraWaitDays'] as int? ?? 0,
    );
  }

  Future<void> selectDeliveryChoice(DeliveryChoice choice) async {
    final sessionId = _sessionId ?? await _createSession();
    if (choice.kind == DeliveryChoiceKind.pickupFromSeller) {
      final sellerId = choice.sellerAccountId;
      if (sellerId == null || sellerId.isEmpty) {
        throw StateError('Pickup choice has no seller account.');
      }
      await apiClient.post(
        '/v1/checkout/sessions/$sessionId/pickup',
        data: {'pickupVendorAccountId': sellerId},
        options: Options(
          headers: {
            'requiresToken': true,
            'Idempotency-Key': 'checkout-pickup-$sessionId-$sellerId',
          },
        ),
      );
    } else {
      await apiClient.post(
        '/v1/checkout/sessions/$sessionId/delivery',
        options: Options(
          headers: {
            'requiresToken': true,
            'Idempotency-Key': 'checkout-delivery-$sessionId',
          },
        ),
      );
    }
  }

  /// Names which of the seller's counters the shopper will collect from.
  ///
  /// This is the same `/pickup` call [selectDeliveryChoice] already makes, with
  /// `pickupLocationId` added — the endpoint has accepted that field all along.
  /// It sets no price, reserves no stock and moves no money; it records a
  /// choice.
  ///
  /// The idempotency key deliberately includes [locationId]. The pickup key
  /// without it is already spent by [selectDeliveryChoice] for this session and
  /// seller, so reusing it would have the server replay that earlier response
  /// and quietly drop the counter — the choice would look accepted and never be
  /// recorded.
  Future<void> selectPickupLocation({
    required String sellerId,
    required String locationId,
  }) async {
    final sessionId = _sessionId ?? await _createSession();
    await apiClient.post(
      '/v1/checkout/sessions/$sessionId/pickup',
      data: {
        'pickupVendorAccountId': sellerId,
        'pickupLocationId': locationId,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': 'checkout-pickup-$sessionId-$sellerId-$locationId',
        },
      ),
    );
  }

  Future<List<ShippingAddressDto>> getShippingAddresses() async {
    final response = await apiClient.get(
      '/v1/addresses',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as List<dynamic>;
    return data
        .map((e) => ShippingAddressDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PaymentMethodDto>> getPaymentMethods() async {
    final response = await apiClient.get(
      '/v1/payments/saved-methods',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as List<dynamic>;
    return data
        .map((e) => PaymentMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // Backend CheckoutSession.PaymentMethod enum (StyleMint.Modules.CartCheckout
  // .Enums.PaymentMethod) — CardVisaMastercard=1, PayPal=2, Esewa=3,
  // CashOnDelivery=4. Values are locked, never renumbered.
  static int _paymentMethodCode(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.card:
        return 1;
      case PaymentMethodType.paypal:
        return 2;
      case PaymentMethodType.eSewa:
        return 3;
      case PaymentMethodType.cod:
        return 4;
    }
  }

  // Multi-step checkout session flow:
  //   1. Ensure a session exists (create one if _sessionId is null)
  //   2. PATCH address onto the session
  //   3. PATCH payment method onto the session
  //   4. POST place — returns the order number (e.g. "NK2026-00001").
  //      Every downstream order route (detail/invoice/cancel — see
  //      OrdersRemoteDataSource, track_orders_screen.dart) is keyed by this
  //      human-readable order number, not the internal orderId GUID that
  //      also comes back on this response — returning the GUID here caused
  //      the post-purchase "View Order" button to 404 while the exact same
  //      order loaded fine from the Track Order list moments later.
  Future<PlaceOrderResult> placeOrder({
    required String? addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async {
    final sessionId = _sessionId ?? await _createSession();

    if (addressId != null && addressId.isNotEmpty) {
      await apiClient.post(
        '/v1/checkout/sessions/$sessionId/address',
        data: {'addressId': addressId},
        options: Options(headers: {'requiresToken': true}),
      );
    }

    // Backend wants which payment TYPE was chosen (a closed enum), not a
    // saved payment-instrument id — SetCheckoutPaymentMethodVm.PaymentMethod.
    await apiClient.post(
      '/v1/checkout/sessions/$sessionId/payment-method',
      data: {'paymentMethod': _paymentMethodCode(paymentMethod)},
      options: Options(headers: {'requiresToken': true}),
    );

    final response = await apiClient.post(
      '/v1/checkout/sessions/$sessionId/place',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );

    _sessionId = null; // clear after successful placement
    final data = response as Map<String, dynamic>;
    // Cash on Delivery has nothing further for the customer to do — the
    // order is paid-on-fulfillment. PayPal/eSewa/Card come back with
    // paymentRequiresAction=true and a paymentRedirectUrl the customer
    // must complete before the payment is actually captured (the provider's
    // webhook, not this response, is what marks the order paid).
    return PlaceOrderResult(
      orderNumber: data['orderNumber'] as String,
      requiresPaymentAction: data['paymentRequiresAction'] as bool? ?? false,
      paymentRedirectUrl: data['paymentRedirectUrl'] as String?,
    );
  }

  Future<String> _createSession() async {
    final response = await apiClient.post(
      '/v1/checkout/sessions',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as Map<String, dynamic>;
    final id = data['id'] as String?;
    if (id == null)
      throw Exception('Checkout session creation returned no sessionId');
    _sessionId = id;
    return id;
  }
}
