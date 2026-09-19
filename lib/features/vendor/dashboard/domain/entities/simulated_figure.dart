import 'package:intl/intl.dart';

/// One number produced by the retail **simulation** engine, with the
/// provenance it arrived carrying.
///
/// ## Why this type exists
///
/// `POST /api/v1/vendor/digital-twin/scenarios` runs a seeded model. Nothing
/// it returns was measured. The dialog that shows its result sits on the same
/// screen as Store Pulse, whose figures *are* counted, so a simulated number
/// drawn in the measured visual language is a fabricated measurement on a
/// vendor's screen.
///
/// The backend used to send these as bare decimals and this client rendered
/// `result['conversionPercent'] ?? 0` as `"Conversion 12.4%"` with no label.
/// Each figure is now an **object** carrying `simulatedValue`, `provenance`,
/// `derivedFrom`, `measureKey` and `unit`. The field *names* were kept
/// deliberately: renaming them would have made the old `?? 0` fall through and
/// print `"Conversion 0%"` — a plausible invented measurement, which is the
/// exact failure being defended against. A visibly wrong map beats a plausible
/// wrong number.
///
/// ## What this type refuses to do
///
///   * It will not parse a bare number. A number with no provenance cannot be
///     attributed, and [tryParse] returns `null` for it — the caller then
///     renders **nothing**, never `0` and never a dash.
///   * It has no fallback value. There is no `?? 0` anywhere in this file.
///   * It treats an unrecognised provenance as simulated (see
///     [kMeasuredProvenances]).
class SimulatedFigure {
  const SimulatedFigure({
    required this.value,
    this.provenance,
    this.unit,
    this.measureKey,
    this.derivedFrom,
  });

  /// Reads one figure out of a decoded JSON value.
  ///
  /// Returns `null` — meaning *render nothing* — when [raw] is not an object,
  /// when `simulatedValue` is absent, or when it is not a finite number. A
  /// missing simulated figure is not a measurement of zero.
  static SimulatedFigure? tryParse(Object? raw) {
    // A bare number is rejected on purpose. It is exactly the old wire shape,
    // and a figure with no provenance has nothing to label it with.
    if (raw is! Map) return null;
    final value = _finiteNum(raw['simulatedValue']);
    if (value == null) return null;
    return SimulatedFigure(
      value: value,
      provenance: _text(raw['provenance']),
      unit: _text(raw['unit']),
      measureKey: _text(raw['measureKey']),
      derivedFrom: _text(raw['derivedFrom']),
    );
  }

  /// The number. Named after the wire field so that reading it stays a
  /// visible act; there is no `Value` and no implicit conversion.
  final num value;

  /// The raw provenance token, exactly as it arrived. May be `null`.
  final String? provenance;

  /// The raw unit token, e.g. `percent`, `count`, `currency_unstated`.
  final String? unit;

  /// What was counted, in the simulated world, e.g.
  /// `synthetic.conversion_percent`.
  final String? measureKey;

  /// The stated assumptions the figure was produced from.
  final String? derivedFrom;

  /// Provenance tokens this client accepts as meaning *measured*.
  ///
  /// An **allowlist**, not a denylist, and that direction is the whole point.
  /// A denylist would let a future token the backend invents —
  /// `"Projected"`, `"Blended"`, `"Estimated"` — fall through and be drawn in
  /// the measured language. Anything not named here, including `null`, an
  /// empty string and any token added later, reads as simulated.
  static const Set<String> kMeasuredProvenances = {
    'measured',
    'observed',
    'counted',
    'settled',
  };

  /// The token the simulation engine currently sends.
  static const String kSimulated = 'simulated';

  static const String _unitPercent = 'percent';
  static const String _unitCurrencyUnstated = 'currency_unstated';

  String get _provenanceKey => (provenance ?? '').trim().toLowerCase();

  String get _unitKey => (unit ?? '').trim().toLowerCase();

  /// `true` unless the provenance is one this client recognises as a
  /// measurement. The cautious reading is the default.
  bool get isSimulated => !kMeasuredProvenances.contains(_provenanceKey);

  /// `true` when the provenance is neither a recognised measurement nor the
  /// engine's own `Simulated`. Such a figure is still read as simulated; the
  /// tile names the token so nothing is hidden.
  bool get hasUnrecognisedProvenance =>
      isSimulated && _provenanceKey != kSimulated;

  /// The word shown beside the number. Never colour, never a glyph alone.
  String get provenanceWord => isSimulated ? 'Simulated' : 'Measured';

  /// `true` when the engine declared no currency for a monetary figure, so no
  /// symbol may be drawn. GMV is this case: the engine invents prices.
  bool get currencyIsUnstated => _unitKey == _unitCurrencyUnstated;

  /// The number as shown. Carries a `%` for a percentage and **no currency
  /// symbol for anything** — the engine states no currency, so this client
  /// cannot invent one.
  String get displayValue {
    final formatted = _decimal(value);
    return _unitKey == _unitPercent ? '$formatted%' : formatted;
  }

  /// The number as a screen reader should say it.
  String get spokenValue => switch (_unitKey) {
    _unitPercent => '${_decimal(value)} percent',
    _unitCurrencyUnstated => '${_decimal(value)}, in no stated currency',
    _ => _decimal(value),
  };

  /// A plain-language reading of [unit], for the line under the number.
  String get unitSentence => switch (_unitKey) {
    _unitPercent => 'Unit: percent.',
    _unitCurrencyUnstated =>
      'Unit: currency not stated. The engine invents prices and names no '
          'currency, so this figure carries no currency symbol and cannot be '
          'compared with settled money.',
    '' => 'Unit: not stated.',
    _ => 'Unit: ${unit!.trim()}.',
  };

  /// The provenance sentence under the number, naming an unrecognised token
  /// rather than quietly swallowing it.
  String get provenanceSentence {
    if (hasUnrecognisedProvenance) {
      return 'Provenance "${provenance ?? 'none'}" is not a recognised '
          'measurement, so it is read as simulated.';
    }
    return isSimulated
        ? 'Produced by a seeded model. Not a measurement.'
        : 'Counted from recorded activity.';
  }

  /// Everything the tile says, as one sentence for assistive technology.
  String semanticsSentence(String label) => [
    '$label.',
    '$provenanceWord figure.',
    '$spokenValue.',
    provenanceSentence,
    unitSentence,
    if (measureKey != null && measureKey!.trim().isNotEmpty)
      'Measure key ${measureKey!.trim()}.',
  ].join(' ');

  static num? _finiteNum(Object? raw) {
    final value = switch (raw) {
      final num n => n,
      final String s => num.tryParse(s.trim()),
      _ => null,
    };
    if (value == null) return null;
    if (value is double && (value.isNaN || value.isInfinite)) return null;
    return value;
  }

  static String? _text(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Grouped, at most two decimals, with trailing zeros dropped so a count
  /// reads as `1,204` rather than `1,204.00`.
  static String _decimal(num value) =>
      NumberFormat('#,##0.##').format(value);
}
