import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Shared display types ───────────────────────────────────────────────────────

enum PayoutStatus { pending, completed, failed }

class PayoutHistoryEntry {
  const PayoutHistoryEntry({
    required this.id,
    required this.title,
    required this.accountMask,
    required this.dateTime,
    required this.status,
    required this.subTotalAmount,
    required this.receiptNo,
    required this.txnId,
    required this.payoutTo,
    this.processingFeePercent = 2.0,
  });

  final String id;
  final String title;
  final String accountMask;
  final String receiptNo;
  final String txnId;
  final String payoutTo;
  final DateTime dateTime;
  final PayoutStatus status;
  final double subTotalAmount;
  final double processingFeePercent;

  double get processingFee =>
      (subTotalAmount * processingFeePercent / 100).roundToDouble();
  double get netPayout => subTotalAmount - processingFee;
}

class PayoutInvoiceArgs {
  const PayoutInvoiceArgs({required this.payoutId});
  final String payoutId;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtAmount(double v) =>
    'Rs ${NumberFormat('#,##0.##', 'en_US').format(v)}';

void _shareInvoice(PayoutInvoice invoice) {
  final invoiceNumber = invoice.invoiceNumber.isEmpty
      ? invoice.payoutId
      : invoice.invoiceNumber;
  final paidOrRequested = invoice.paidAt ?? invoice.requestedAt;
  final lines = <String>[
    'Style Mint payout invoice $invoiceNumber',
    'Status: ${invoice.state.name}',
    'Requested: ${DateFormat.yMMMd().add_jm().format(paidOrRequested)}',
    'Destination: ${invoice.destinationLabel}'
        '${invoice.destinationRef == null ? '' : ' (${invoice.destinationRef})'}',
    'Gross: ${_fmtAmount(invoice.grossAmount.amount)}',
    'Fee: ${_fmtAmount(invoice.feeAmount.amount)}',
    'Net payout: ${_fmtAmount(invoice.netAmount.amount)}',
  ];
  if (invoice.providerPayoutId?.isNotEmpty == true) {
    lines.add('Provider reference: ${invoice.providerPayoutId}');
  }

  unawaited(
    SharePlus.instance.share(ShareParams(text: lines.join('\n'))),
  );
}

PayoutHistoryEntry _invoiceToEntry(PayoutInvoice invoice) {
  final feePercent = invoice.grossAmount.amount > 0
      ? (invoice.feeAmount.amount / invoice.grossAmount.amount * 100)
      : 0.0;
  final status = switch (invoice.state) {
    PayoutState.paid => PayoutStatus.completed,
    PayoutState.failed => PayoutStatus.failed,
    _ => PayoutStatus.pending,
  };
  final receiptNo = invoice.invoiceNumber.isNotEmpty
      ? invoice.invoiceNumber
      : invoice.payoutId.substring(0, 8).toUpperCase();
  final txnId =
      invoice.providerPayoutId ??
      invoice.payoutId.substring(0, 8).toUpperCase();
  return PayoutHistoryEntry(
    id: invoice.payoutId,
    title:
        '${_fmtAmount(invoice.grossAmount.amount)} Payout'
        ' to ${invoice.destinationLabel}',
    accountMask: invoice.destinationRef ?? '',
    dateTime: invoice.paidAt ?? invoice.requestedAt,
    status: status,
    subTotalAmount: invoice.grossAmount.amount,
    processingFeePercent: feePercent,
    receiptNo: receiptNo,
    txnId: txnId,
    payoutTo: invoice.destinationRef != null
        ? '${invoice.destinationLabel} — ${invoice.destinationRef}'
        : invoice.destinationLabel,
  );
}

// ── PayoutInvoiceScreen ───────────────────────────────────────────────────────

class PayoutInvoiceScreen extends ConsumerWidget {
  const PayoutInvoiceScreen({required this.args, super.key});

  final PayoutInvoiceArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceState = ref.watch(
      payoutInvoiceNotifierProvider(args.payoutId),
    );
    final invoice = invoiceState.maybeWhen(
      loadSuccess: (value) => value,
      orElse: () => null,
    );
    final cancelState = ref.watch(cancelPayoutNotifierProvider);

    ref.listen<CancelPayoutState>(cancelPayoutNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ref.invalidate(payoutHistoryProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payout cancelled.')),
          );
          unawaited(Navigator.of(context).maybePop());
        },
        failure: (NetworkExceptions f) =>
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(NetworkExceptions.getMessage(f))),
            ),
        orElse: () {},
      );
    });

    final isCancelling = cancelState.maybeWhen(
      inProgress: () => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Invoice', style: DesignTokens.sectionInnerTitle),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: DesignTokens.textWhite,
            ),
            tooltip: 'Share invoice',
            onPressed: invoice == null ? null : () => _shareInvoice(invoice),
          ),
          IconButton(
            icon: const Icon(
              Icons.print_outlined,
              color: DesignTokens.textWhite,
            ),
            tooltip: 'Printing is unavailable on this device',
            onPressed: null,
          ),
        ],
      ),
      body: invoiceState.when(
        initial: () => const _Loader(),
        loadInProgress: () => const _Loader(),
        loadSuccess: (PayoutInvoice invoice) => _InvoiceBody(
          invoice: invoice,
          isCancelling: isCancelling,
          onCancel: () => _showCancelSheet(context, ref, invoice.payoutId),
        ),
        loadFailure: (NetworkExceptions failure) => _ErrorView(
          message: NetworkExceptions.getMessage(failure),
          onRetry: () => ref
              .read(
                payoutInvoiceNotifierProvider(args.payoutId).notifier,
              )
              .load(),
        ),
      ),
    );
  }

  void _showCancelSheet(
    BuildContext context,
    WidgetRef ref,
    String payoutId,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: DesignTokens.bgAppBody,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.cardRadius),
          ),
        ),
        builder: (_) => _CancelConfirmSheet(
          onConfirm: () {
            Navigator.of(context).pop();
            unawaited(
              ref.read(cancelPayoutNotifierProvider.notifier).cancel(payoutId),
            );
          },
        ),
      ),
    );
  }
}

// ── Invoice body ──────────────────────────────────────────────────────────

class _InvoiceBody extends StatelessWidget {
  const _InvoiceBody({
    required this.invoice,
    required this.isCancelling,
    required this.onCancel,
  });

  final PayoutInvoice invoice;
  final bool isCancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final entry = _invoiceToEntry(invoice);
    final canCancel = invoice.state == PayoutState.requested;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: _ReceiptCard(entry: entry),
          ),
        ),
        if (canCancel)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                0,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: OutlinedButton(
                  onPressed: isCancelling ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.colorError,
                    side: const BorderSide(color: DesignTokens.colorError),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.buttonRadius,
                      ),
                    ),
                  ),
                  child: isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: DesignTokens.colorError,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Cancel Payout'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Cancel confirm sheet ──────────────────────────────────────────────────

class _CancelConfirmSheet extends StatelessWidget {
  const _CancelConfirmSheet({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cancel this payout?',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              'The requested amount will be returned to your available '
              'balance. This action cannot be undone once processing begins.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.textWhite,
                      side: const BorderSide(color: DesignTokens.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.s12,
                      ),
                    ),
                    child: const Text('Keep'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.colorError,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: DesignTokens.s12,
                      ),
                    ),
                    child: const Text('Cancel Payout'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
  }
}

// ── Loader / Error ─────────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            ElevatedButton(
              onPressed: onRetry,
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Receipt card with scalloped bottom ───────────────────────────────────

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.entry});

  final PayoutHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s20,
            DesignTokens.s16,
            DesignTokens.s28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReceiptHeader(entry: entry),
              const SizedBox(height: DesignTokens.s20),
              _ReceiptRow(label: 'Receipt No.', value: entry.receiptNo),
              _ReceiptRow(
                label: 'Date',
                value: DateFormat('MMM d, yyyy').format(entry.dateTime),
              ),
              _ReceiptRow(label: 'Payout to', value: entry.payoutTo),
              _ReceiptRow(label: 'TXN', value: entry.txnId),
              _ReceiptRow(
                label: 'Payment Status',
                value: '',
                valueBadge: _StatusBadge(status: entry.status),
              ),
              const SizedBox(height: DesignTokens.s8),
              _ReceiptRow(
                label: 'Sub Total',
                value: _fmtAmount(entry.subTotalAmount),
              ),
              _ReceiptRow(
                label:
                    'Processing Fee '
                    '(${entry.processingFeePercent.toStringAsFixed(0)}%)',
                value: '-${_fmtAmount(entry.processingFee)}',
                valueColor: const Color(0xFFEF4444),
              ),
              const SizedBox(height: DesignTokens.s12),
              const _DashedDivider(),
              const SizedBox(height: DesignTokens.s12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Payout',
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                  Text(
                    _fmtAmount(entry.netPayout),
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -9,
          left: 0,
          right: 0,
          child: const _ScallopRow(),
        ),
      ],
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.entry});

  final PayoutHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreenDark,
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.shopping_bag_outlined,
            size: 28,
            color: DesignTokens.primaryGreen,
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'StyleMint Receipt',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                DateFormat('MMM d, yyyy · HH:mm').format(entry.dateTime),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueBadge,
    this.valueColor,
  });

  final String label;
  final String value;
  final Widget? valueBadge;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(width: DesignTokens.s16),
          Flexible(
            child:
                valueBadge ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: DesignTokens.smallRegular.copyWith(
                    color: valueColor ?? DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PayoutStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      PayoutStatus.completed => (
        const Color(0xFFB9F8CF),
        const Color(0xFF016630),
        'Completed',
      ),
      PayoutStatus.pending => (
        const Color(0xFFFFF3CD),
        const Color(0xFF856404),
        'Pending',
      ),
      PayoutStatus.failed => (
        const Color(0xFFFFE0E0),
        const Color(0xFFB91C1C),
        'Failed',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1,
          color: fg,
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashGap = 4.0;
        const dashHeight = 1.0;
        final count = (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          children: List.generate(count, (_) {
            return const Padding(
              padding: EdgeInsets.only(right: dashGap),
              child: SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: ColoredBox(color: DesignTokens.borderDefault),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ScallopRow extends StatelessWidget {
  const _ScallopRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const circleSize = 18.0;
        final totalWidth = constraints.maxWidth;
        const count = 14;
        final spacing = (totalWidth - circleSize) / (count - 1);
        return SizedBox(
          height: circleSize,
          child: Stack(
            children: List.generate(count, (i) {
              return Positioned(
                left: i * spacing,
                child: const SizedBox(
                  width: circleSize,
                  height: circleSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppFoundation,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
