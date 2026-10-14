import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/measurement_rules.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The short "your measurements" form: lengths in cm or inches (the wire is
/// always cm), weight in kg, plus a fit preference.
class MeasurementsForm extends StatefulWidget {
  const MeasurementsForm({
    required this.onSubmit,
    this.initial,
    this.saving = false,
    this.serverError,
    super.key,
  });

  final BodyMeasurements? initial;
  final bool saving;
  final String? serverError;
  final ValueChanged<BodyMeasurements> onSubmit;

  @override
  State<MeasurementsForm> createState() => _MeasurementsFormState();
}

class _MeasurementsFormState extends State<MeasurementsForm> {
  final Map<BodyField, TextEditingController> _controllers = {
    for (final f in BodyField.values) f: TextEditingController(),
  };
  MeasurementUnit _unit = MeasurementUnit.cm;
  FitPreference _fit = FitPreference.regular;
  Map<BodyField, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    if (m != null) {
      _fit = m.fitPreference;
      final values = <BodyField, double?>{
        BodyField.height: m.heightCm,
        BodyField.weight: m.weightKg,
        BodyField.chest: m.chestCm,
        BodyField.waist: m.waistCm,
        BodyField.hips: m.hipsCm,
        BodyField.shoulder: m.shoulderCm,
        BodyField.inseam: m.inseamCm,
        BodyField.footLength: m.footLengthCm,
      };
      for (final e in values.entries) {
        final v = e.value;
        if (v != null && v > 0) _controllers[e.key]!.text = _fmt(v);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _switchUnit(MeasurementUnit next) {
    if (next == _unit) return;
    setState(() {
      for (final f in BodyField.values.where((f) => f.isLength)) {
        final c = _controllers[f]!;
        final v = double.tryParse(c.text.trim());
        if (v == null) continue;
        c.text = _fmt(next == MeasurementUnit.inch ? cmToInch(v) : inchToCm(v));
      }
      _unit = next;
    });
  }

  /// Field values converted to cm/kg.
  Map<BodyField, double?> _valuesCm() => {
    for (final f in BodyField.values)
      f: switch (double.tryParse(_controllers[f]!.text.trim())) {
        null => null,
        final v when f.isLength && _unit == MeasurementUnit.inch =>
          double.parse(inchToCm(v).toStringAsFixed(1)),
        final v => v,
      },
  };

  void _submit() {
    final values = _valuesCm();
    final errors = MeasurementRules.validate(values);
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;
    widget.onSubmit(
      BodyMeasurements(
        heightCm: values[BodyField.height]!,
        weightKg: values[BodyField.weight],
        chestCm: values[BodyField.chest],
        waistCm: values[BodyField.waist],
        hipsCm: values[BodyField.hips],
        shoulderCm: values[BodyField.shoulder],
        inseamCm: values[BodyField.inseam],
        footLengthCm: values[BodyField.footLength],
        fitPreference: _fit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your measurements',
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Measure over light clothing. Only height is required — the more '
          'you add, the better the size advice.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        SegmentedButton<MeasurementUnit>(
          key: const Key('measurements-unit'),
          segments: const [
            ButtonSegment(value: MeasurementUnit.cm, label: Text('cm')),
            ButtonSegment(value: MeasurementUnit.inch, label: Text('inch')),
          ],
          selected: {_unit},
          onSelectionChanged: (s) => _switchUnit(s.first),
        ),
        const SizedBox(height: DesignTokens.s12),
        Wrap(
          spacing: DesignTokens.s12,
          runSpacing: DesignTokens.s8,
          children: [
            for (final f in BodyField.values)
              SizedBox(
                width: 150,
                child: TextField(
                  key: Key('measure-${f.name}'),
                  controller: _controllers[f],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: const TextStyle(color: DesignTokens.textWhite),
                  decoration: InputDecoration(
                    labelText: f == BodyField.height ? '${f.label} *' : f.label,
                    suffixText: f.isLength ? _unit.label : 'kg',
                    errorText: _errors[f],
                    errorMaxLines: 3,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        Text(
          'How do you like clothes to fit?',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        SegmentedButton<FitPreference>(
          segments: [
            for (final p in FitPreference.values)
              ButtonSegment(value: p, label: Text(p.label)),
          ],
          selected: {_fit},
          onSelectionChanged: (s) => setState(() => _fit = s.first),
        ),
        if (widget.serverError case final String error) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            error,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('measurements-save'),
            style: DesignTokens.primaryButtonStyle(),
            onPressed: widget.saving ? null : _submit,
            child: widget.saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Find my size'),
          ),
        ),
      ],
    );
  }
}
