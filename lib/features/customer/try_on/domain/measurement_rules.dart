/// Client-side checks for the buyer's measurements form — the ranges in the
/// TryOn contract, applied before the `PUT` so the buyer sees every problem
/// at once. Values are in centimetres / kilograms.
library;

enum BodyField {
  height('Height', 100, 250),
  weight('Weight', 25, 300),
  chest('Chest', 20, 250),
  waist('Waist', 20, 250),
  hips('Hips', 20, 250),
  shoulder('Shoulder', 20, 250),
  inseam('Inseam', 20, 250),
  footLength('Foot length', 10, 40);

  const BodyField(this.label, this.minCm, this.maxCm);

  final String label;

  /// Bounds in cm (kg for [weight]).
  final double minCm;
  final double maxCm;

  /// Weight is always kilograms; everything else follows the unit toggle.
  bool get isLength => this != BodyField.weight;
}

abstract final class MeasurementRules {
  /// Problems per field; empty when the form can be saved. [values] are
  /// already converted to cm/kg. Only height is required.
  static Map<BodyField, String> validate(Map<BodyField, double?> values) {
    final errors = <BodyField, String>{};
    for (final field in BodyField.values) {
      final v = values[field];
      if (v == null) {
        if (field == BodyField.height) errors[field] = 'Height is required.';
        continue;
      }
      if (v < field.minCm || v > field.maxCm) {
        final unit = field.isLength ? 'cm' : 'kg';
        errors[field] =
            '${field.label} must be between ${field.minCm.toStringAsFixed(0)} '
            'and ${field.maxCm.toStringAsFixed(0)} $unit.';
      }
    }
    return errors;
  }
}
