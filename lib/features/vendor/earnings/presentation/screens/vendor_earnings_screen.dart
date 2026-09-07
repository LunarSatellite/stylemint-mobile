import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/notifiers/payout_destinations_controller.dart';
import 'package:stylemint_mobile_frontend/features/payouts/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/all_payout_history_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const _vendorRole = PayeeKind.vendor;

class VendorEarningsScreen extends ConsumerWidget {
  const VendorEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(vendorEarningsNotifierProvider);
    final balanceState = ref.watch(vendorBalanceNotifierProvider);
    final payoutHistoryState = ref.watch(payoutHistoryNotifierProvider);
    final destinationsState = ref.watch(
      payoutDestinationsControllerProvider(_vendorRole.value),
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Payouts & Earnings', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: DesignTokens.textWhite,
              size: 22,
            ),
            onPressed: () => context.push(RouteNames.vendorPaymentMethods),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: DesignTokens.primaryGreen,
        onRefresh: () async {
          await ref.read(vendorEarningsNotifierProvider.notifier).loadSummary();
          await ref.read(vendorBalanceNotifierProvider.notifier).load();
          await ref.read(payoutHistoryNotifierProvider.notifier).load();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Balance', style: DesignTokens.mediumSemibold),
                TextButton.icon(
                  onPressed: () => context.push(RouteNames.vendorEarningsPayout),
                  icon: const Icon(
                    Icons.request_quote_outlined,
                    size: 16,
                    color: DesignTokens.primaryGreen,
                  ),
                  label: Text(
                    'Request Payout',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            _buildBalanceCard(balanceState),
            const SizedBox(height: DesignTokens.s12),
            _buildNextPayoutBanner(summaryState, destinationsState),
            const SizedBox(height: DesignTokens.s20),
            _buildSummarySection(summaryState),
            const SizedBox(height: DesignTokens.s20),
            _buildPayoutHistorySection(context, payoutHistoryState),
            const SizedBox(height: DesignTokens.s20),
            _buildPaymentMethodsSection(context, destinationsState),
            const SizedBox(height: DesignTokens.s24),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BalanceState state) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: state.maybeWhen(
        loadSuccess: (balance) => Column(
          children: [
            _BalanceRow(
              icon: Icons.account_balance_wallet_outlined,
              iconColor: DesignTokens.primaryGreen,
              iconBg: const Color(0xFF1A3A1A),
              label: 'Available Balance',
              amount: balance.available,
            ),
            const SizedBox(height: DesignTokens.s16),
            _BalanceRow(
              icon: Icons.hourglass_bottom_outlined,
              iconColor: const Color(0xFFF1C40F),
              iconBg: const Color(0xFF2A2000),
              label: 'Pending Balance',
              amount: balance.pending,
            ),
          ],
        ),
        loadFailure: (_) => Text(
          'Balance unavailable.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.colorError,
          ),
        ),
        orElse: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextPayoutBanner(
    EarningsSummaryState summaryState,
    PayoutDestinationsState destinationsState,
  ) {
    final nextPayoutDate = summaryState.maybeWhen(
      loadSuccess: (summary) => summary.nextPayoutDate,
      orElse: () => null,
    );
    if (nextPayoutDate == null) return const SizedBox.shrink();

    final items = destinationsState.items;
    final destination = items.isEmpty
        ? null
        : items.firstWhere(
            (d) => d.isDefault,
            orElse: () => items.first,
          );

    return _NextPayoutBanner(date: nextPayoutDate, destination: destination);
  }

  Widget _buildSummarySection(EarningsSummaryState state) {
    return state.maybeWhen(
      loadSuccess: (summary) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatCard(
                icon: Icons.receipt_long_outlined,
                value: '${summary.totalOrders}',
                label: 'Total Orders',
              ),
              const SizedBox(width: DesignTokens.s8),
              _StatCard(
                icon: Icons.calendar_month_outlined,
                value: formatMoneyShort(summary.thisMonth),
                label: 'This Month',
              ),
              const SizedBox(width: DesignTokens.s8),
              _StatCard(
                icon: Icons.history_outlined,
                value: formatMoneyShort(summary.lastMonth),
                label: 'Last Month',
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s20),
          Text('Revenue Breakdown', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: [
                _RevenueRow(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Total Revenue',
                  amount: summary.totalRevenue,
                ),
                _RevenueRow(
                  icon: Icons.percent_outlined,
                  label: 'Platform Fees',
                  amount: summary.platformFees,
                  negative: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.s12),
                  child: _DashedDivider(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Net Earnings', style: DesignTokens.mediumSemibold),
                    MoneyText(
                      Money(
                        amount:
                            summary.totalRevenue.amount -
                            summary.platformFees.amount,
                        currency: summary.totalRevenue.currency,
                      ),
                      style: DesignTokens.mediumSemibold.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      loadFailure: (_) => Text(
        'Could not load earnings summary.',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.colorError,
        ),
      ),
      orElse: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
    );
  }

  Widget _buildPayoutHistorySection(
    BuildContext context,
    PayoutHistoryState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Payout History', style: DesignTokens.mediumSemibold),
            GestureDetector(
              onTap: () => context.push(RouteNames.vendorPayoutHistory),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: DesignTokens.primaryGreen,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        state.maybeWhen(
          loadSuccess: (payouts, hasMore) {
            if (payouts.isEmpty) {
              return Text(
                'No payouts yet.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              );
            }
            final preview = payouts.take(3).toList(growable: false);
            return Container(
              decoration: DesignTokens.cardDecoration(),
              child: Column(
                children: preview.asMap().entries.map((e) {
                  return Column(
                    children: [
                      if (e.key > 0)
                        const Divider(
                          color: DesignTokens.borderDefault,
                          height: 1,
                        ),
                      _PayoutTile(
                        payout: e.value,
                        onTap: () => context.push(
                          RouteNames.vendorStatementDetails,
                          extra: e.value.id,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
          loadFailure: (_) => Text(
            'Could not load payout history.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
          orElse: () => const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsSection(
    BuildContext context,
    PayoutDestinationsState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Methods', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s12),
        if (state.isLoading)
          const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
          )
        else if (state.items.isEmpty)
          TextButton(
            onPressed: () => context.push(RouteNames.vendorPaymentMethods),
            child: const Text('Add a payment method'),
          )
        else
          Container(
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: state.items
                  .map(
                    (m) => _PaymentMethodTile(
                      method: m,
                      onMenuTap: () =>
                          context.push(RouteNames.vendorPaymentMethods),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

String formatMoneyShort(Money money) {
  final amount = money.amount;
  if (amount >= 1000000) return 'Rs ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
  return 'Rs ${amount.toStringAsFixed(0)}';
}

// ── Balance row ───────────────────────────────────────────────────────────────

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.amount,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: DesignTokens.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            MoneyText(
              amount,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Next payout banner ───────────────────────────────────────────────────────

class _NextPayoutBanner extends StatelessWidget {
  const _NextPayoutBanner({required this.date, this.destination});

  final DateTime date;
  final PayoutDestinationDto? destination;

  @override
  Widget build(BuildContext context) {
    final scheduleText = destination != null
        ? 'Payouts are processed automatically every Friday & transferred '
              'to your ${destination!.label} '
              '${destination!.accountIdentifierMasked}.'
        : 'Payouts are processed automatically every Friday to your '
              'default payment method.';

    return ClipPath(
      clipper: const _ScallopTopClipper(),
      child: Container(
        width: double.infinity,
        color: DesignTokens.secondaryYellow,
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s20,
          DesignTokens.s16,
          DesignTokens.s16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/vendordashboard/Next payout.png',
              width: 36,
              height: 36,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Payout: '
                    '${DateFormat('EEE MMM d, yyyy').format(date.toLocal())}',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scheduleText,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textDark.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clips a wavy/scalloped top edge (ticket-stub look) with rounded bottom
/// corners, matching the payout-schedule banner design.
class _ScallopTopClipper extends CustomClipper<Path> {
  const _ScallopTopClipper();

  static const _bumpWidth = 20.0;
  static const _bumpHeight = 8.0;
  static const _cornerRadius = 16.0;

  @override
  Path getClip(Size size) {
    final count = (size.width / _bumpWidth).round().clamp(1, 1000);
    final segmentWidth = size.width / count;

    final path = Path()..moveTo(0, _bumpHeight);
    for (var i = 0; i < count; i++) {
      final midX = segmentWidth * i + segmentWidth / 2;
      final endX = segmentWidth * (i + 1);
      path.quadraticBezierTo(midX, 0, endX, _bumpHeight);
    }
    path
      ..lineTo(size.width, size.height - _cornerRadius)
      ..arcToPoint(
        Offset(size.width - _cornerRadius, size.height),
        radius: const Radius.circular(_cornerRadius),
      )
      ..lineTo(_cornerRadius, size.height)
      ..arcToPoint(
        Offset(0, size.height - _cornerRadius),
        radius: const Radius.circular(_cornerRadius),
      )
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: DesignTokens.textWhite, size: 24),
            const SizedBox(height: DesignTokens.s12),
            Text(
              value,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Revenue row ───────────────────────────────────────────────────────────────

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({
    required this.icon,
    required this.label,
    required this.amount,
    this.negative = false,
  });
  final IconData icon;
  final String label;
  final Money amount;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.textMuted, size: 16),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Row(
            children: [
              if (negative)
                Text(
                  '-',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              MoneyText(
                amount,
                style: DesignTokens.smallRegular.copyWith(
                  color: negative
                      ? DesignTokens.colorError
                      : DesignTokens.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Padding(
              padding: const EdgeInsets.only(right: dashSpace),
              child: Container(
                width: dashWidth,
                height: 1,
                color: DesignTokens.borderDefault,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Payout tile ───────────────────────────────────────────────────────────────

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.payout, required this.onTap});
  final VendorPayout payout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = PayoutDestinationKind.fromValue(payout.destinationKind);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: DesignTokens.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payout to ${kind.label}',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat(
                      'MMM d, yyyy',
                    ).format(payout.requestedAt.toLocal()),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: payout.state.bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      payout.state.label,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: payout.state.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            MoneyText(
              payout.netAmount,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment method tile ───────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({required this.method, required this.onMenuTap});
  final PayoutDestinationDto method;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      method.label,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (method.isDefault) ...[
                      const SizedBox(width: DesignTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A2A3A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Default',
                          style: DesignTokens.smallRegular.copyWith(
                            color: const Color(0xFF4DA6FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  method.accountIdentifierMasked,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: DesignTokens.textMuted,
              size: 20,
            ),
            onPressed: onMenuTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
