import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_balance.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_transaction.dart';
import 'package:stylemint_mobile_frontend/features/wallet/presentation/notifiers/wallet_notifier.dart';
import 'package:stylemint_mobile_frontend/features/wallet/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final _nprFmt = NumberFormat('#,##0.00', 'en_US');
String _npr(double amount) => 'Rs ${_nprFmt.format(amount)}';

// ── Root screen ───────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Wallet', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: () => const _Loader(),
        loading: () => const _Loader(),
        loaded: (balance, transactions, loadingMore, hasMore) => _LoadedBody(
          balance: balance,
          transactions: transactions,
          loadingMore: loadingMore,
          hasMore: hasMore,
        ),
        failure: (f) => _ErrorBody(
          message: NetworkExceptions.getMessage(f),
          onRetry: () => ref.read(walletNotifierProvider.notifier).load(),
        ),
      ),
    );
  }
}

// ── Loaded body ───────────────────────────────────────────────────────────────

class _LoadedBody extends ConsumerWidget {
  const _LoadedBody({
    required this.balance,
    required this.transactions,
    required this.loadingMore,
    required this.hasMore,
  });

  final WalletBalance balance;
  final List<WalletTransaction> transactions;
  final bool loadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = _groupByDate(transactions);

    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      backgroundColor: DesignTokens.bgAppBody,
      onRefresh: () async =>
          ref.read(walletNotifierProvider.notifier).load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Balance card ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                0,
              ),
              child: _BalanceCard(balance: balance),
            ),
          ),

          // ── Status banners ────────────────────────────────────────────────
          if (balance.status == 'Frozen')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s12,
                  DesignTokens.s16,
                  0,
                ),
                child: _StatusBanner(
                  icon: Icons.ac_unit_rounded,
                  color: DesignTokens.colorInfo,
                  message:
                      'Your wallet is temporarily frozen. Please contact support to resolve this.',
                ),
              ),
            ),
          if (balance.status == 'Closed')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s12,
                  DesignTokens.s16,
                  0,
                ),
                child: _StatusBanner(
                  icon: Icons.block_rounded,
                  color: DesignTokens.colorError,
                  message: 'This wallet has been closed.',
                ),
              ),
            ),

          // ── Section title ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s28,
                DesignTokens.s16,
                DesignTokens.s4,
              ),
              child: Row(
                children: [
                  const Text(
                    'Transaction History',
                    style: DesignTokens.sectionInnerTitle,
                  ),
                  const Spacer(),
                  if (transactions.isNotEmpty)
                    Text(
                      '${transactions.length} records',
                      style: DesignTokens.smallRegular,
                    ),
                ],
              ),
            ),
          ),

          // ── Empty state ───────────────────────────────────────────────────
          if (transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyTransactions(),
            )
          else ...[
            // ── Grouped transaction list ──────────────────────────────────
            for (final entry in grouped.entries) ...[
              SliverToBoxAdapter(
                child: _DateHeader(label: entry.key),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final tx = entry.value[i];
                      final isLast = i == entry.value.length - 1;
                      return _TransactionTile(
                        tx: tx,
                        isLast: isLast,
                        onTap: () => _showDetail(ctx, tx),
                      );
                    },
                    childCount: entry.value.length,
                  ),
                ),
              ),
            ],

            // ── Load more ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: loadingMore
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(DesignTokens.s12),
                          child: CircularProgressIndicator(
                            color: DesignTokens.primaryGreen,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : hasMore
                        ? SizedBox(
                            width: double.infinity,
                            height: DesignTokens.buttonHeight,
                            child: OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(walletNotifierProvider.notifier)
                                  .loadMore(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DesignTokens.textLight,
                                side: const BorderSide(
                                  color: DesignTokens.borderDefault,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.cardRadius,
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.expand_more_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Load more',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              'You\'ve reached the end',
                              style: DesignTokens.smallRegular,
                            ),
                          ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s32)),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, WalletTransaction tx) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _TransactionDetail(tx: tx),
    );
  }

  static Map<String, List<WalletTransaction>> _groupByDate(
    List<WalletTransaction> txs,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final map = <String, List<WalletTransaction>>{};
    for (final tx in txs) {
      final d = tx.occurredUtc.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      final String bucket;
      if (!day.isBefore(today)) {
        bucket = 'Today';
      } else if (!day.isBefore(yesterday)) {
        bucket = 'Yesterday';
      } else if (!day.isBefore(weekAgo)) {
        bucket = 'This Week';
      } else {
        bucket = 'Earlier';
      }
      map.putIfAbsent(bucket, () => []).add(tx);
    }
    return map;
  }
}

// ── Balance card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final WalletBalance balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          // ── Top section — available balance ───────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2D1A), Color(0xFF0A1F12)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(DesignTokens.s20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Currency chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                    border: Border.all(
                      color: DesignTokens.primaryGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: DesignTokens.primaryGreen,
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        'NPR Wallet',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),

                // Label
                Text(
                  'Available Balance',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),

                // Amount — large
                Text(
                  _npr(balance.available),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: DesignTokens.primaryGreen,
                  ),
                ),

                // Status badge
                const SizedBox(height: DesignTokens.s12),
                _StatusChip(status: balance.status),
              ],
            ),
          ),

          // ── Bottom section — pending balance ──────────────────────────────
          Container(
            width: double.infinity,
            color: DesignTokens.bgAppBody,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s20,
              vertical: DesignTokens.s16,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A2F03),
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                  ),
                  child: const Icon(
                    Icons.hourglass_bottom_rounded,
                    size: 20,
                    color: DesignTokens.secondaryYellow,
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending Balance',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _npr(balance.pending),
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: DesignTokens.secondaryYellow,
                        ),
                      ),
                    ],
                  ),
                ),
                // Info tooltip
                Tooltip(
                  message: 'Refunds or credits not yet cleared',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label, icon) = switch (status) {
      'Frozen' => (DesignTokens.colorInfo, 'Frozen', Icons.ac_unit_rounded),
      'Closed' => (DesignTokens.colorError, 'Closed', Icons.block_rounded),
      _ => (DesignTokens.primaryGreen, 'Active', Icons.check_circle_outline_rounded),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              message,
              style: DesignTokens.smallRegular.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date section header ───────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s20,
        DesignTokens.s16,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          const Expanded(
            child: Divider(
              color: DesignTokens.borderDefault,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction tile ──────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.isLast,
    required this.onTap,
  });

  final WalletTransaction tx;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isReversal = tx.type == 'Reversal';
    final isDebit = tx.type == 'Debit';
    final isPending =
        tx.type == 'PendingCredit' || tx.type == 'PendingClear';

    final amountColor = isReversal
        ? DesignTokens.textMuted
        : isPending
            ? DesignTokens.secondaryYellow
            : isDebit
                ? DesignTokens.colorError
                : DesignTokens.primaryGreen;

    final amountPrefix = isDebit ? '− ' : '+ ';
    final amountStr =
        isReversal ? _npr(tx.amount) : '$amountPrefix${_npr(tx.amount)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(0),
        topRight: const Radius.circular(0),
        bottomLeft:
            isLast ? const Radius.circular(DesignTokens.cardRadius) : Radius.zero,
        bottomRight:
            isLast ? const Radius.circular(DesignTokens.cardRadius) : Radius.zero,
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.only(
            bottomLeft: isLast
                ? const Radius.circular(DesignTokens.cardRadius)
                : Radius.zero,
            bottomRight: isLast
                ? const Radius.circular(DesignTokens.cardRadius)
                : Radius.zero,
          ),
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(
                    color: DesignTokens.borderDefault,
                    width: 0.5,
                  ),
          ),
        ),
        child: Row(
          children: [
            _TxIcon(type: tx.type),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(tx),
                    style: DesignTokens.mediumRegular.copyWith(
                      color: isReversal
                          ? DesignTokens.textMuted
                          : DesignTokens.textWhite,
                      decoration: isReversal
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM d · h:mm a')
                        .format(tx.occurredUtc.toLocal()),
                    style: DesignTokens.smallRegular,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountStr,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: amountColor,
                    decoration: isReversal
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rs ${_nprFmt.format(tx.balanceAfter)} after',
                  style: DesignTokens.smallRegular.copyWith(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: DesignTokens.s8),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.iconLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  static String _label(WalletTransaction tx) => switch (tx.type) {
        'Credit' => switch (tx.source) {
            'Refund' => 'Refund',
            'AdminAdjustment' => 'Credit Added',
            _ => 'Credit',
          },
        'Debit' => 'Withdrawn',
        'PendingCredit' => 'Refund Processing',
        'PendingClear' => 'Credit Cleared',
        'Reversal' => 'Reversed',
        _ => tx.type,
      };
}

class _TxIcon extends StatelessWidget {
  const _TxIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = switch (type) {
      'Credit' => (
          Icons.arrow_downward_rounded,
          DesignTokens.primaryGreenDark,
          DesignTokens.primaryGreen,
        ),
      'PendingCredit' => (
          Icons.hourglass_top_rounded,
          const Color(0xFF3A2F03),
          DesignTokens.secondaryYellow,
        ),
      'PendingClear' => (
          Icons.check_circle_outline_rounded,
          const Color(0xFF3A2F03),
          DesignTokens.secondaryYellow,
        ),
      'Debit' => (
          Icons.arrow_upward_rounded,
          const Color(0xFF2D0A0A),
          DesignTokens.colorError,
        ),
      'Reversal' => (
          Icons.undo_rounded,
          DesignTokens.bgAppBodyLight,
          DesignTokens.textMuted,
        ),
      _ => (
          Icons.swap_horiz_rounded,
          DesignTokens.bgAppBodyLight,
          DesignTokens.textMuted,
        ),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Icon(icon, color: fg, size: 18),
    );
  }
}

// ── Transaction detail sheet ──────────────────────────────────────────────────

class _TransactionDetail extends StatelessWidget {
  const _TransactionDetail({required this.tx});

  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isDebit = tx.type == 'Debit';
    final isReversal = tx.type == 'Reversal';
    final amountColor = isReversal
        ? DesignTokens.textMuted
        : isDebit
            ? DesignTokens.colorError
            : DesignTokens.primaryGreen;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s24,
          DesignTokens.s16,
          DesignTokens.s24,
          DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            // Icon + amount hero
            _TxIcon(type: tx.type),
            const SizedBox(height: DesignTokens.s12),
            Text(
              _TransactionTile._label(tx),
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              _npr(tx.amount),
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: amountColor,
                decoration: isReversal
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            // Detail rows
            Container(
              decoration: DesignTokens.cardDecoration(
                backgroundColor: DesignTokens.bgAppBodyLight,
                hasShadow: false,
              ),
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                children: [
                  if (tx.description != null && tx.description!.isNotEmpty)
                    _DetailRow(
                      label: 'Description',
                      value: tx.description!,
                    ),
                  _DetailRow(label: 'Type', value: tx.type),
                  _DetailRow(label: 'Source', value: tx.source),
                  _DetailRow(
                    label: 'Balance after',
                    value: _npr(tx.balanceAfter),
                  ),
                  _DetailRow(
                    label: 'Date',
                    value: DateFormat('MMM d, yyyy · h:mm a')
                        .format(tx.occurredUtc.toLocal()),
                    isLast: tx.reversalOf == null &&
                        tx.correlationType != 'Order',
                  ),
                  if (tx.correlationType == 'Order' &&
                      tx.description != null)
                    _DetailRow(
                      label: 'Order',
                      value: tx.description!,
                      isLast: tx.reversalOf == null,
                    ),
                  if (tx.reversalOf != null)
                    _DetailRow(
                      label: 'Note',
                      value:
                          'This transaction reversed an earlier transaction.',
                      isLast: true,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: DesignTokens.smallRegular,
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            color: DesignTokens.borderDefault,
          ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            const Text(
              'No transactions yet',
              style: DesignTokens.mediumSemibold,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Your wallet activity will appear here once you make a purchase or receive a credit.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Utility widgets ───────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: DesignTokens.colorError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: DesignTokens.colorError,
                size: 32,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            const Text(
              'Failed to load wallet',
              style: DesignTokens.mediumSemibold,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              message,
              style: DesignTokens.smallRegular,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s24),
            ElevatedButton(
              onPressed: onRetry,
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
