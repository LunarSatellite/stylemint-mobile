import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator Earnings & Payments — rebuilt to the design spec:
/// a two-tone balances + payout-request card, an "Earnings Breakdown This
/// Month" card, a "Payout History" list, and a "Payment Methods" list.
///
/// Real data: available/pending balance, this-month earnings, payout-type
/// ledger entries, and the payout methods. The per-reel breakdown metrics
/// (sales count, average, highest) aren't on the summary payload yet — those
/// are clearly-marked `MOCK` until the API exposes them.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(earningsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Earnings & Payments',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (summary, entries, methods) => RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: () => ref.read(earningsNotifierProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              _BalancesPayoutCard(summary: summary),
              const SizedBox(height: DesignTokens.s24),
              _EarningsBreakdown(summary: summary),
              const SizedBox(height: DesignTokens.s24),
              _PayoutHistory(entries: entries),
              const SizedBox(height: DesignTokens.s24),
              _PaymentMethods(methods: methods),
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load earnings.',
          onRetry: () => ref.read(earningsNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

// ── Balances + payout request (two-tone card) ─────────────────────────────────
class _BalancesPayoutCard extends StatelessWidget {
  const _BalancesPayoutCard({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          // Top half — balances.
          Container(
            width: double.infinity,
            color: DesignTokens.bgAppBody,
            padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.s20, horizontal: DesignTokens.s16),
            child: Column(
              children: [
                _BalanceMetric(
                  iconBg: DesignTokens.primaryGreenDark,
                  iconColor: DesignTokens.primaryGreen,
                  label: 'Available Balance (In NPR)',
                  value: formatMoney(summary.availableBalance),
                ),
                const SizedBox(height: DesignTokens.s16),
                _BalanceMetric(
                  iconBg: const Color(0xFF3A2F03),
                  iconColor: DesignTokens.secondaryYellow,
                  label: 'Pending Balance (In NPR)',
                  value: formatMoney(summary.pendingBalance),
                ),
              ],
            ),
          ),
          // Bottom half — payout request.
          Container(
            width: double.infinity,
            color: DesignTokens.secondaryYellow,
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmPrimaryButton(
                  label: 'Request Payout Withdrawal',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.buttonPrimaryText,
                  labelColor: DesignTokens.secondaryYellow,
                  onPressed: () async => context.push(RouteNames.earningsPayout),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text('Payouts are processed weekly on fridays.',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.buttonPrimaryText)),
                Text('The minimum withdraw amount is Rs 5,000.00',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.buttonPrimaryText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.account_balance_wallet_outlined,
              size: 28, color: iconColor),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textLight)),
              const SizedBox(height: DesignTokens.s4),
              Text(value,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: DesignTokens.textWhite,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Earnings breakdown (this month) ───────────────────────────────────────────
class _EarningsBreakdown extends StatelessWidget {
  const _EarningsBreakdown({required this.summary});

  final EarningsSummary summary;

  // MOCK — per-reel breakdown metrics aren't on the summary payload yet.
  static const _salesCount = '89';
  static const _reelCount = '23';
  static const _avgPerSale = 'Rs 2,335.88 per sale';
  static const _highestReel = 'Rs 18,909.22';

  @override
  Widget build(BuildContext context) {
    final total = formatMoney(summary.thisMonthEarnings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Earnings Breakdown This Month',
            style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s12),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            children: [
              _BreakdownRow(
                  label: 'No. of sales across $_reelCount reels',
                  value: _salesCount),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(label: 'Average', value: _avgPerSale),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(
                  label: 'Highest Earned from a Reel', value: _highestReel),
              const Divider(
                  color: DesignTokens.borderDefault, height: DesignTokens.s24),
              _BreakdownRow(label: 'Total Earned', value: total),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(label: 'Platform Fee (0%)', value: '-0.00'),
              const Divider(
                  color: DesignTokens.borderDefault, height: DesignTokens.s24),
              _BreakdownRow(label: 'Net Earnings', value: total, emphasize: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(
      {required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight)),
        ),
        const SizedBox(width: DesignTokens.s12),
        Text(value,
            style: DesignTokens.mediumSemibold.copyWith(
              color:
                  emphasize ? DesignTokens.primaryGreen : DesignTokens.textWhite,
            )),
      ],
    );
  }
}

// ── Payout history ────────────────────────────────────────────────────────────
class _PayoutHistory extends StatelessWidget {
  const _PayoutHistory({required this.entries});

  final List<EarningsLedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    final payouts = entries
        .where((e) => e.type == LedgerEntryType.payout)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Payout History',
          action: 'View All',
          onAction: () => context.push(RouteNames.earningsPayout),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (payouts.isEmpty)
          Text('No payouts yet.',
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted))
        else
          ...payouts.map((e) => _PayoutRow(entry: e)),
      ],
    );
  }
}

class _PayoutRow extends StatelessWidget {
  const _PayoutRow({required this.entry});

  final EarningsLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('HH:mm, MMM d yyyy').format(entry.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_outlined,
                size: 28, color: DesignTokens.iconLight),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${formatMoney(entry.amount)} ${entry.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.textWhite)),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: [
                    if (entry.reference != null) ...[
                      Text(entry.reference!,
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textLight)),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF71717B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(when,
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textLight)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          // "Completed" status tag.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
            decoration: BoxDecoration(
              color: const Color(0xFFB9F8CF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text('Completed',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: Color(0xFF016630),
                )),
          ),
        ],
      ),
    );
  }
}

// ── Payment methods ───────────────────────────────────────────────────────────
class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods({required this.methods});

  final List<PayoutMethod> methods;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Payment Methods',
          action: 'Add Method',
          onAction: () => context.push(RouteNames.creatorPaymentMethods),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (methods.isEmpty)
          Text('No payout methods yet.',
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted))
        else
          ...methods.map((m) => _PaymentMethodRow(method: m)),
      ],
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({required this.method});

  final PayoutMethod method;

  String get _typeLabel => switch (method.type) {
        PayoutMethodType.bankTransfer => 'Bank A/C',
        PayoutMethodType.esewa => 'Wallet',
        PayoutMethodType.paypal => 'Wallet',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.account_balance_wallet_outlined,
                size: 24, color: DesignTokens.iconLight),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_typeLabel,
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.textWhite)),
                    if (method.isDefault) ...[
                      const SizedBox(width: DesignTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: DesignTokens.s4),
                        decoration: BoxDecoration(
                          color: DesignTokens.tagInfoFill,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text('Default',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.tagInfoText,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            )),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(method.label,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared section header (title + green action link) ─────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.action, required this.onAction});

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: DesignTokens.sectionInnerTitle),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(action,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: DesignTokens.s4),
              const Icon(Icons.chevron_right_rounded,
                  size: 12, color: DesignTokens.primaryGreen),
            ],
          ),
        ),
      ],
    );
  }
}
