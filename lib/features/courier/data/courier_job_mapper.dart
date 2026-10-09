import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `CourierJobDto` and `DeliveryProofDto` (delivery-complete contract) →
/// domain.
///
/// Hand-written and tolerant, like the rest of this feature's mappers: the
/// backend is built in parallel, so a missing or oddly-typed field degrades
/// to "not shown" rather than failing the whole screen.
abstract final class CourierJobMapper {
  static CourierJob job(Map<String, dynamic> json) {
    final items =
        (json['items'] is List
                ? json['items'] as List<dynamic>
                : const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => CourierJobItem(
            name: _text(item['name']) ?? 'Item',
            quantity: _int(item['quantity']) ?? 1,
            imageUrl: _text(item['imageUrl']),
          ),
        )
        .toList(growable: false);

    return CourierJob(
      hopId: _text(json['hopId']) ?? _text(json['id']) ?? '',
      packageId: _text(json['packageId']) ?? '',
      packageNumber: _text(json['packageNumber']) ?? '',
      status: CourierJobStatus.fromWire(json['status']),
      assignedUtc: _date(json['assignedUtc']),
      pickedUpUtc: _date(json['pickedUpUtc']),
      deliveredUtc: _date(json['deliveredUtc']),
      payout: money(json['payout']),
      cashToCollect: _positive(money(json['cashToCollect'])),
      items: items,
      itemCount:
          _int(json['itemCount']) ??
          items.fold<int>(0, (sum, item) => sum + item.quantity),
      declaredValue: money(json['declaredValue']),
      notes: _text(json['notes']),
      pickup: stop(json['pickup']),
      dropoff: stop(json['dropoff']),
      distanceKm: _double(json['distanceKm']),
    );
  }

  static DeliveryProof proof(Map<String, dynamic> json) => DeliveryProof(
    hopId: _text(json['hopId']) ?? '',
    packageNumber: _text(json['packageNumber']) ?? '',
    status: DeliveryProofStatus.fromWire(json['status']),
    qrPayload: _text(json['qrPayload']) ?? '',
    code: _text(json['code']) ?? '',
    expiresUtc: _date(json['expiresUtc']),
    confirmedUtc: _date(json['confirmedUtc']),
  );

  /// `{ latitude, longitude, label, addressLine, contactName, contactPhone }`.
  /// A 0,0 or out-of-range point is dropped — a failed geocode would
  /// otherwise put the pin in the Atlantic — but the text is kept.
  static CourierJobStop stop(Object? value) {
    if (value is! Map) return const CourierJobStop(point: null);
    final latitude = _double(value['latitude']);
    final longitude = _double(value['longitude']);
    final point =
        latitude != null &&
            longitude != null &&
            latitude.abs() <= 90 &&
            longitude.abs() <= 180 &&
            !(latitude == 0 && longitude == 0)
        ? GeoPoint(latitude, longitude)
        : null;
    return CourierJobStop(
      point: point,
      label: _text(value['label']),
      addressLine: _text(value['addressLine']),
      contactName: _text(value['contactName']),
      contactPhone: _text(value['contactPhone']),
    );
  }

  /// `{ amount, currency }`, or null when absent. A bare number is read as
  /// NPR rather than dropped.
  static Money? money(Object? value) {
    if (value is num) return Money(amount: value.toDouble(), currency: 'NPR');
    if (value is! Map) return null;
    final amount = _double(value['amount']);
    if (amount == null) return null;
    return Money(amount: amount, currency: _text(value['currency']) ?? 'NPR');
  }

  /// A zero "cash to collect" is a prepaid order, not a Rs 0 banner.
  static Money? _positive(Money? money) =>
      money == null || money.amount <= 0 ? null : money;

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _int(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v.trim()),
    _ => null,
  };

  static double? _double(Object? value) => switch (value) {
    final num v => v.toDouble(),
    final String v => double.tryParse(v.trim()),
    _ => null,
  };

  /// Always UTC, so countdowns compare against `DateTime.now().toUtc()`.
  ///
  /// A timestamp without a zone is read as UTC, not local time: every field
  /// here is a `…Utc`, and reading one as Kathmandu time would put a QR's
  /// expiry 5 h 45 min out.
  static DateTime? _date(Object? value) {
    if (value is! String) return null;
    final text = value.trim();
    if (text.isEmpty) return null;
    final zoned = _zone.hasMatch(text) || !text.contains('T')
        ? text
        : '${text}Z';
    return DateTime.tryParse(zoned)?.toUtc();
  }

  static final RegExp _zone = RegExp(
    r'(Z|[+-]\d{2}:?\d{2})$',
    caseSensitive: false,
  );
}
