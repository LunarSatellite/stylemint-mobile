import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/widgets/vendor_ledger_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorEarningsScreen extends ConsumerWidget {
  const VendorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorEarningsNotifierProvider);
    final ledgerState = ref.watch(ledgerNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Earnings', style: DesignTokens.titleMedium),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (summary) => RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: () async {
            ref.read(vendorEarningsNotifierProvider.notifier).loadSummary();
            ref.read(ledgerNotifierProvider.notifier).loadLedger();
          },
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
                    onPressed: () => context.push('/vendor/earnings/payout'),
                    child: const Text('Request Payout'),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
              ledgerState.when(
                initial: _loader,
                loadInProgress: _loader,
                loadSuccess: (entries, hasMore) {
                  if (entries.isEmpty) {
                    return const SmEmptyState(
                      message: 'No ledger entries yet.',
                      icon: Icons.receipt_long_outlined,
                    );
                  }
                  return Column(
                    children: [
                      ...entries.map(
                        (entry) => VendorLedgerTile(entry: entry),
                      ),
                      if (hasMore)
                        TextButton(
                          onPressed: () => ref
                              .read(ledgerNotifierProvider.notifier)
                              .loadLedger(),
                          child: const Text('Load More'),
                        ),
                    ],
                  );
                },
                loadFailure: (f) => SmErrorView(
                  message: 'Failed to load ledger.',
                  onRetry: () =>
                      ref.read(ledgerNotifierProvider.notifier).loadLedger(),
                ),
              ),
            ],
          ),
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load earnings.',
          onRetry: () =>
              ref.read(vendorEarningsNotifierProvider.notifier).loadSummary(),
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

  final VendorEarningsSummary summary;

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
          label: 'Revenue',
          value: summary.totalRevenue,
          color: DesignTokens.primaryGreen,
        ),
        _SummaryCard(
          label: 'Available',
          value: summary.availableBalance,
          color: DesignTokens.colorInfo,
        ),
        _SummaryCard(
          label: 'Pending',
          value: summary.pendingPayout,
          color: DesignTokens.warning500,
        ),
        _SummaryCard(
          label: 'This Month',
          value: summary.thisMonth,
          color: DesignTokens.primaryGreen,
        ),
        _SummaryCard(
          label: 'Last Month',
          value: summary.lastMonth,
          color: DesignTokens.textLight,
        ),
        _SummaryCard(
          label: 'Platform Fees',
          value: summary.platformFees,
          color: DesignTokens.colorError,
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
      decoration: DesignTokens.cardDecoration(),
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
