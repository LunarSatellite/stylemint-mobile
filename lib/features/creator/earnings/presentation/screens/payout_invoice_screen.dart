import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Shared types ──────────────────────────────────────────────────────────────

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
  const PayoutInvoiceArgs({required this.entry});
  final PayoutHistoryEntry entry;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtAmount(double v) =>
    'Rs ${NumberFormat('#,##0.##', 'en_US').format(v)}';

// ── PayoutInvoiceScreen ───────────────────────────────────────────────────────

class PayoutInvoiceScreen extends StatelessWidget {
  const PayoutInvoiceScreen({super.key, required this.args});

  final PayoutInvoiceArgs args;

  @override
  Widget build(BuildContext context) {
    final entry = args.entry;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Invoice', style: DesignTokens.sectionInnerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined,
                color: DesignTokens.textWhite),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Downloading invoices is coming soon.'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined,
                color: DesignTokens.textWhite),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Printing invoices is coming soon.'),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: _ReceiptCard(entry: entry),
      ),
    );
  }
}

// ── Receipt card with scalloped bottom ───────────────────────────────────────

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
              _ReceiptRow(
                label: 'Receipt No.',
                value: entry.receiptNo,
              ),
              _ReceiptRow(
                label: 'Date',
                value: DateFormat('MMM d, yyyy').format(entry.dateTime),
              ),
              _ReceiptRow(
                label: 'Payout to',
                value: entry.payoutTo,
              ),
              _ReceiptRow(
                label: 'TXN',
                value: entry.txnId,
              ),
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
                    'Processing Fee (${entry.processingFeePercent.toStringAsFixed(0)}%)',
                value: '-${_fmtAmount(entry.processingFee)}',
                valueColor: const Color(0xFFEF4444),
              ),
              const SizedBox(height: DesignTokens.s12),
              _DashedDivider(),
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
        // Scalloped punch-holes at the bottom
        Positioned(
          bottom: -9,
          left: 0,
          right: 0,
          child: _ScallopRow(),
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
          child: const Icon(Icons.shopping_bag_outlined,
              size: 28, color: DesignTokens.primaryGreen),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ReelCommerce Receipt',
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
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight),
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
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(width: DesignTokens.s16),
          Flexible(
            child: valueBadge ??
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
          horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
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
          height: 1.0,
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
        final count =
            (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          children: List.generate(count, (_) {
            return Padding(
              padding: const EdgeInsets.only(right: dashGap),
              child: Container(
                width: dashWidth,
                height: dashHeight,
                color: DesignTokens.borderDefault,
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
        // Overlap the card edges by half a circle so cut-outs look punched
        final totalWidth = constraints.maxWidth;
        const count = 14;
        final spacing = (totalWidth - circleSize) / (count - 1);
        return SizedBox(
          height: circleSize,
          child: Stack(
            children: List.generate(count, (i) {
              return Positioned(
                left: i * spacing,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: DesignTokens.bgAppFoundation,
                    shape: BoxShape.circle,
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
