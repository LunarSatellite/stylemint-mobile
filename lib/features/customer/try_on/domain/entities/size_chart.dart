/// Size charts for virtual try-on: the shape both the buyer's fit panel and
/// the vendor's editor read, and the validation the vendor editor runs before
/// a `PUT` (the same rules the server enforces, so a vendor fixes everything
/// in one pass rather than one 400 at a time). Pure Dart.
library;

enum GarmentType {
  top(1, 'Top'),
  bottom(2, 'Bottom'),
  dress(3, 'Dress'),
  outerwear(4, 'Outerwear'),
  fullBody(5, 'Full body'),
  footwear(6, 'Footwear'),
  accessory(7, 'Accessory');

  const GarmentType(this.wire, this.label);

  final int wire;
  final String label;

  static GarmentType fromWire(int? value) =>
      values.firstWhere((v) => v.wire == value, orElse: () => top);

  static GarmentType? tryFromWire(int? value) {
    for (final v in values) {
      if (v.wire == value) return v;
    }
    return null;
  }

  /// Measurements a chart for this garment must give on every row.
  List<SizeMeasure> get requiredMeasures => switch (this) {
    GarmentType.top || GarmentType.outerwear => const [SizeMeasure.chest],
    GarmentType.bottom => const [SizeMeasure.waist],
    GarmentType.dress ||
    GarmentType.fullBody => const [SizeMeasure.chest, SizeMeasure.waist],
    GarmentType.footwear => const [SizeMeasure.footLength],
    GarmentType.accessory => const <SizeMeasure>[],
  };

  /// The columns the editor shows for this garment (required first).
  List<SizeMeasure> get editorMeasures => switch (this) {
    GarmentType.top => const [
      SizeMeasure.chest,
      SizeMeasure.shoulder,
      SizeMeasure.waist,
      SizeMeasure.length,
    ],
    GarmentType.outerwear => const [
      SizeMeasure.chest,
      SizeMeasure.shoulder,
      SizeMeasure.length,
    ],
    GarmentType.bottom => const [
      SizeMeasure.waist,
      SizeMeasure.hips,
      SizeMeasure.inseam,
      SizeMeasure.length,
    ],
    GarmentType.dress || GarmentType.fullBody => const [
      SizeMeasure.chest,
      SizeMeasure.waist,
      SizeMeasure.hips,
      SizeMeasure.length,
    ],
    GarmentType.footwear => const [SizeMeasure.footLength],
    GarmentType.accessory => const [SizeMeasure.length],
  };
}

enum MeasurementUnit {
  cm(1, 'cm'),
  inch(2, 'in');

  const MeasurementUnit(this.wire, this.label);

  final int wire;
  final String label;

  static MeasurementUnit fromWire(int? value) => value == inch.wire ? inch : cm;

  /// Largest value a chart cell may hold in this unit (300 cm / 120 in).
  double get maxMeasure => this == cm ? 300 : 120;
}

/// One measurement column of a size chart, named as on the wire.
enum SizeMeasure {
  chest('chest', 'Chest'),
  waist('waist', 'Waist'),
  hips('hips', 'Hips'),
  shoulder('shoulder', 'Shoulder'),
  length('length', 'Length'),
  inseam('inseam', 'Inseam'),
  footLength('footLength', 'Foot length');

  const SizeMeasure(this.wire, this.label);

  final String wire;
  final String label;
}

const double cmPerInch = 2.54;

double inchToCm(double inches) => inches * cmPerInch;
double cmToInch(double cm) => cm / cmPerInch;

class SizeChartRow {
  const SizeChartRow({
    required this.sizeLabel,
    this.values = const <SizeMeasure, double>{},
  });

  final String sizeLabel;
  final Map<SizeMeasure, double> values;

  double? operator [](SizeMeasure m) => values[m];

  SizeChartRow copyWith({
    String? sizeLabel,
    Map<SizeMeasure, double>? values,
  }) => SizeChartRow(
    sizeLabel: sizeLabel ?? this.sizeLabel,
    values: values ?? this.values,
  );

  /// The same row with [measure] set, or cleared when [value] is null.
  SizeChartRow withValue(SizeMeasure measure, double? value) {
    final next = Map<SizeMeasure, double>.of(values);
    if (value == null) {
      next.remove(measure);
    } else {
      next[measure] = value;
    }
    return copyWith(values: next);
  }
}

class SizeChart {
  const SizeChart({
    required this.garmentType,
    required this.unit,
    required this.rows,
    this.fitNote,
    this.productId,
    this.updatedUtc,
  });

  final String? productId;
  final GarmentType garmentType;
  final MeasurementUnit unit;
  final List<SizeChartRow> rows;
  final String? fitNote;
  final DateTime? updatedUtc;

  List<String> get sizeLabels => [for (final r in rows) r.sizeLabel];

  SizeChart copyWith({
    GarmentType? garmentType,
    MeasurementUnit? unit,
    List<SizeChartRow>? rows,
    String? fitNote,
  }) => SizeChart(
    productId: productId,
    garmentType: garmentType ?? this.garmentType,
    unit: unit ?? this.unit,
    rows: rows ?? this.rows,
    fitNote: fitNote ?? this.fitNote,
    updatedUtc: updatedUtc,
  );
}

/// One problem with a chart the vendor is editing. [row] is the 0-based row
/// it belongs to, null for the chart as a whole.
class SizeChartIssue {
  const SizeChartIssue(this.message, {this.row, this.measure});

  final String message;
  final int? row;
  final SizeMeasure? measure;

  @override
  String toString() => row == null ? message : 'Row ${row! + 1}: $message';
}

abstract final class SizeChartRules {
  static const int minRows = 1;
  static const int maxRows = 20;
  static const int maxLabelLength = 16;
  static const int maxFitNoteLength = 300;

  /// Every reason [chart] would be refused, in reading order. Empty when it
  /// can be saved. Mirrors the server's rules in the TryOn contract.
  static List<SizeChartIssue> validate(SizeChart chart) {
    final issues = <SizeChartIssue>[];
    if (chart.rows.length < minRows) {
      issues.add(const SizeChartIssue('Add at least one size.'));
    }
    if (chart.rows.length > maxRows) {
      issues.add(
        const SizeChartIssue('A size chart can have at most 20 sizes.'),
      );
    }
    final note = chart.fitNote?.trim() ?? '';
    if (note.length > maxFitNoteLength) {
      issues.add(
        const SizeChartIssue('The fit note can be at most 300 characters.'),
      );
    }

    final seen = <String>{};
    final max = chart.unit.maxMeasure;
    final required = chart.garmentType.requiredMeasures;
    for (var i = 0; i < chart.rows.length; i++) {
      final row = chart.rows[i];
      final label = row.sizeLabel.trim();
      if (label.isEmpty) {
        issues.add(SizeChartIssue('Give the size a label (e.g. M).', row: i));
      } else if (label.length > maxLabelLength) {
        issues.add(
          SizeChartIssue('Size labels can be at most 16 characters.', row: i),
        );
      } else if (!seen.add(label.toLowerCase())) {
        issues.add(SizeChartIssue('Size "$label" is listed twice.', row: i));
      }
      for (final entry in row.values.entries) {
        final v = entry.value;
        if (v <= 0 || v > max) {
          issues.add(
            SizeChartIssue(
              '${entry.key.label} must be more than 0 and at most '
              '${max.toStringAsFixed(0)} ${chart.unit.label}.',
              row: i,
              measure: entry.key,
            ),
          );
        }
      }
      for (final m in required) {
        if (row[m] == null) {
          issues.add(
            SizeChartIssue(
              '${m.label} is required for ${chart.garmentType.label.toLowerCase()}s.',
              row: i,
              measure: m,
            ),
          );
        }
      }
    }
    return issues;
  }

  /// Advice that does not block a save: a bottom without hips or inseam can
  /// only be matched on the waist.
  static List<String> recommendations(SizeChart chart) {
    if (chart.garmentType != GarmentType.bottom) return const [];
    final missing = chart.rows.any(
      (r) => r[SizeMeasure.hips] == null && r[SizeMeasure.inseam] == null,
    );
    return missing
        ? const [
            'Add hips or inseam for each size — buyers get a far better fit '
                'recommendation than from the waist alone.',
          ]
        : const [];
  }
}
