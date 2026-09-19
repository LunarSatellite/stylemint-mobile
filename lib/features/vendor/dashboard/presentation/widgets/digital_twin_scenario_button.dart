// Scenario copy deliberately distinguishes measured baselines from simulated outcomes.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
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
      final result =
          await ref
                  .read(apiClientProvider)
                  .post(
                    '/api/v1/vendor/digital-twin/scenarios',
                    data: {
                      'name':
                          'Vendor what-if ${DateTime.now().toIso8601String()}',
                      'seed': Random().nextInt(2147483646) + 1,
                      'customerAgents': 1000,
                      'days': 30,
                      'demandShockPercent': scenario.demand,
                      'inventoryLossPercent': scenario.inventory,
                      'fulfillmentCapacityLossPercent': scenario.capacity,
                    },
                  )
              as Map<String, dynamic>;
      if (!context.mounted) return;
      Navigator.pop(context);
      await showDialog<void>(
        context: context,
        builder: (_) => _ResultDialog(result: result),
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
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
        onChanged: onChanged,
      ),
    ],
  );
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.result});
  final Map<String, dynamic> result;
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFF121A24),
    title: const Row(
      children: [
        Icon(Icons.auto_graph_rounded, color: Color(0xFF67F5C7)),
        SizedBox(width: 10),
        Expanded(
          child: Text('Scenario result', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row('Conversion', '${result['conversionPercent'] ?? 0}%'),
        _row('Stockouts', '${result['stockoutPercent'] ?? 0}%'),
        _row('On-time', '${result['onTimePercent'] ?? 0}%'),
        _row('Simulated GMV', 'NPR ${result['grossMerchandiseValue'] ?? 0}'),
        const SizedBox(height: 12),
        const Text(
          'This is a bounded simulation, not a forecast guarantee. The run keeps its live calibration snapshot and seed for audit and replay.',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Done'),
      ),
    ],
  );
  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: DesignTokens.textLight)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _Scenario {
  const _Scenario(this.demand, this.inventory, this.capacity);
  final double demand;
  final double inventory;
  final double capacity;
}
