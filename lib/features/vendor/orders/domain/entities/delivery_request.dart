import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Where a "find a delivery partner" request has got to. Mirrors the
/// delivery-selection contract's `state` string.
///
/// Riders within the radius are notified and tap "I'm interested"; nothing is
/// assigned until the vendor picks one. So unlike the old directed offer,
/// there is a waiting period the vendor watches, and every state here is
/// something the sheet has to say differently.
enum DeliveryRequestState {
  /// Riders were notified and none has answered yet.
  searching('Searching'),

  /// At least one rider is interested; the vendor can choose.
  ridersInterested('RidersInterested'),

  /// The vendor chose and the rider has the hop.
  assigned('Assigned'),

  /// The request closed with nobody chosen.
  expired('Expired'),

  /// The request is open but nobody eligible was in range to notify.
  noRiders('NoRiders');

  const DeliveryRequestState(this.wire);

  final String wire;

  /// Tolerant on purpose: the contract says strings, but a backend still on a
  /// numeric enum (1-based, in contract order) is read too, and anything
  /// unrecognised is null so the caller can fall back on what it does know.
  static DeliveryRequestState? fromWire(Object? value) {
    if (value is num) {
      final index = value.toInt() - 1;
      return index >= 0 && index < values.length ? values[index] : null;
    }
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    if (raw == null || raw.isEmpty) return null;
    for (final state in values) {
      if (state.wire.toLowerCase() == raw) return state;
    }
    return null;
  }

  /// Polling stops here: nothing more will change without the vendor acting.
  bool get isSettled =>
      this == DeliveryRequestState.assigned ||
      this == DeliveryRequestState.expired;
}

/// A rider who said they would take the parcel.
class InterestedRider {
  const InterestedRider({
    required this.offerId,
    required this.courierId,
    required this.displayName,
    required this.tier,
    required this.rating,
    required this.completedDeliveries,
    required this.distanceKm,
    this.avatarUrl,
    this.vehicle,
    this.interestedUtc,
    this.ratingCount,
    this.verified,
    this.fare,
  });

  factory InterestedRider.fromJson(Map<String, dynamic> json) {
    final rating = _double(json['rating']);
    final count = json['ratingCount'];
    final verified = json['verified'];
    return InterestedRider(
      fare: _money(json['fare']),
      offerId: _string(json['offerId']),
      courierId: _string(json['courierId']),
      displayName: _string(json['displayName']).isEmpty
          ? 'StyleMint rider'
          : _string(json['displayName']),
      avatarUrl: _stringOrNull(json['avatarUrl']),
      tier: riderTierLabel(json['tier']),
      // Null (fewer than 3 ratings) and zero both read "New rider".
      rating: rating > 0 ? rating : null,
      completedDeliveries: _double(json['completedDeliveries']).toInt(),
      distanceKm: _double(json['distanceKm']),
      vehicle: riderVehicleLabel(json['vehicle']),
      interestedUtc: _date(json['interestedUtc']),
      ratingCount: count == null ? null : _double(count).toInt(),
      verified: verified is bool
          ? verified
          : verified == null
          ? null
          : verified.toString().toLowerCase() == 'true',
    );
  }

  /// What the vendor names when choosing — the select call takes this, not
  /// the courier id.
  final String offerId;
  final String courierId;
  final String displayName;
  final String? avatarUrl;

  /// Neighbour, Traveller or Pro, already worded for a vendor.
  final String tier;

  /// The average of their ratings; null until they have three — the card
  /// says "New rider" rather than showing a zero or a one-review score.
  final double? rating;
  final int completedDeliveries;
  final double distanceKm;
  final String? vehicle;
  final DateTime? interestedUtc;

  /// How many ratings [rating] averages. Null from a backend before the
  /// rider-rating contract.
  final int? ratingCount;

  /// KYC approved. Null when the server does not say — no tick is drawn,
  /// which is not the same as "unverified".
  final bool? verified;

  /// The fixed fare of this rider's offer (return pickup contract §4); null
  /// from a server that does not send it.
  final Money? fare;

  bool get isNew => rating == null;
}

/// The rider the vendor chose.
class AssignedRider {
  const AssignedRider({
    required this.courierId,
    required this.displayName,
    this.avatarUrl,
    this.phone,
  });

  factory AssignedRider.fromJson(Map<String, dynamic> json) => AssignedRider(
    courierId: _string(json['courierId']),
    displayName: _string(json['displayName']).isEmpty
        ? 'Your rider'
        : _string(json['displayName']),
    avatarUrl: _stringOrNull(json['avatarUrl']),
    phone: _stringOrNull(json['phone']),
  );

  final String courierId;
  final String displayName;
  final String? avatarUrl;

  /// Masked by the server, or null. Shown as given — never unmasked here.
  final String? phone;
}

/// The open "find a delivery partner" request for one sub-order.
class DeliveryRequest {
  const DeliveryRequest({
    required this.packageId,
    required this.state,
    required this.notifiedCount,
    required this.radiusKm,
    required this.interested,
    this.openedUtc,
    this.expiresUtc,
    this.assigned,
    this.noRidersReason,
    this.canUseVerifiedRider = false,
    this.verifiedRiderConsentUtc,
    this.kind = DeliveryRequestKind.delivery,
    this.returnRequestId,
  });

  factory DeliveryRequest.fromJson(Map<String, dynamic> json) {
    final interested = (json['interested'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(InterestedRider.fromJson)
        .where((rider) => rider.offerId.isNotEmpty)
        .toList(growable: false);
    final assignedJson = json['assigned'];
    final assigned = assignedJson is Map<String, dynamic>
        ? AssignedRider.fromJson(assignedJson)
        : null;

    // An unknown state is read from what the payload does carry, rather
    // than defaulting to one that would show the vendor the wrong panel: a
    // rider assigned is assigned, and riders listed means there is a choice.
    final state =
        DeliveryRequestState.fromWire(json['state']) ??
        (assigned != null
            ? DeliveryRequestState.assigned
            : interested.isNotEmpty
            ? DeliveryRequestState.ridersInterested
            : DeliveryRequestState.searching);

    final radius = _double(json['radiusKm']);
    final consent = json['verifiedRiderConsent'];
    return DeliveryRequest(
      kind: DeliveryRequestKind.fromWire(json['kind']),
      returnRequestId: _stringOrNull(json['returnRequestId']),
      noRidersReason: _stringOrNull(json['noRidersReason']),
      canUseVerifiedRider: json['canUseVerifiedRider'] == true,
      verifiedRiderConsentUtc: consent is Map
          ? _date(consent['consentedUtc'])
          : null,
      packageId: _string(json['packageId']),
      state: state,
      notifiedCount: _double(json['notifiedCount']).toInt(),
      openedUtc: _date(json['openedUtc']),
      expiresUtc: _date(json['expiresUtc']),
      radiusKm: radius > 0 ? radius : 5,
      interested: interested,
      assigned: assigned,
    );
  }

  final String packageId;
  final DeliveryRequestState state;
  final int notifiedCount;
  final DateTime? openedUtc;
  final DateTime? expiresUtc;
  final double radiusKm;
  final List<InterestedRider> interested;
  final AssignedRider? assigned;

  /// Why nobody was found, when there is a specific reason — see
  /// [noProRiderHighValue] and [noVerifiedRiderHighValue]. Null otherwise.
  final String? noRidersReason;

  /// The seller may repeat the request agreeing to a verified rider. Only
  /// ever true with [noProRiderHighValue].
  final bool canUseVerifiedRider;

  /// When the seller agreed to a verified non-Pro rider for this parcel, or
  /// null when they have not.
  final DateTime? verifiedRiderConsentUtc;

  /// A parcel going out, or a return coming back (return pickup contract).
  final DeliveryRequestKind kind;
  final String? returnRequestId;

  /// `noRidersReason`: a high-value parcel may only go to a Pro rider and
  /// none is available. The seller is asked whether a verified rider may
  /// take it instead.
  static const String noProRiderHighValue = 'delivery.no_pro_rider_high_value';

  /// `noRidersReason`: the seller already agreed to a verified rider and no
  /// verified rider is in range either.
  static const String noVerifiedRiderHighValue =
      'delivery.no_verified_rider_high_value';

  /// A high-value parcel found no Pro rider.
  bool get noProRider =>
      state == DeliveryRequestState.noRiders &&
      noRidersReason == noProRiderHighValue;

  /// A high-value parcel found no Pro rider and the seller can be asked
  /// whether a verified rider may take it instead.
  bool get offersVerifiedRider => noProRider && canUseVerifiedRider;

  /// Time left before the request closes; zero once it has, null when the
  /// server sent no expiry.
  Duration? remainingAt(DateTime nowUtc) {
    final expires = expiresUtc;
    if (expires == null) return null;
    final left = expires.difference(nowUtc);
    return left.isNegative ? Duration.zero : left;
  }
}

/// `kind`: `Delivery | Return`. Absent or unknown is [delivery], which is
/// what every request was before the field existed.
enum DeliveryRequestKind {
  delivery,
  returnPickup;

  static DeliveryRequestKind fromWire(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'return' || 'returnpickup' || '2' => DeliveryRequestKind.returnPickup,
        _ => DeliveryRequestKind.delivery,
      };
}

Money? _money(Object? value) {
  if (value is num) return Money(amount: value.toDouble(), currency: 'NPR');
  if (value is! Map) return null;
  final amount = value['amount'];
  if (amount is! num) return null;
  return Money(
    amount: amount.toDouble(),
    currency: _stringOrNull(value['currency']) ?? 'NPR',
  );
}

String _string(Object? value) => value?.toString() ?? '';

String? _stringOrNull(Object? value) {
  final raw = value?.toString().trim();
  return raw == null || raw.isEmpty ? null : raw;
}

double _double(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v) ?? 0,
  _ => 0,
};

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}

/// The contract sends `Neighbor | Traveler | Pro`; the existing candidate
/// list sent 1–3. Both are read, and worded the way the rest of the vendor
/// app words them.
String riderTierLabel(Object? value) {
  final raw = value?.toString().trim().toLowerCase() ?? '';
  return switch (raw) {
    'neighbor' || 'neighbour' || '1' => 'Neighbour',
    'traveler' || 'traveller' || '2' => 'Traveller',
    'pro' || '3' => 'Pro',
    _ => 'Partner',
  };
}

/// `Bike | Scooter | Car | Bicycle | OnFoot` as a vendor reads it. Accepts
/// the bare string the interested list sends or the rider profile's
/// `{ type, plateLast4 }` object; an unknown type is shown as sent, and
/// nothing at all is null.
String? riderVehicleLabel(Object? value) {
  final raw = _stringOrNull(value is Map ? value['type'] : value);
  if (raw == null) return null;
  return switch (raw.toLowerCase().replaceAll(RegExp('[ _-]'), '')) {
    'bike' || 'motorbike' || 'motorcycle' => 'Bike',
    'scooter' => 'Scooter',
    'car' => 'Car',
    'bicycle' || 'cycle' => 'Bicycle',
    'onfoot' || 'foot' || 'walking' => 'On foot',
    _ => raw,
  };
}
