import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Edits a size chart: garment type, unit, one row per size with the
/// measurements that garment needs, and a fit note. Validation is the
/// contract's (see [SizeChartRules]); problems show once [showErrors] is on
/// (after the first Save) so a half-typed row is not shouted at.
class SizeChartEditor extends StatefulWidget {
  const SizeChartEditor({
    required this.initial,
    required this.onChanged,
    this.showErrors = false,
    super.key,
  });

  final SizeChart initial;
  final ValueChanged<SizeChart> onChanged;
  final bool showErrors;

  /// A starting chart for a product that has none.
  static SizeChart blank(GarmentType type) => SizeChart(
    garmentType: type,
    unit: MeasurementUnit.cm,
    rows: const [
      SizeChartRow(sizeLabel: 'S'),
      SizeChartRow(sizeLabel: 'M'),
      SizeChartRow(sizeLabel: 'L'),
    ],
  );

  @override
  State<SizeChartEditor> createState() => _SizeChartEditorState();
}

class _SizeChartEditorState extends State<SizeChartEditor> {
  late SizeChart _chart = widget.initial;

  /// Stable keys per row so removing row 2 does not hand its text fields to
  /// row 3.
  late List<int> _rowIds = List.generate(_chart.rows.length, (i) => i);
  late int _nextId = _chart.rows.length;
  late final TextEditingController _note = TextEditingController(
    text: widget.initial.fitNote ?? '',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _set(SizeChart next) {
    setState(() => _chart = next);
    widget.onChanged(next);
  }

  void _setRow(int index, SizeChartRow row) {
    final rows = [..._chart.rows]..[index] = row;
    _set(_chart.copyWith(rows: rows));
  }

  void _addRow() {
    if (_chart.rows.length >= SizeChartRules.maxRows) return;
    _rowIds = [..._rowIds, _nextId++];
    _set(
      _chart.copyWith(
        rows: [
          ..._chart.rows,
          const SizeChartRow(sizeLabel: ''),
        ],
      ),
    );
  }

  void _removeRow(int index) {
    _rowIds = [..._rowIds]..removeAt(index);
    _set(_chart.copyWith(rows: [..._chart.rows]..removeAt(index)));
  }

  static String _fmt(double? v) => v == null
      ? ''
      : v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toString();

  @override
  Widget build(BuildContext context) {
    final measures = _chart.garmentType.editorMeasures;
    final required = _chart.garmentType.requiredMeasures.toSet();
    final issues = widget.showErrors
        ? SizeChartRules.validate(_chart)
        : const <SizeChartIssue>[];
    final advice = SizeChartRules.recommendations(_chart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<GarmentType>(
                key: const Key('chart-garment-type'),
                initialValue: _chart.garmentType,
                dropdownColor: DesignTokens.bgAppBodyLight,
                style: const TextStyle(color: DesignTokens.textWhite),
                decoration: const InputDecoration(labelText: 'Garment type'),
                items: [
                  for (final g in GarmentType.values)
                    DropdownMenuItem(value: g, child: Text(g.label)),
                ],
                onChanged: (g) {
                  if (g != null) _set(_chart.copyWith(garmentType: g));
                },
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            SegmentedButton<MeasurementUnit>(
              key: const Key('chart-unit'),
              segments: const [
                ButtonSegment(value: MeasurementUnit.cm, label: Text('cm')),
                ButtonSegment(value: MeasurementUnit.inch, label: Text('inch')),
              ],
              selected: {_chart.unit},
              onSelectionChanged: (s) => _set(_chart.copyWith(unit: s.first)),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          required.isEmpty
              ? 'Accessories need no measurements — add the sizes you sell.'
              : 'Required for every size: '
                    '${required.map((m) => m.label.toLowerCase()).join(' and ')}. '
                    'Measure the garment laid flat and double it for chest, '
                    'waist and hips.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        for (var i = 0; i < _chart.rows.length; i++)
          _RowEditor(
            key: ValueKey('chart-row-${_rowIds[i]}'),
            index: i,
            row: _chart.rows[i],
            measures: measures,
            required: required,
            unit: _chart.unit,
            issues: [
              for (final x in issues)
                if (x.row == i) x.message,
            ],
            canRemove: _chart.rows.length > 1,
            fmt: _fmt,
            onChanged: (r) => _setRow(i, r),
            onRemove: () => _removeRow(i),
          ),
        TextButton.icon(
          key: const Key('chart-add-row'),
          onPressed: _chart.rows.length >= SizeChartRules.maxRows
              ? null
              : _addRow,
          icon: const Icon(Icons.add),
          label: const Text('Add size'),
        ),
        TextField(
          key: const Key('chart-fit-note'),
          controller: _note,
          maxLength: SizeChartRules.maxFitNoteLength,
          maxLines: 2,
          style: const TextStyle(color: DesignTokens.textWhite),
          decoration: const InputDecoration(
            labelText: 'Fit note (optional)',
            hintText: 'e.g. Runs small — size up if between sizes',
          ),
          onChanged: (v) => _set(_chart.copyWith(fitNote: v)),
        ),
        for (final x in issues.where((x) => x.row == null))
          Text(
            x.message,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        for (final a in advice)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: Text(
              a,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorWarning,
              ),
            ),
          ),
      ],
    );
  }
}

class _RowEditor extends StatelessWidget {
  const _RowEditor({
    required this.index,
    required this.row,
    required this.measures,
    required this.required,
    required this.unit,
    required this.issues,
    required this.canRemove,
    required this.fmt,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final SizeChartRow row;
  final List<SizeMeasure> measures;
  final Set<SizeMeasure> required;
  final MeasurementUnit unit;
  final List<String> issues;
  final bool canRemove;
  final String Function(double?) fmt;
  final ValueChanged<SizeChartRow> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s8),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        border: Border.all(
          color: issues.isEmpty
              ? DesignTokens.borderDefault
              : DesignTokens.colorError,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: TextFormField(
                  key: Key('chart-row-$index-label'),
                  initialValue: row.sizeLabel,
                  maxLength: SizeChartRules.maxLabelLength,
                  style: const TextStyle(color: DesignTokens.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'Size',
                    counterText: '',
                  ),
                  onChanged: (v) => onChanged(row.copyWith(sizeLabel: v)),
                ),
              ),
              for (final m in measures)
                SizedBox(
                  width: 92,
                  child: TextFormField(
                    key: Key('chart-row-$index-${m.wire}'),
                    initialValue: fmt(row[m]),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: const TextStyle(color: DesignTokens.textWhite),
                    decoration: InputDecoration(
                      labelText: required.contains(m)
                          ? '${m.label} *'
                          : m.label,
                      suffixText: unit.label,
                    ),
                    onChanged: (v) =>
                        onChanged(row.withValue(m, double.tryParse(v.trim()))),
                  ),
                ),
              if (canRemove)
                IconButton(
                  key: Key('chart-row-$index-remove'),
                  tooltip: 'Remove size',
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: DesignTokens.textMuted,
                  ),
                ),
            ],
          ),
          for (final issue in issues)
            Text(
              issue,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
        ],
      ),
    );
  }
}
