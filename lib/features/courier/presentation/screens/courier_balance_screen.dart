import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the rider has earned, and the deliveries it came from.
///
/// Two different kinds of money live on this screen and they are labelled
/// apart on purpose:
///
/// * **Earned** — the sum of the hops they completed. This is pay.
/// * **Escrow** — their own security deposit, which couriers above the
///   Neighbour tier must hold against the parcels they carry. They paid it in
///   and can withdraw it.
///
/// Before this the app could only show escrow, so the only money figure a
/// courier ever saw was their own deposit. Presenting that under the word
/// "balance" would tell them they had been paid for work they had not been
/// paid for, which is why the deposit is in its own section with its own
/// explanation rather than folded into a single total.
class CourierBalanceScreen extends ConsumerWidget {
  const CourierBalanceScreen({required this.courierProfileId, super.key});

  final String courierProfileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(courierEarningsProvider);
    final history = ref.watch(courierEarningsHistoryProvider);
    final escrow = ref.watch(courierEscrowBalanceProvider(courierProfileId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Balance'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(courierEarningsProvider)
              ..invalidate(courierEarningsHistoryProvider)
              ..invalidate(courierEscrowBalanceProvider(courierProfileId));
          },
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s20),
            children: [
              earnings.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: SmBrandLoader()),
                ),
                error: (_, _) => const _Unavailable(
                  'Your earnings could not be loaded. Pull down to try again.',
                ),
                data: _TotalCard.new,
              ),

              const SizedBox(height: DesignTokens.s24),
              Text('Deliveries', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s8),
              history.when(
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: SmBrandLoader(size: 40)),
                ),
                error: (_, _) => const _Unavailable(
                  'The delivery list could not be loaded.',
                ),
                data: (rows) => rows.isEmpty
                    ? Text(
                        'Nothing completed yet. Finished deliveries and what '
                        'they paid will appear here.',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      )
                    : Column(
                        children: [
                          for (final row in rows) _EarningRow(row: row),
                        ],
                      ),
              ),

              const SizedBox(height: DesignTokens.s24),
              Text('Your deposit', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Held against the parcels you carry, not earnings. It is your '
                'money and it comes back to you.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              escrow.when(
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(child: SmBrandLoader(size: 32)),
                ),
                // 404 is normal for a Neighbour-tier courier who holds none,
                // so this reads as "nothing held" rather than as a failure.
                error: (_, _) => Text(
                  'No deposit held.',
                  style: DesignTokens.bodyText,
                ),
                data: (money) => Text(
                  formatMoney(
                    Money(amount: money.amount, currency: money.currency),
                  ),
                  style: DesignTokens.h3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard(this.earnings);

  final CourierEarnings earnings;

  @override
  Widget build(BuildContext context) {
    // No currency until the first hop is completed, so the zero is shown
    // bare rather than stamped with a currency nobody has been paid in.
    String money(double amount) => earnings.currency.isEmpty
        ? amount.toStringAsFixed(0)
        : formatMoney(Money(amount: amount, currency: earnings.currency));

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total earned',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(money(earnings.totalEarned), style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'Last 7 days',
                    value: money(earnings.last7Days),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Last 30 days',
                    value: money(earnings.last30Days),
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Deliveries',
                    value: '${earnings.completedHops}',
                  ),
                ),
              ],
            ),
            if (!earnings.hasEarned) ...[
              const SizedBox(height: DesignTokens.s12),
              Text(
                'Complete your first delivery and it will show up here.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: DesignTokens.mediumSemibold),
      Text(
        label,
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
    ],
  );
}

class _EarningRow extends StatelessWidget {
  const _EarningRow({required this.row});

  final CourierEarningRow row;

  @override
  Widget build(BuildContext context) {
    final when = row.handedOffUtc?.toLocal();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leg number, because a parcel can pass through several
                // couriers and "hop 2" is what the rider actually did.
                Text('Leg ${row.hopIndex + 1}', style: DesignTokens.bodyText),
                Text(
                  when == null
                      ? 'Completed'
                      : '${when.day}/${when.month}/${when.year}',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            row.currency.isEmpty
                ? row.amount.toStringAsFixed(0)
                : formatMoney(
                    Money(amount: row.amount, currency: row.currency),
                  ),
            style: DesignTokens.mediumSemibold,
          ),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
  );
}
