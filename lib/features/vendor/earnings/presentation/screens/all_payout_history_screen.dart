import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AllPayoutHistoryScreen extends ConsumerWidget {
  const AllPayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(payoutHistoryNotifierProvider);

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
        title: Text('All Payout History', style: DesignTokens.oneLinerSemibold),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load payout history.',
          onRetry: () =>
              ref.read(payoutHistoryNotifierProvider.notifier).load(),
        ),
        loadSuccess: (payouts, hasMore) {
          if (payouts.isEmpty) {
            return const SmEmptyState(
              message: 'No payouts yet.',
              icon: Icons.account_balance_wallet_outlined,
            );
          }
          final groups = _groupByMonth(payouts);
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () =>
                ref.read(payoutHistoryNotifierProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              children: groups.entries
                  .expand(
                    (group) => [
                      Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                        child: Text(
                          group.key,
                          style: DesignTokens.smallRegular.copyWith(
                            color: const Color(0xFFD4D4D8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Container(
                        decoration: DesignTokens.cardDecoration(),
                        child: Column(
                          children: group.value.asMap().entries.map((e) {
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
                      ),
                      const SizedBox(height: DesignTokens.s12),
                    ],
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Map<String, List<VendorPayout>> _groupByMonth(List<VendorPayout> payouts) {
    final byMonth = <String, List<VendorPayout>>{};
    for (final p in payouts) {
      final label = DateFormat('MMM yyyy').format(p.requestedAt.toLocal());
      (byMonth[label] ??= []).add(p);
    }
    return byMonth;
  }
}

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
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0D2137),
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: Color(0xFF4DA6FF),
                size: 18,
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
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payout.destinationRef,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  payout.netAmount,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: payout.state.bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payout.state.label,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: payout.state.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension VendorPayoutStateX on VendorPayoutState {
  String get label => switch (this) {
    VendorPayoutState.requested => 'Requested',
    VendorPayoutState.processing => 'Processing',
    VendorPayoutState.paid => 'Completed',
    VendorPayoutState.failed => 'Failed',
    VendorPayoutState.held => 'Held',
  };

  Color get textColor => switch (this) {
    VendorPayoutState.paid => DesignTokens.primaryGreen,
    VendorPayoutState.failed => DesignTokens.colorError,
    VendorPayoutState.requested ||
    VendorPayoutState.processing ||
    VendorPayoutState.held => const Color(0xFFFFB800),
  };

  Color get bgColor => switch (this) {
    VendorPayoutState.paid => const Color(0xFF0D2A0D),
    VendorPayoutState.failed => const Color(0xFF2A0A0A),
    VendorPayoutState.requested ||
    VendorPayoutState.processing ||
    VendorPayoutState.held => const Color(0xFF2A2000),
  };
}
