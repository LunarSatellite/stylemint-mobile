import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
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
              Text('Total Balance',
                  style: DesignTokens.sectionInnerTitle
                      .copyWith(fontSize: 15)),
              const SizedBox(height: DesignTokens.s12),
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
                  imagePath: 'assets/images/creatordash/material-symbols_money-bag-rounded.png',
                  label: 'Available Balance (In NPR)',
                  value: formatMoney(summary.availableBalance),
                ),
                const SizedBox(height: DesignTokens.s16),
                _BalanceMetric(
                  iconBg: const Color(0xFF3A2F03),
                  iconChild: Image.asset(
                    'assets/images/creatordash/material-symbols_hourglass-top-rounded.png',
                    width: 28,
                    height: 28,
                  ),
                  label: 'Pending Balance (In NPR)',
                  value: formatMoney(summary.pendingBalance),
                ),
              ],
            ),
          ),
          // Bottom half — payout request with scalloped top edge.
          GestureDetector(
            onTap: () => context.push(RouteNames.earningsPayout),
            behavior: HitTestBehavior.opaque,
            child: ClipPath(
              clipper: const _ScallopedTopClipper(),
            child: Container(
              width: double.infinity,
              color: DesignTokens.secondaryYellow,
              padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, 22, DesignTokens.s16, DesignTokens.s16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/creatordash/Payout.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request Payout Withdrawal',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          'Payouts are processed weekly on fridays.\nThe minimum withdraw amount is Rs 5,000.00',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DesignTokens.buttonPrimaryText,
                    size: 22,
                  ),
                ],
              ),
            ),
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
    required this.label,
    required this.value,
    this.imagePath,
    this.iconChild,
  });

  final Color iconBg;
  final String? imagePath;
  final Widget? iconChild;
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
          child: iconChild ??
              Image.asset(imagePath!, width: 28, height: 28,
                  fit: BoxFit.contain),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
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
class _EarningsBreakdown extends ConsumerWidget {
  const _EarningsBreakdown({required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = formatMoney(summary.thisMonthEarnings);
    final breakdown = ref.watch(earningsBreakdownProvider);

    // Real per-reel metrics come from the analytics dashboard; show a dash
    // while loading or if the dashboard call fails.
    final (salesLabel, avg, highest) = breakdown.maybeWhen(
      data: (b) => (
        'No. of sales across ${b.reelCount} reels',
        '${formatMoney(b.avgPerSale)} per sale',
        formatMoney(b.highestReelEarnings),
      ),
      orElse: () => ('No. of sales', '—', '—'),
    );
    final salesValue = breakdown.maybeWhen(
      data: (b) => '${b.salesCount}',
      orElse: () => '—',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Earnings Breakdown This Month',
            style: DesignTokens.sectionInnerTitle.copyWith(fontSize: 15)),
        const SizedBox(height: DesignTokens.s12),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            children: [
              _BreakdownRow(
                  iconWidget: Image.asset(
                      'assets/images/creatordash/material-symbols_package-2-outline.png',
                      width: 14, height: 14),
                  label: salesLabel,
                  value: salesValue),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(
                  iconWidget: Image.asset(
                      'assets/images/creatordash/universal-currency.png',
                      width: 14, height: 14),
                  label: 'Average',
                  value: avg),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(
                  iconWidget: Image.asset(
                      'assets/images/creatordash/material-symbols_animated-images-outline-rounded.png',
                      width: 14, height: 14),
                  label: 'Highest Earned from a Reel',
                  value: highest),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(
                  iconWidget: Image.asset(
                      'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
                      width: 14, height: 14),
                  label: 'Total Earned',
                  value: total),
              const SizedBox(height: DesignTokens.s8),
              _BreakdownRow(
                  icon: Icons.percent_rounded,
                  label: 'Platform Fee (0%)',
                  value: '-0.00'),
              const Divider(
                  color: DesignTokens.borderDefault, height: DesignTokens.s24),
              _BreakdownRow(
                  label: 'Net Earnings',
                  value: total,
                  emphasize: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(
      {required this.label, required this.value, this.emphasize = false, this.icon, this.iconWidget});

  final String label;
  final String value;
  final bool emphasize;
  final IconData? icon;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    final leading = iconWidget ?? (icon != null ? Icon(icon, size: 14, color: DesignTokens.textMuted) : null);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading,
          const SizedBox(width: DesignTokens.s8),
        ],
        Expanded(
          child: Text(label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              )),
        ),
        const SizedBox(width: DesignTokens.s12),
        Text(value,
            style: DesignTokens.mediumSemibold.copyWith(
              fontSize: emphasize ? 16 : 14,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
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
          onAction: () => context.push(RouteNames.creatorPayoutHistory),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (payouts.isEmpty)
          Text('No payouts yet.',
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted))
        else
          Container(
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: payouts.asMap().entries.map((e) {
                final isLast = e.key == payouts.length - 1;
                return Column(
                  children: [
                    _PayoutRow(entry: e.value),
                    if (!isLast)
                      const Divider(
                        color: DesignTokens.borderDefault,
                        height: 1,
                        indent: DesignTokens.s16,
                        endIndent: DesignTokens.s16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
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
      padding: const EdgeInsets.all(DesignTokens.s16),
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
            child: Image.asset(
              'assets/images/creatordash/universal-currency.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
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
                Text(
                  entry.reference != null
                      ? '${entry.reference!} · $when'
                      : when,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textLight),
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
          onAction: () => context.push(RouteNames.creatorAddPaymentMethod),
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
        PayoutMethodType.venmo => 'Wallet',
      };

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBodyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentMethodActionsSheet(
        method: method,
        onRemoveTap: () {
          Navigator.of(context).pop();
          _showRemoveConfirmation(context);
        },
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBodyLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RemovePaymentMethodSheet(method: method),
    );
  }

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
            child: const Icon(Icons.account_balance_outlined,
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
                    if (method.isPrimary) ...[
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
          GestureDetector(
            onTap: () => _showActions(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(DesignTokens.s4),
              child: Icon(Icons.more_vert_rounded,
                  size: 18, color: DesignTokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Payment method actions bottom sheet ──────────────────────────────────────
class _PaymentMethodActionsSheet extends StatelessWidget {
  const _PaymentMethodActionsSheet({
    required this.method,
    required this.onRemoveTap,
  });

  final PayoutMethod method;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.borderDefault,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _ActionRow(
            icon: Icons.edit_outlined,
            label: 'Edit Details',
            onTap: () {
              Navigator.of(context).pop();
              context.push(RouteNames.creatorAddPaymentMethod);
            },
          ),
          const Divider(
              color: DesignTokens.borderDefault, height: 1,
              indent: DesignTokens.s16, endIndent: DesignTokens.s16),
          _ActionRow(
            icon: Icons.delete_outline_rounded,
            label: 'Remove Payment Method',
            onTap: onRemoveTap,
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    );
  }
}

class _RemovePaymentMethodSheet extends ConsumerWidget {
  const _RemovePaymentMethodSheet({required this.method});

  final PayoutMethod method;

  String get _typeLabel => switch (method.type) {
        PayoutMethodType.bankTransfer => 'Bank A/C',
        PayoutMethodType.esewa => 'Wallet',
        PayoutMethodType.paypal => 'Wallet',
        PayoutMethodType.venmo => 'Wallet',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addPayoutMethodNotifierProvider);

    ref.listen<AsyncValue<void>>(addPayoutMethodNotifierProvider, (_, next) {
      next.whenOrNull(
        data: (_) {
          ref.read(earningsNotifierProvider.notifier).load();
          Navigator.of(context).pop();
        },
        error: (e, __) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        ),
      );
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DesignTokens.s12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            Image.asset(
              'assets/images/infoicon.png',
              width: 52,
              height: 52,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Confirm Remove',
              style: DesignTokens.sectionInnerTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Are you sure you want to remove this\npayment method?',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBodyLight,
                      borderRadius: BorderRadius.circular(DesignTokens.s8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.account_balance_outlined,
                        size: 20, color: DesignTokens.iconLight),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_typeLabel,
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.textWhite)),
                      const SizedBox(height: 2),
                      Text(method.label,
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textLight)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => ref
                        .read(addPayoutMethodNotifierProvider.notifier)
                        .remove(method.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.buttonPrimaryText,
                        ),
                      )
                    : Text('Remove Payment Method',
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.buttonPrimaryText)),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed:
                    state.isLoading ? null : () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.bgAppBody,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                child: Text('Cancel',
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.textWhite)),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: DesignTokens.textWhite),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(label,
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.textWhite)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: DesignTokens.textMuted),
          ],
        ),
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
        Text(title,
            style: DesignTokens.sectionInnerTitle.copyWith(fontSize: 15)),
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

// ── Scalloped top clipper for the yellow payout section ───────────────────────
class _ScallopedTopClipper extends CustomClipper<Path> {
  const _ScallopedTopClipper();

  @override
  Path getClip(Size size) {
    const r = 9.0;
    final path = Path()..moveTo(0, r);
    double x = 0;
    while (x < size.width) {
      path.arcToPoint(
        Offset((x + r * 2).clamp(0, size.width), r),
        radius: const Radius.circular(r),
        clockwise: true,
      );
      x += r * 2;
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
