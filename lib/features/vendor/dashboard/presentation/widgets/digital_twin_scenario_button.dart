// Scenario copy deliberately distinguishes measured baselines from simulated outcomes.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/simulated_figure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/simulated_figure_tile.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class DigitalTwinScenarioButton extends ConsumerWidget {
  const DigitalTwinScenarioButton({super.key});
  static const runKey = ValueKey<String>('run-digital-twin-scenario');

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      key: runKey,
      onPressed: () => _configure(context, ref),
      icon: const Icon(Icons.science_outlined),
      label: const Text('Test a future scenario'),
    ),
  );

  Future<void> _configure(BuildContext context, WidgetRef ref) async {
    var demand = 25.0;
    var inventory = 10.0;
    var capacity = 10.0;
    final scenario = await showModalBottomSheet<_Scenario>(
      context: context,
      backgroundColor: const Color(0xFF121A24),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stress-test your store',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Stylemint will calibrate from your live inventory, attributed demand and 30-day fulfilment history. These sliders change only the simulated future.',
                  style: TextStyle(color: DesignTokens.textLight, height: 1.4),
                ),
                const SizedBox(height: 16),
                _slider(
                  'Demand surge',
                  demand,
                  0,
                  200,
                  (x) => setState(() => demand = x),
                ),
                _slider(
                  'Inventory loss',
                  inventory,
                  0,
                  80,
                  (x) => setState(() => inventory = x),
                ),
                _slider(
                  'Capacity loss',
                  capacity,
                  0,
                  80,
                  (x) => setState(() => capacity = x),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(
                      context,
                      _Scenario(demand, inventory, capacity),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Run calibrated scenario'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (scenario == null || !context.mounted) return;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/api/v1/vendor/digital-twin/scenarios',
            data: {
              'name': 'Vendor what-if ${DateTime.now().toIso8601String()}',
              'seed': Random().nextInt(2147483646) + 1,
              'customerAgents': 1000,
              'days': 30,
              'demandShockPercent': scenario.demand,
              'inventoryLossPercent': scenario.inventory,
              'fulfillmentCapacityLossPercent': scenario.capacity,
            },
          );
      // A body that is not an object carries no figures this client can
      // attribute. It becomes an empty map, which renders the "nothing
      // readable" note rather than any number.
      final result = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};
      if (!context.mounted) return;
      Navigator.pop(context);
      await showDialog<void>(
        context: context,
        builder: (_) => DigitalTwinScenarioResultDialog(result: result),
      );
    } on Object {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The scenario could not run. Refresh Store Pulse and try again.',
          ),
        ),
      );
    }
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expanded, not bare: at 320dp and 1.3x text this Row overflowed by
          // 34px, which hid the right edge of the reading.
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Text(
            '${value.round()}%',
            style: const TextStyle(
              color: Color(0xFF67F5C7),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: (max - min).round(),
        label: '$label ${value.round()} percent',
        semanticFormatterCallback: (x) => '$label ${x.round()} percent',
        onChanged: onChanged,
      ),
    ],
  );
}

/// The simulation result, figure by figure.
///
/// Every number here came out of a seeded model and none of it was measured,
/// which matters because this dialog opens over Store Pulse — counted figures
/// are one tap behind it. So each figure is drawn by [SimulatedFigureTile],
/// which carries the word "Simulated" and a flask glyph in the same line as
/// the numeral. See that widget for why the marking is there and not in a
/// footnote or a heading.
///
/// What is **not** here:
///
///   * no `?? 0`. A figure that will not parse is dropped from the list
///     entirely — a missing simulated figure is not a measurement of zero,
///     and "0%" would be the most convincing fabrication on the screen;
///   * no currency symbol on GMV. Its unit is `currency_unstated`: the engine
///     invents prices and declares no currency, so the old "NPR 48,210" was
///     the client inventing one. The number stands alone and the tile says
///     the currency is not stated;
///   * no drift figure. `calibrationConversionDriftPoints` and its two
///     siblings are gone from the contract and are not reconstructed here; a
///     drift point folds a simulated figure and a recorded baseline into one
///     number with no provenance.
class DigitalTwinScenarioResultDialog extends StatelessWidget {
  const DigitalTwinScenarioResultDialog({required this.result, super.key});

  final Map<String, dynamic> result;

  static const Key emptyKey = ValueKey<String>('scenario-result-empty');
  static const Key doneKey = ValueKey<String>('scenario-result-done');

  /// Wire field to the label it is read under. The names are the ones the old
  /// bare-decimal contract used; only the shape behind them changed.
  static const List<({String field, String label})> _figures = [
    (field: 'conversionPercent', label: 'Conversion'),
    (field: 'stockoutPercent', label: 'Stockouts'),
    (field: 'onTimePercent', label: 'On-time fulfilment'),
    (field: 'grossMerchandiseValue', label: 'Gross merchandise value'),
  ];

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final entry in _figures)
        if (SimulatedFigure.tryParse(result[entry.field]) case final figure?)
          SimulatedFigureTile(label: entry.label, figure: figure),
    ];
    return AlertDialog(
      backgroundColor: const Color(0xFF121A24),
      title: const Row(
        children: [
          Icon(Icons.science_outlined, color: DesignTokens.textLight),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simulated scenario result',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Every figure below was produced by a model from your stated assumptions. None of it was measured. Your Store Pulse numbers behind this dialog are the measured ones.',
              style: TextStyle(
                color: DesignTokens.textLight,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            if (tiles.isEmpty)
              const Text(
                key: emptyKey,
                'This run returned no figure this app could read. Nothing is shown here, because a figure that did not arrive is not a result of zero.',
                style: TextStyle(
                  color: DesignTokens.textLight,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              )
            else
              ...tiles,
            const SizedBox(height: DesignTokens.s12),
            const Text(
              'A bounded simulation, not a forecast guarantee. The run keeps its seed and its recorded assumptions so it can be replayed. Calibration is not reported as a single drift number: a simulated figure and a recorded outcome are set side by side instead.',
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: doneKey,
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Scenario {
  const _Scenario(this.demand, this.inventory, this.capacity);
  final double demand;
  final double inventory;
  final double capacity;
}
