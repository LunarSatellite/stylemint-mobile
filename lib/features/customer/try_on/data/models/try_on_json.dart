/// Wire mapping for the TryOn contract v1 (camelCase, integer enums).
///
/// Written with the tolerant `json_read` helpers, like the EMI/credit
/// feature: one odd field degrades to empty instead of failing the screen.
library;

import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';

List<Map<String, dynamic>> _objects(Object? raw) => raw is List
    ? raw
          .whereType<Map<Object?, Object?>>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false)
    : const [];

List<String> _strings(Object? raw) => raw is List
    ? raw
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false)
    : const [];

int? _optionalInt(Object? raw) => raw == null ? null : readInt(raw);

// ── Size chart ───────────────────────────────────────────────────────────

SizeChartRow readSizeChartRow(Map<String, dynamic> json) {
  final values = <SizeMeasure, double>{};
  for (final m in SizeMeasure.values) {
    final v = readOptionalDouble(json[m.wire]);
    if (v != null) values[m] = v;
  }
  return SizeChartRow(sizeLabel: readString(json['sizeLabel']), values: values);
}

SizeChart readSizeChart(Map<String, dynamic> json) => SizeChart(
  productId: readOptionalString(json['productId']),
  garmentType: GarmentType.fromWire(_optionalInt(json['garmentType'])),
  unit: MeasurementUnit.fromWire(_optionalInt(json['unit'])),
  rows: [for (final r in _objects(json['rows'])) readSizeChartRow(r)],
  fitNote: readOptionalString(json['fitNote']),
  updatedUtc: readDate(json['updatedUtc']),
);

/// `SizeChartInput`. Unset measurements go as null, as the contract allows.
Map<String, dynamic> writeSizeChart(SizeChart chart) => <String, dynamic>{
  'garmentType': chart.garmentType.wire,
  'unit': chart.unit.wire,
  'rows': [
    for (final row in chart.rows)
      <String, dynamic>{
        'sizeLabel': row.sizeLabel.trim(),
        for (final m in SizeMeasure.values) m.wire: row[m],
      },
  ],
  'fitNote': (chart.fitNote?.trim().isEmpty ?? true)
      ? null
      : chart.fitNote!.trim(),
};

// ── Access, plans, subscriptions ─────────────────────────────────────────

TryOnPlan readTryOnPlan(Map<String, dynamic> json) => TryOnPlan(
  id: readString(json['id']),
  name: readString(json['name']),
  description: readOptionalString(json['description']),
  priceAmount: readOptionalDouble(json['priceAmount']) ?? 0,
  currency: readOptionalString(json['currency']) ?? 'NPR',
  durationDays: readInt(json['durationDays']),
);

TryOnAccess readTryOnAccess(Map<String, dynamic> json) => TryOnAccess(
  serviceEnabled: readBool(json['serviceEnabled']),
  hasAccess: readBool(json['hasAccess']),
  source: TryOnAccessSource.fromWire(_optionalInt(json['source'])),
  expiresUtc: readDate(json['expiresUtc']),
  trialAvailable: readBool(json['trialAvailable']),
  freeTrialDays: readInt(json['freeTrialDays']),
  disclaimer: readString(json['disclaimer']),
  plans: [
    for (final p in _objects(json['plans']))
      if (readString(p['id']).isNotEmpty) readTryOnPlan(p),
  ],
);

MyTryOnSubscription readMySubscription(Map<String, dynamic> json) =>
    MyTryOnSubscription(
      id: readString(json['id']),
      planId: readOptionalString(json['planId']),
      planName: readOptionalString(json['planName']),
      source:
          TryOnAccessSource.fromWire(_optionalInt(json['source'])) ??
          TryOnAccessSource.unknown,
      state: TryOnSubscriptionState.fromWire(_optionalInt(json['state'])),
      startsUtc: readDate(json['startsUtc']),
      expiresUtc: readDate(json['expiresUtc']),
      priceAmount: readOptionalDouble(json['priceAmount']) ?? 0,
      currency: readOptionalString(json['currency']) ?? 'NPR',
      createdUtc: readDate(json['createdUtc']),
    );

List<MyTryOnSubscription> readMySubscriptions(Object? raw) => [
  for (final s in raw is Map ? readPagedItems(raw) : _objects(raw))
    readMySubscription(s),
];

/// `{ subscription, payment: PaymentInitiationDto }`. The payment shape is
/// the shared payments one; the hand-off URL is read under the names the
/// payment rails use (`redirectUrl`, else `approvalUrl` / `paymentUrl`).
TryOnPaymentStart readTryOnPaymentStart(Map<String, dynamic> json) {
  final payment = json['payment'] is Map
      ? Map<String, dynamic>.from(json['payment'] as Map)
      : const <String, dynamic>{};
  return TryOnPaymentStart(
    subscription: readMySubscription(readJsonObject(json['subscription'])),
    redirectUrl:
        readOptionalString(payment['redirectUrl']) ??
        readOptionalString(payment['approvalUrl']) ??
        readOptionalString(payment['paymentUrl']),
    paymentIntentId:
        readOptionalString(payment['paymentIntentId']) ??
        readOptionalString(payment['id']),
  );
}

// ── Product, measurements, fit ───────────────────────────────────────────

TryOnProduct readTryOnProduct(Map<String, dynamic> json) => TryOnProduct(
  productId: readString(json['productId']),
  name: readString(json['name']),
  overlayImageUrl: readString(json['overlayImageUrl']),
  overlayWidth: readInt(json['overlayWidth']),
  overlayHeight: readInt(json['overlayHeight']),
  garmentType: GarmentType.fromWire(_optionalInt(json['garmentType'])),
  sizeChart: json['sizeChart'] is Map
      ? readSizeChart(Map<String, dynamic>.from(json['sizeChart'] as Map))
      : null,
  disclaimer: readString(json['disclaimer']),
);

BodyMeasurements readBodyMeasurements(Map<String, dynamic> json) =>
    BodyMeasurements(
      heightCm: readOptionalDouble(json['heightCm']) ?? 0,
      weightKg: readOptionalDouble(json['weightKg']),
      chestCm: readOptionalDouble(json['chestCm']),
      waistCm: readOptionalDouble(json['waistCm']),
      hipsCm: readOptionalDouble(json['hipsCm']),
      shoulderCm: readOptionalDouble(json['shoulderCm']),
      inseamCm: readOptionalDouble(json['inseamCm']),
      footLengthCm: readOptionalDouble(json['footLengthCm']),
      fitPreference: FitPreference.fromWire(
        _optionalInt(json['fitPreference']),
      ),
      updatedUtc: readDate(json['updatedUtc']),
    );

Map<String, dynamic> writeBodyMeasurements(BodyMeasurements m) =>
    <String, dynamic>{
      'heightCm': m.heightCm,
      'weightKg': m.weightKg,
      'chestCm': m.chestCm,
      'waistCm': m.waistCm,
      'hipsCm': m.hipsCm,
      'shoulderCm': m.shoulderCm,
      'inseamCm': m.inseamCm,
      'footLengthCm': m.footLengthCm,
      'fitPreference': m.fitPreference.wire,
    };

FitRecommendation readFitRecommendation(Map<String, dynamic> json) =>
    FitRecommendation(
      productId: readString(json['productId']),
      recommendedSize: readOptionalString(json['recommendedSize']),
      confidence: (readOptionalDouble(json['confidence']) ?? 0)
          .clamp(0, 1)
          .toDouble(),
      perSize: [
        for (final s in _objects(json['perSize']))
          SizeFit(
            sizeLabel: readString(s['sizeLabel']),
            verdict: FitVerdict.fromWire(_optionalInt(s['verdict'])),
            notes: _strings(s['notes']),
          ),
      ],
      missingMeasurements: _strings(json['missingMeasurements']),
      basedOn: readString(json['basedOn']),
    );
