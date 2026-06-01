import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/widgets/ledger_entry_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(earningsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Earnings', style: DesignTokens.titleMedium),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (summary, entries, methods) {
          if (entries.isEmpty) {
            return const SmEmptyState(
              message: 'No earnings yet.\nStart creating content to earn!',
              icon: Icons.account_balance_wallet_outlined,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh:
                () => ref.read(earningsNotifierProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                _SummaryGrid(summary: summary),
                const SizedBox(height: DesignTokens.s24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ledger', style: DesignTokens.h3),
                    TextButton(
                      onPressed: () => context.push('/creator/earnings/payout'),
                      child: const Text('Request Payout'),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s8),
                ...entries.map((entry) => LedgerEntryTile(entry: entry)),
              ],
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load earnings.',
          onRetry:
              () => ref.read(earningsNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: DesignTokens.s8,
      mainAxisSpacing: DesignTokens.s8,
      childAspectRatio: 1.6,
      children: [
        _SummaryCard(
          label: 'Available',
          value: summary.availableBalance,
          color: DesignTokens.primaryGreen,
        ),
        _SummaryCard(
          label: 'Pending',
          value: summary.pendingBalance,
          color: DesignTokens.warning500,
        ),
        _SummaryCard(
          label: 'This Month',
          value: summary.thisMonthEarnings,
          color: DesignTokens.colorInfo,
        ),
        _SummaryCard(
          label: 'Total Payouts',
          value: summary.totalPayouts,
          color: DesignTokens.textLight,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final Money value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: DesignTokens.smallRegular),
          const SizedBox(height: DesignTokens.s4),
          MoneyText(
            value,
            style: DesignTokens.sectionInnerTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
