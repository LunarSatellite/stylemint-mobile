import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_payout.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_fare_breakdown.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_payout_request_sheet.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/payout_providers.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';
import 'package:stylemint_mobile_frontend/features/payouts/presentation/screens/payment_methods_screen.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The rider's money: what they can be paid, what is still settling, the
/// cash they owe back, where payouts go, the payouts themselves and the
/// deliveries behind it all (rider-payout contract v1).
///
/// The courier's escrow deposit is at the bottom in its own section. It is
/// their own money held against the parcels they carry — never pay — and is
/// labelled so, because a deposit shown as a balance would tell a rider they
/// had been paid for work they had not.
///
/// Until the payout ledger is deployed its endpoints 404. Each section then
/// says payouts are being set up and the screen falls back to what the
/// delivery module already knows: lifetime totals and completed deliveries.
class CourierBalanceScreen extends ConsumerWidget {
  const CourierBalanceScreen({required this.courierProfileId, super.key});

  final String courierProfileId;

  static const Key settingUpKey = ValueKey<String>('courier-payouts-setting-up');
  static const Key balanceErrorKey = ValueKey<String>('courier-balance-error');
  static const Key requestKey = ValueKey<String>('courier-payout-request');
  static const Key netPayableKey = ValueKey<String>('courier-net-payable');

  static const settingUpTitle = 'Payouts are being set up';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(courierBalanceProvider);
    final balanceSettingUp = courierPayoutsSettingUp(balance.error);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Earnings'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(courierBalanceProvider)
              ..invalidate(courierPayoutEarningsProvider)
              ..invalidate(courierPayoutsProvider)
              ..invalidate(courierPayoutDestinationsProvider)
              ..invalidate(courierEarningsProvider)
              ..invalidate(courierEarningsHistoryProvider)
              ..invalidate(courierEscrowBalanceProvider(courierProfileId));
          },
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s20),
            children: [
              // Not when(): a failed read must show its state at once, and
              // a 404 must read as "being set up", not as an error.
              switch ((balance.value, balance.error)) {
                (final CourierBalance b, _) => _BalanceCard(balance: b),
                (_, final Object _) when balanceSettingUp => const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CourierPayoutsSettingUp(),
                    SizedBox(height: DesignTokens.s12),
                    _LegacyTotalCard(),
                  ],
                ),
                (_, final Object _) => _Problem(
                  key: balanceErrorKey,
                  message:
                      'Your balance could not be loaded. Pull down to try '
                      'again.',
                  onRetry: () => ref.invalidate(courierBalanceProvider),
                ),
                _ => const SizedBox(
                  height: 160,
                  child: Center(child: SmBrandLoader()),
                ),
              },

              if (!balanceSettingUp) ...[
                const SizedBox(height: DesignTokens.s24),
                const _DestinationsSection(),
                const SizedBox(height: DesignTokens.s24),
                const _PayoutsSection(),
              ],

              const SizedBox(height: DesignTokens.s24),
              Text('Deliveries', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s8),
              if (balanceSettingUp)
                const _LegacyHistory()
              else
                const _EarningsHistory(),

              const SizedBox(height: DesignTokens.s24),
              _DepositSection(courierProfileId: courierProfileId),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown where the payout ledger's figures will be, until it is deployed.
class CourierPayoutsSettingUp extends StatelessWidget {
  const CourierPayoutsSettingUp({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: CourierBalanceScreen.settingUpKey,
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.construction_rounded, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                CourierBalanceScreen.settingUpTitle,
                style: DesignTokens.mediumSemibold,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Soon you will see what you can be paid, the cash you '
                'collected and your payouts here. Your deliveries are still '
                'recorded and count towards it.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Balance ─────────────────────────────────────────────────────────────────

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard({required this.balance});

  final CourierBalance balance;

  Future<void> _request(BuildContext context, WidgetRef ref) async {
    List<PayoutDestinationDto>? destinations;
    try {
      destinations = await ref.read(courierPayoutDestinationsProvider.future);
    } on Object {
      destinations = null;
    }
    if (!context.mounted) return;
    if (destinations == null) {
      SmSnackbar.error(
        context,
        'Your payout methods could not be loaded. Try again.',
      );
      return;
    }
    if (destinations.isEmpty) {
      SmSnackbar.info(context, 'Add a payout method first.');
      await _openMethods(context, ref);
      return;
    }
    final payout = await showCourierPayoutRequestSheet(
      context,
      balance: balance,
      destinations: destinations,
    );
    if (payout != null && context.mounted) {
      SmSnackbar.success(
        context,
        'Payout of ${formatMoney(payout.money(payout.netAmount))} requested.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = balance;
    final inFlight = b.inFlightPayout;
    final min = b.onDemandMinAmount;
    final belowMinimum = min != null && b.netPayable > 0 && b.netPayable < min;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s20),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            b.owesCash ? 'You owe' : 'You can be paid',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            formatMoney(b.money(b.netPayable.abs())),
            key: CourierBalanceScreen.netPayableKey,
            style: DesignTokens.h2.copyWith(
              color: b.owesCash ? DesignTokens.colorError : null,
            ),
          ),
          if (b.owesCash)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: Text(
                'The cash you collected is more than your earnings. Hand it '
                'in at the hub; payouts start again once it is recorded.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Available',
                  value: formatMoney(b.money(b.availableEarnings)),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: b.onHoldEarnings > 0
                      ? 'Pending · ${formatMoney(b.money(b.onHoldEarnings), decimalDigits: 0)} on hold'
                      : 'Pending',
                  value: formatMoney(b.money(b.pendingEarnings)),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Cash to hand in',
                  value: formatMoney(b.money(b.cashToRemit)),
                  warn: b.cashToRemit > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            [
              if (b.settleAfterHours case final h?)
                'Deliveries become available $h hours after hand-off.',
              if (b.cashToRemit > 0)
                'Cash you have not handed in is taken off your payout.',
            ].join(' '),
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s16),
          if (inFlight != null)
            _InFlight(payout: inFlight)
          else ...[
            FilledButton(
              key: CourierBalanceScreen.requestKey,
              onPressed: b.netPayable > 0 && !belowMinimum
                  ? () => _request(context, ref)
                  : null,
              child: const Text('Request payout'),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              belowMinimum
                  ? 'On-demand payouts start at '
                        '${formatMoney(b.money(min ?? 0), decimalDigits: 0)}. '
                        'Smaller balances are paid automatically every '
                        'Friday to your default method.'
                  : 'Paid automatically every Friday to your default '
                        'method${b.hasDefaultDestination ? '' : ' — add one below'}.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Earned in total: ${formatMoney(b.money(b.lifetimeEarnings))}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
          ),
        ],
      ),
    );
  }
}

class _InFlight extends StatelessWidget {
  const _InFlight({required this.payout});

  final CourierPayout payout;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.s8),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 18,
          color: DesignTokens.textLight,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            'A payout of ${formatMoney(payout.money(payout.netAmount))} is '
            '${payout.state.label.toLowerCase()}. You can ask again once it '
            'is paid.',
            style: DesignTokens.smallRegular,
          ),
        ),
      ],
    ),
  );
}

/// Lifetime totals from the delivery module — what the old screen showed,
/// kept while the payout ledger is not deployed.
class _LegacyTotalCard extends ConsumerWidget {
  const _LegacyTotalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnings = ref.watch(courierEarningsProvider);
    return earnings.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: SmBrandLoader(size: 40)),
      ),
      error: (_, _) => const _Problem(
        message: 'Your earnings could not be loaded. Pull down to try again.',
      ),
      data: (e) {
        String money(double amount) => e.currency.isEmpty
            ? amount.toStringAsFixed(0)
            : formatMoney(Money(amount: amount, currency: e.currency));
        return Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
          child: Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Earned in total',
                  value: money(e.totalEarned),
                ),
              ),
              Expanded(
                child: _Stat(label: 'Last 7 days', value: money(e.last7Days)),
              ),
              Expanded(
                child: _Stat(
                  label: 'Deliveries',
                  value: '${e.completedHops}',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Destinations ────────────────────────────────────────────────────────────

Future<void> _openMethods(BuildContext context, WidgetRef ref) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => const PayoutMethodsScreen(role: PayeeKind.courier),
    ),
  );
  ref
    ..invalidate(courierPayoutDestinationsProvider)
    ..invalidate(courierBalanceProvider);
}

class _DestinationsSection extends ConsumerWidget {
  const _DestinationsSection();

  static const Key manageKey = ValueKey<String>('courier-payout-methods');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(courierPayoutDestinationsProvider);
    final error = destinations.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Payout methods', style: DesignTokens.h3)),
            if (!courierPayoutsSettingUp(error))
              TextButton(
                key: manageKey,
                onPressed: () => _openMethods(context, ref),
                child: const Text('Manage'),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        switch ((destinations.value, error)) {
          (final List<PayoutDestinationDto> list, _) when list.isEmpty => Text(
            'No payout method yet. Add a bank account or wallet to get paid.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          (final List<PayoutDestinationDto> list, _) => Column(
            children: [for (final d in list) _DestinationRow(destination: d)],
          ),
          (_, final Object e) when courierPayoutsSettingUp(e) => Text(
            'Adding a payout method will be possible here shortly.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          (_, final Object _) => _Problem(
            message: 'Your payout methods could not be loaded.',
            onRetry: () => ref.invalidate(courierPayoutDestinationsProvider),
          ),
          _ => const SizedBox(
            height: 48,
            child: Center(child: SmBrandLoader(size: 32)),
          ),
        },
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({required this.destination});

  final PayoutDestinationDto destination;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        children: [
          Icon(
            d.kind.requiresBranch
                ? Icons.account_balance_rounded
                : Icons.account_balance_wallet_rounded,
            size: 20,
            color: DesignTokens.textLight,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.label.isEmpty ? d.kind.label : d.label,
                  style: DesignTokens.bodyText,
                ),
                // Masked by the server; never the full number.
                Text(
                  '${d.kind.label} · ${d.accountIdentifierMasked}',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (d.isDefault) const _Chip(text: 'Default', color: DesignTokens.primaryGreen),
        ],
      ),
    );
  }
}

// ── Payouts ─────────────────────────────────────────────────────────────────

class _PayoutsSection extends ConsumerWidget {
  const _PayoutsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payouts = ref.watch(courierPayoutsProvider(null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Payouts', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s8),
        switch ((payouts.value, payouts.error)) {
          (final CourierPage<CourierPayout> page, _) when page.items.isEmpty =>
            Text(
              'No payouts yet.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          (final CourierPage<CourierPayout> page, _) => Column(
            children: [
              for (final p in page.items) CourierPayoutRow(payout: p),
            ],
          ),
          (_, final Object e) when courierPayoutsSettingUp(e) => Text(
            'Your payouts will be listed here shortly.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          (_, final Object _) => _Problem(
            message: 'Your payouts could not be loaded.',
            onRetry: () => ref.invalidate(courierPayoutsProvider),
          ),
          _ => const SizedBox(
            height: 48,
            child: Center(child: SmBrandLoader(size: 32)),
          ),
        },
      ],
    );
  }
}

/// One payout: amount, state, and what the rider needs for that state —
/// the release date while requested, the transfer reference once paid, the
/// reason when it failed.
class CourierPayoutRow extends StatelessWidget {
  const CourierPayoutRow({required this.payout, super.key});

  final CourierPayout payout;

  @override
  Widget build(BuildContext context) {
    final p = payout;
    final (color, detail) = switch (p.state) {
      CourierPayoutState.paid => (
        DesignTokens.primaryGreen,
        [
          if (p.paidUtc case final at?) 'Paid ${_date(at)}',
          if (p.reference case final ref?) 'Ref $ref',
        ].join(' · '),
      ),
      CourierPayoutState.failed => (
        DesignTokens.colorError,
        p.failureReason == null
            ? 'Not sent. The amount is back in your balance.'
            : '${p.failureReason}. The amount is back in your balance.',
      ),
      CourierPayoutState.awaitingTransfer => (
        DesignTokens.colorInfo,
        'Finance is sending the transfer.',
      ),
      CourierPayoutState.requested => (
        DesignTokens.colorWarning,
        p.pendingUntilUtc == null
            ? 'Requested.'
            : 'Goes to finance after ${_date(p.pendingUntilUtc!)}.',
      ),
      CourierPayoutState.held => (
        DesignTokens.colorWarning,
        'On hold while support checks it.',
      ),
      _ => (DesignTokens.textLight, ''),
    };
    final to = [
      if (p.destinationKind case final k?)
        PayoutDestinationKind.fromValue(k).label,
      if (p.destinationRef case final ref?) ref,
    ].join(' ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatMoney(p.money(p.netAmount)),
                  style: DesignTokens.mediumSemibold,
                ),
                Text(
                  [
                    if (p.requestedUtc case final at?) _date(at),
                    if (p.automatic) 'Weekly' else 'On demand',
                    if (p.feeAmount > 0)
                      'fee ${formatMoney(p.money(p.feeAmount))}',
                    if (to.isNotEmpty) 'to $to',
                  ].join(' · '),
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: DesignTokens.tiny.copyWith(
                      color: p.state == CourierPayoutState.failed
                          ? DesignTokens.colorError
                          : DesignTokens.textLight,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          _Chip(text: p.state.label, color: color),
        ],
      ),
    );
  }
}

// ── Earnings history ────────────────────────────────────────────────────────

/// The payout ledger's deliveries, a page at a time. Each page is its own
/// provider keyed by cursor, so "Show more" appends without re-reading.
class _EarningsHistory extends ConsumerStatefulWidget {
  const _EarningsHistory();

  @override
  ConsumerState<_EarningsHistory> createState() => _EarningsHistoryState();
}

class _EarningsHistoryState extends ConsumerState<_EarningsHistory> {
  final List<String?> _cursors = [null];

  @override
  Widget build(BuildContext context) {
    final first = ref.watch(courierPayoutEarningsProvider(null));
    if (first.error case final Object e when first.value == null) {
      if (courierPayoutsSettingUp(e)) return const _LegacyHistory();
      return _Problem(
        message: 'The delivery list could not be loaded.',
        onRetry: () => ref.invalidate(courierPayoutEarningsProvider),
      );
    }
    final firstPage = first.value;
    if (firstPage == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: SmBrandLoader(size: 40)),
      );
    }
    if (firstPage.items.isEmpty) {
      return const _NothingYet();
    }

    final rows = <Widget>[];
    CourierPage<CourierPayoutEarning>? last;
    for (final cursor in _cursors) {
      final page = ref.watch(courierPayoutEarningsProvider(cursor));
      final value = page.value;
      if (value == null) {
        rows.add(
          page.hasError
              ? _Problem(
                  message: 'More deliveries could not be loaded.',
                  onRetry: () =>
                      ref.invalidate(courierPayoutEarningsProvider(cursor)),
                )
              : const Padding(
                  padding: EdgeInsets.all(DesignTokens.s8),
                  child: Center(child: SmBrandLoader(size: 32)),
                ),
        );
        last = null;
        break;
      }
      rows.addAll(value.items.map((e) => CourierEarningTile(earning: e)));
      last = value;
    }

    final next = last?.nextCursor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...rows,
        if (last != null && last.hasMore && next != null)
          TextButton(
            onPressed: () => setState(() => _cursors.add(next)),
            child: const Text('Show more'),
          ),
      ],
    );
  }
}

/// One delivery on the payout ledger, with its status and, on tap, how the
/// fare was made up.
class CourierEarningTile extends StatefulWidget {
  const CourierEarningTile({required this.earning, super.key});

  final CourierPayoutEarning earning;

  @override
  State<CourierEarningTile> createState() => _CourierEarningTileState();
}

class _CourierEarningTileState extends State<CourierEarningTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.earning;
    final fare = e.fare;
    final hasFare = fare != null && fare.isItemised;
    final hasLines = e.lines.length > 1;
    final expandable = hasFare || hasLines;

    final statusColor = switch (e.status) {
      CourierEarningStatus.available => DesignTokens.primaryGreen,
      CourierEarningStatus.onHold => DesignTokens.colorWarning,
      CourierEarningStatus.reversed => DesignTokens.colorError,
      _ => DesignTokens.textLight,
    };
    final note = switch (e.status) {
      CourierEarningStatus.pending when e.settleAfterUtc != null =>
        'Available after ${_date(e.settleAfterUtc!)}',
      CourierEarningStatus.onHold =>
        e.holdReason == null ? 'Held while support checks the delivery' : 'On hold: ${e.holdReason}',
      CourierEarningStatus.reversed => 'Taken back — this delivery did not count',
      _ => null,
    };

    return InkWell(
      onTap: expandable ? () => setState(() => _open = !_open) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.trackingNumber ?? 'Delivery',
                        style: DesignTokens.bodyText,
                      ),
                      Text(
                        [
                          if (e.completedUtc case final at?) _date(at),
                          if (e.cashCollected case final cash?)
                            'collected ${formatMoney(Money(amount: cash, currency: e.currency))} cash',
                        ].join(' · '),
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      if (note != null)
                        Text(
                          note,
                          style: DesignTokens.tiny.copyWith(color: statusColor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatMoney(e.money),
                      style: DesignTokens.mediumSemibold.copyWith(
                        decoration: e.status == CourierEarningStatus.reversed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    _Chip(text: e.status.label, color: statusColor),
                  ],
                ),
                if (expandable)
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: DesignTokens.textMuted,
                  ),
              ],
            ),
            if (_open && fare != null && fare.isItemised)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s8),
                child: CourierFareBreakdown(fare: fare, dense: true),
              )
            else if (_open && hasLines)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s8),
                child: Column(
                  children: [
                    for (final line in e.lines)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              line.label,
                              style: DesignTokens.tiny.copyWith(
                                color: DesignTokens.textLight,
                              ),
                            ),
                          ),
                          Text(
                            formatMoney(
                              Money(amount: line.amount, currency: e.currency),
                            ),
                            style: DesignTokens.tiny,
                          ),
                        ],
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

/// Completed deliveries from the delivery module, while the payout ledger is
/// not deployed. These carry the fare breakdown too.
class _LegacyHistory extends ConsumerWidget {
  const _LegacyHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(courierEarningsHistoryProvider);
    return history.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: SmBrandLoader(size: 40)),
      ),
      error: (_, _) =>
          const _Problem(message: 'The delivery list could not be loaded.'),
      data: (rows) => rows.isEmpty
          ? const _NothingYet()
          : Column(
              children: [for (final row in rows) _LegacyRow(row: row)],
            ),
    );
  }
}

class _LegacyRow extends StatelessWidget {
  const _LegacyRow({required this.row});

  final CourierEarningRow row;

  @override
  Widget build(BuildContext context) {
    final when = row.handedOffUtc;
    final fare = row.fare;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Leg number, because a parcel can pass through several
                    // couriers and "hop 2" is what the rider actually did.
                    Text(
                      'Leg ${row.hopIndex + 1}',
                      style: DesignTokens.bodyText,
                    ),
                    Text(
                      when == null ? 'Completed' : _date(when),
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
          if (fare != null && fare.isItemised)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s4),
              child: CourierFareBreakdown(
                fare: fare,
                dense: true,
                showTotal: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _NothingYet extends StatelessWidget {
  const _NothingYet();

  @override
  Widget build(BuildContext context) => Text(
    'Nothing completed yet. Finished deliveries and what they paid will '
    'appear here.',
    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
  );
}

// ── Deposit (escrow) ────────────────────────────────────────────────────────

class _DepositSection extends ConsumerWidget {
  const _DepositSection({required this.courierProfileId});

  final String courierProfileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escrow = ref.watch(courierEscrowBalanceProvider(courierProfileId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your deposit', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Held against the parcels you carry. Not earnings and not part of '
          'your payouts — it is your money and it comes back to you.',
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
          // 404 is normal for a Neighbour-tier courier who holds none; any
          // other failure is "could not load", never "none".
          error: (error, _) =>
              error is NetworkExceptions && error.isNotFound
              ? Text('No deposit held.', style: DesignTokens.bodyText)
              : Text(
                  'Your deposit could not be loaded.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
          data: (money) => Text(
            formatMoney(Money(amount: money.amount, currency: money.currency)),
            style: DesignTokens.h3,
          ),
        ),
      ],
    );
  }
}

// ── Bits ────────────────────────────────────────────────────────────────────

String _date(DateTime utc) {
  final local = utc.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.warn = false});

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: DesignTokens.mediumSemibold.copyWith(
          color: warn ? DesignTokens.colorWarning : null,
        ),
      ),
      Text(
        label,
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(DesignTokens.s8),
    ),
    child: Text(text, style: DesignTokens.tiny.copyWith(color: color)),
  );
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          message,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ),
      if (onRetry != null)
        TextButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}
