import 'dart:convert';

import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_fare.dart';

/// `fareBreakdown` (rider-fare contract v1, §2) → [FareBreakdown].
///
/// Tolerant like the rest of this feature's mappers: an absent breakdown
/// (offers and hops made before the release) is null, a breakdown sent as a
/// JSON string is decoded, and a malformed one is null rather than a failed
/// screen. Without a numeric `total` there is nothing trustworthy to show, so
/// that is null too.
abstract final class CourierFareMapper {
  static FareBreakdown? breakdown(Object? value, {String? fallbackCurrency}) {
    var raw = value;
    if (raw is String) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      try {
        raw = jsonDecode(text);
      } on FormatException {
        return null;
      }
    }
    if (raw is! Map) return null;

    final total = _double(raw['total']);
    if (total == null) return null;

    final extras = (raw['extras'] is List ? raw['extras'] as List : const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) {
          final kind = FareExtraKind.fromWire(e['code']);
          final amount = _double(e['amount']);
          if (amount == null) return null;
          return FareExtra(
            kind: kind,
            label: _text(e['label']) ?? kind.fallbackLabel,
            amount: amount,
          );
        })
        .whereType<FareExtra>()
        .toList(growable: false);

    return FareBreakdown(
      total: total,
      currency: _text(raw['currency']) ?? fallbackCurrency ?? 'NPR',
      roadPriced: _text(raw['method'])?.toLowerCase() == 'road',
      km: _double(raw['roadKm']),
      straightLineKm: _double(raw['straightLineKm']),
      detourFactor: _double(raw['detourFactor']),
      baseFare: _double(raw['baseFare']),
      perKm: _double(raw['perKm']),
      distanceAmount: _double(raw['distanceAmount']),
      tier: _text(raw['tier']),
      tierMultiplier: _double(raw['tierMultiplier']),
      tripAmount: _double(raw['tripAmount']),
      minimumFare: _double(raw['minimumFare']),
      minimumApplied: raw['minimumApplied'] == true,
      extras: extras,
      rounding: _double(raw['rounding']),
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _double(Object? value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v.trim()),
    _ => null,
  };
}
