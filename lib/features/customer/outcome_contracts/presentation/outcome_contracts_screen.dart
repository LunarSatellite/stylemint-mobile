// The contractual copy is kept intact for accessibility and product review.
// ignore_for_file: lines_longer_than_80_chars, sort_constructors_first

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final FutureProvider<List<OutcomeContract>> outcomeContractsProvider =
    FutureProvider.autoDispose<List<OutcomeContract>>((ref) async {
      final response = await ref
          .watch(apiClientProvider)
          .get('/v1/outcome-contracts');
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OutcomeContract.fromJson)
          .toList(growable: false);
    });

class OutcomeContract {
  const OutcomeContract({
    required this.id,
    required this.mission,
    required this.deadline,
    required this.status,
    required this.recovery,
    required this.assurancePrice,
    required this.currency,
    required this.orderId,
    required this.deliveredCount,
    required this.planCount,
  });
  final String id;
  final String mission;
  final DateTime deadline;
  final int status;
  final int recovery;
  final double assurancePrice;
  final String currency;
  final String? orderId;
  final int deliveredCount;
  final int planCount;

  factory OutcomeContract.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? const {};
    final items = plan['items'] as List<dynamic>? ?? const [];
    final delivered = json['deliveredProductIds'] as List<dynamic>? ?? const [];
    return OutcomeContract(
      id: json['id'] as String? ?? '',
      mission: json['missionText'] as String? ?? '',
      deadline:
          DateTime.tryParse(json['deadlineUtc'] as String? ?? '') ??
          DateTime.now(),
      status: _enumValue(json['status']),
      recovery: _enumValue(json['recoveryObligation']),
      assurancePrice: (json['assurancePrice'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'NPR',
      orderId: json['orderId'] as String?,
      deliveredCount: delivered.length,
      planCount: items.length,
    );
  }

  static int _enumValue(dynamic value) {
    if (value is num) return value.toInt();
    return switch (value?.toString().toLowerCase()) {
      'active' || 'refundassurancefee' => 1,
      'fulfilled' || 'replacementplan' => 2,
      'recoverydue' || 'customercredit' => 3,
      'recovered' => 4,
      'cancelled' => 5,
      _ => 0,
    };
  }
}

class OutcomeContractsScreen extends ConsumerWidget {
  const OutcomeContractsScreen({super.key});
  static const createKey = ValueKey<String>('outcome-contract-create');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(outcomeContractsProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Outcome promises'),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: createKey,
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: const Color(0xFF07170D),
        onPressed: () async {
          final created = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: const Color(0xFF141715),
            builder: (_) => const _CreateContractSheet(),
          );
          if (created == true) ref.invalidate(outcomeContractsProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New promise',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: contracts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.cloud_off_rounded,
          title: 'Promises unavailable',
          body: 'Check your connection and try again.',
          action: () => ref.invalidate(outcomeContractsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(outcomeContractsProvider.future),
          child: items.isEmpty
              ? const _Message(
                  icon: Icons.verified_outlined,
                  title: 'Shop for an outcome',
                  body:
                      'Freeze a curated plan, deadline and recovery promise—not just a basket.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    const _Intro(),
                    const SizedBox(height: 16),
                    for (final item in items) ...[
                      _ContractCard(item),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [Color(0xFF183B29), Color(0xFF111512)],
      ),
      border: Border.all(color: const Color(0x5532D477)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.workspace_premium_outlined,
          color: DesignTokens.primaryGreen,
          size: 30,
        ),
        SizedBox(height: 12),
        Text(
          'The result is the product.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'StyleMint freezes the plan, watches delivery and executes the recovery you chose if the deadline is missed.',
          style: TextStyle(color: DesignTokens.textLight, height: 1.45),
        ),
      ],
    ),
  );
}

class _ContractCard extends StatelessWidget {
  const _ContractCard(this.contract);
  final OutcomeContract contract;
  String get status => switch (contract.status) {
    1 => 'ACTIVE',
    2 => 'FULFILLED',
    3 => 'RECOVERY DUE',
    4 => 'RECOVERED',
    5 => 'CANCELLED',
    _ => 'UNKNOWN',
  };
  String get recovery => switch (contract.recovery) {
    1 => 'Assurance refund',
    2 => 'Replacement plan',
    3 => 'StyleMint credit',
    _ => 'Recovery',
  };
  @override
  Widget build(BuildContext context) {
    final delivered = contract.planCount == 0
        ? 0.0
        : (contract.deliveredCount / contract.planCount).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171A18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF303630)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2632D477),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: DesignTokens.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${contract.deadline.day}/${contract.deadline.month}/${contract.deadline.year}',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            contract.mission,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: delivered,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            color: DesignTokens.primaryGreen,
            backgroundColor: const Color(0xFF303530),
          ),
          const SizedBox(height: 7),
          Text(
            '${contract.deliveredCount} of ${contract.planCount} planned products delivered',
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 11),
          ),
          const Divider(height: 28, color: Color(0xFF303630)),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: DesignTokens.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recovery,
                  style: const TextStyle(
                    color: DesignTokens.textLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (contract.assurancePrice > 0)
                Text(
                  '${contract.currency} ${contract.assurancePrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateContractSheet extends ConsumerStatefulWidget {
  const _CreateContractSheet();
  @override
  ConsumerState<_CreateContractSheet> createState() =>
      _CreateContractSheetState();
}

class _CreateContractSheetState extends ConsumerState<_CreateContractSheet> {
  final mission = TextEditingController();
  final budget = TextEditingController();
  final criteria = TextEditingController(
    text: 'Every planned product is delivered',
  );
  int days = 7;
  int recovery = 3;
  bool saving = false;
  String? error;
  @override
  void dispose() {
    mission.dispose();
    budget.dispose();
    criteria.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final budgetValue = double.tryParse(budget.text.trim());
    if (mission.text.trim().isEmpty ||
        criteria.text.trim().isEmpty ||
        budgetValue == null ||
        budgetValue <= 0) {
      setState(
        () => error = 'Add a mission, positive budget and success criterion.',
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final key = 'outcome-${DateTime.now().microsecondsSinceEpoch}';
      await ref
          .read(apiClientProvider)
          .post(
            '/v1/outcome-contracts',
            data: {
              'missionText': mission.text.trim(),
              'budgetAmount': budgetValue,
              'maxItems': 8,
              'successCriteria': [criteria.text.trim()],
              'deadlineUtc': DateTime.now()
                  .toUtc()
                  .add(Duration(days: days))
                  .toIso8601String(),
              'substitutionAuthority': 2,
              'assurancePrice': recovery == 3
                  ? (budgetValue * .02).clamp(50, 500)
                  : 0,
              'currency': 'NPR',
              'recoveryObligation': recovery,
              'recoveryTerms': recovery == 3
                  ? 'Issue spendable StyleMint checkout credit automatically.'
                  : 'Generate a fresh in-stock mission plan automatically.',
            },
            options: Options(
              headers: {'requiresToken': true, 'Idempotency-Key': key},
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          saving = false;
          error = 'Could not create this promise. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create an outcome promise',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'The catalogue plan is frozen when you confirm.',
            style: TextStyle(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 18),
          _field(mission, 'What must this shopping mission achieve?', lines: 3),
          const SizedBox(height: 12),
          _field(budget, 'Budget in NPR', number: true),
          const SizedBox(height: 12),
          _field(criteria, 'Success criterion'),
          const SizedBox(height: 18),
          const Text(
            'DEADLINE',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final value in [3, 7, 14])
                ChoiceChip(
                  label: Text('$value days'),
                  selected: days == value,
                  onSelected: (_) => setState(() => days = value),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'IF STYLEMINT MISSES IT',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          _RecoveryChoice(
            selected: recovery == 3,
            title: 'Automatic StyleMint credit',
            subtitle: '2% assurance, capped at NPR 500',
            onTap: () => setState(() => recovery = 3),
          ),
          _RecoveryChoice(
            selected: recovery == 2,
            title: 'Automatic replacement plan',
            subtitle: 'A new in-stock plan, no assurance charge',
            onTap: () => setState(() => recovery = 2),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                error!,
                style: const TextStyle(color: DesignTokens.colorError),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              key: const ValueKey('outcome-contract-confirm'),
              onPressed: saving ? null : save,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: const Color(0xFF07170D),
              ),
              child: Text(
                saving ? 'Freezing promise…' : 'Confirm outcome promise',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String hint, {
    int lines = 1,
    bool number = false,
  }) => TextField(
    controller: controller,
    minLines: lines,
    maxLines: lines,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF0E100F),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

class _RecoveryChoice extends StatelessWidget {
  const _RecoveryChoice({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
      color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
    ),
    title: Text(title),
    subtitle: Text(subtitle),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      SizedBox(height: MediaQuery.sizeOf(context).height * .2),
      Icon(icon, size: 48, color: DesignTokens.primaryGreen),
      const SizedBox(height: 14),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: DesignTokens.textMuted, height: 1.4),
        ),
      ),
      if (action != null)
        TextButton(onPressed: action, child: const Text('Try again')),
    ],
  );
}
