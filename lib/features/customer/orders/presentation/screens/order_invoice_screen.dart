import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderInvoiceScreen extends ConsumerWidget {
  const OrderInvoiceScreen({required this.order, super.key});

  final OrderDetail order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(orderInvoiceProvider(order.orderNumber));
    return invoice.when(
      loading: () => const _InvoiceLoading(),
      error: (_, __) => _InvoiceError(
        onRetry: () => ref.invalidate(orderInvoiceProvider(order.orderNumber)),
      ),
      data: (value) => _AuthoritativeInvoice(invoice: value),
    );
  }
}

class _AuthoritativeInvoice extends StatelessWidget {
  const _AuthoritativeInvoice({required this.invoice});

  final OrderInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final invoiceNum = invoice.invoiceNumber;
    final dateStr = DateFormat('MMMM dd, yyyy').format(invoice.placedAt);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Invoice', style: DesignTokens.sectionInnerTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: DesignTokens.textWhite,
              size: 22,
            ),
            tooltip: 'Share invoice',
            onPressed: () => _shareOrderInvoice(invoice),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DesignTokens.cardDecoration(),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/OrderImage.svg',
                  width: 44,
                  height: 44,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'StyleMint Invoice',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Invoice fields ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: [
                _InvRow(label: 'Invoice No.', value: invoiceNum),
                _InvRow(label: 'Order No.', value: invoice.orderNumber),
                _InvRow(label: 'Date', value: dateStr),
                _InvRow(label: 'Payment', value: invoice.paymentMethod),
                _InvRow(label: 'Payment Status', value: invoice.paymentStatus),
                _InvRow(
                  label: 'Shipping Address',
                  value: invoice.shippingAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Order Summary ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 12),

                // Table header row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 5,
                        child: Text(
                          'Items',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      for (final h in ['Qty.', 'Rate', 'Amt.'])
                        SizedBox(
                          width: 52,
                          child: Text(
                            h,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.textWhite,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Item rows
                for (final item in invoice.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            [
                              item.productTitle,
                              if (item.variantLabel?.isNotEmpty == true)
                                item.variantLabel!,
                            ].join('\n'),
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.end,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            item.unitPrice.amount.toStringAsFixed(0),
                            textAlign: TextAlign.end,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            item.lineSubtotal.amount.toStringAsFixed(0),
                            textAlign: TextAlign.end,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(color: DesignTokens.borderDefault, height: 20),

                // Subtotals
                _TotalRow(
                  label: 'Sub Total',
                  value: formatMoney(invoice.subtotal),
                ),
                const SizedBox(height: 8),
                _TotalRow(
                  label: 'Shipping',
                  value: invoice.shipping.amount == 0
                      ? 'FREE'
                      : formatMoney(invoice.shipping),
                ),
                if (invoice.tax.amount > 0) ...[
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'Tax',
                    value: formatMoney(invoice.tax),
                  ),
                ],

                const Divider(color: DesignTokens.borderDefault, height: 20),

                // Grand Total
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(invoice.total),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Save Invoice button ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _shareOrderInvoice(invoice),
              icon: const Icon(
                Icons.share_outlined,
                size: 18,
                color: Colors.black,
              ),
              label: const Text(
                'Share Invoice',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _shareOrderInvoice(OrderInvoice invoice) {
  final lines = <String>[
    'Style Mint invoice ${invoice.invoiceNumber}',
    'Order: ${invoice.orderNumber}',
    'Placed: ${DateFormat.yMMMd().add_jm().format(invoice.placedAt)}',
    'Payment: ${invoice.paymentMethod} (${invoice.paymentStatus})',
    'Subtotal: ${formatMoney(invoice.subtotal)}',
    'Shipping: ${formatMoney(invoice.shipping)}',
    if (invoice.tax.amount > 0) 'Tax: ${formatMoney(invoice.tax)}',
    'Grand total: ${formatMoney(invoice.total)}',
  ];
  unawaited(SharePlus.instance.share(ShareParams(text: lines.join('\n'))));
}

class _InvoiceLoading extends StatelessWidget {
  const _InvoiceLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    body: Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    ),
  );
}

class _InvoiceError extends StatelessWidget {
  const _InvoiceError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(backgroundColor: DesignTokens.bgAppFoundation),
    body: Center(
      child: ElevatedButton(
        onPressed: onRetry,
        style: DesignTokens.primaryButtonStyle(),
        child: const Text('Retry'),
      ),
    ),
  );
}

// ── Invoice field row ─────────────────────────────────────────────────────────

class _InvRow extends StatelessWidget {
  const _InvRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Totals row ────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}
