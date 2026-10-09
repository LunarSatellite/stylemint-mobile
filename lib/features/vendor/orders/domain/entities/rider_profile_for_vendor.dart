import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';

/// Where this rider stands on the vendor's current request.
enum RiderOfferState {
  interested('Interested'),
  assigned('Assigned'),
  notSelected('NotSelected'),
  withdrawn('Withdrawn');

  const RiderOfferState(this.wire);

  final String wire;

  static RiderOfferState? fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase().replaceAll('_', '');
    if (raw == null || raw.isEmpty) return null;
    for (final state in values) {
      if (state.wire.toLowerCase() == raw) return state;
    }
    return null;
  }

  /// No longer someone the vendor can choose.
  bool get isGone =>
      this == RiderOfferState.notSelected || this == RiderOfferState.withdrawn;
}

/// What a vendor may see about a rider before choosing them
/// (`RiderProfileForVendorDto`, rider-rating contract).
///
/// Privacy is the server's: no phone, email, full surname, exact home or
/// documents arrive here, and reviews carry no rater. Built either from that
/// endpoint or — while it is not deployed — from the row the vendor tapped
/// ([RiderProfileForVendor.fromInterested]), so the sheet always has the
/// basics and adds the rest when the server has it.
class RiderProfileForVendor {
  const RiderProfileForVendor({
    required this.courierId,
    required this.displayName,
    required this.tier,
    this.offerId,
    this.avatarUrl,
    this.verified,
    this.memberSinceUtc,
    this.vehicle,
    this.plateLast4,
    this.homeArea,
    this.distanceKm,
    this.interestedUtc,
    this.rating,
    this.averageFromList,
    this.ratingCountFromList,
    this.completedDeliveries,
    this.onTimeRate,
    this.cancellationRate,
    this.recentReviews = const [],
    this.state,
    this.isFallback = false,
  });

  factory RiderProfileForVendor.fromJson(Map<String, dynamic> json) {
    final name = _text(json['displayName']);
    return RiderProfileForVendor(
      courierId: _text(json['courierId']) ?? '',
      offerId: _text(json['offerId']),
      displayName: name ?? 'StyleMint rider',
      avatarUrl: _text(json['avatarUrl']),
      verified: json['verified'] is bool ? json['verified'] as bool : null,
      memberSinceUtc: _date(json['memberSinceUtc']),
      tier: riderTierLabel(json['tier']),
      vehicle: riderVehicleLabel(json['vehicle']),
      plateLast4: json['vehicle'] is Map
          ? _text((json['vehicle'] as Map)['plateLast4'])
          : null,
      homeArea: _text(json['homeArea']),
      distanceKm: _double(json['distanceKm']),
      interestedUtc: _date(json['interestedUtc']),
      rating: RiderRatingSummary.fromJson(json['rating']),
      completedDeliveries: _double(json['completedDeliveries'])?.toInt(),
      onTimeRate: _rate(json['onTimeRate']),
      cancellationRate: _rate(json['cancellationRate']),
      // The contract caps vendor-visible reviews at five; so does the app.
      recentReviews: RiderReview.listFrom(json['recentReviews'], max: 5),
      state: RiderOfferState.fromWire(json['state']),
    );
  }

  /// What the interested list already said about [rider] — the sheet's
  /// stand-in while the details endpoint is missing or still loading.
  factory RiderProfileForVendor.fromInterested(InterestedRider rider) =>
      RiderProfileForVendor(
        courierId: rider.courierId,
        offerId: rider.offerId,
        displayName: rider.displayName,
        avatarUrl: rider.avatarUrl,
        verified: rider.verified,
        tier: rider.tier,
        vehicle: rider.vehicle,
        distanceKm: rider.distanceKm,
        interestedUtc: rider.interestedUtc,
        averageFromList: rider.rating,
        ratingCountFromList: rider.ratingCount,
        completedDeliveries: rider.completedDeliveries,
        state: RiderOfferState.interested,
        isFallback: true,
      );

  final String courierId;
  final String? offerId;
  final String displayName;
  final String? avatarUrl;
  final bool? verified;
  final DateTime? memberSinceUtc;
  final String tier;
  final String? vehicle;
  final String? plateLast4;

  /// An area name ("Lalitpur"), never a location.
  final String? homeArea;
  final double? distanceKm;
  final DateTime? interestedUtc;

  /// The full summary; null on the fallback, where [averageFromList] and
  /// [ratingCountFromList] are all there is.
  final RiderRatingSummary? rating;
  final double? averageFromList;
  final int? ratingCountFromList;
  final int? completedDeliveries;

  /// 0–1, or null when there is too little history to say.
  final double? onTimeRate;
  final double? cancellationRate;
  final List<RiderReview> recentReviews;
  final RiderOfferState? state;

  /// Built from the interested row, not the details endpoint.
  final bool isFallback;
}

String? _text(Object? value) {
  final raw = value?.toString().trim();
  return raw == null || raw.isEmpty ? null : raw;
}

double? _double(Object? value) => switch (value) {
  final num v => v.toDouble(),
  final String v => double.tryParse(v),
  _ => null,
};

/// A 0–1 rate; a server sending a percentage (0–100) is read too.
double? _rate(Object? value) {
  final rate = _double(value);
  if (rate == null || rate < 0) return null;
  return rate > 1 ? (rate / 100).clamp(0, 1).toDouble() : rate;
}

DateTime? _date(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toUtc();
}
