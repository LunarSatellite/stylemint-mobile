import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderInvoiceScreen extends StatelessWidget {
  const OrderInvoiceScreen({required this.order, super.key});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final invoiceNum = 'INV-${order.orderNumber}';
    final txn = 'TXN-${order.orderNumber}-2024';
    final dateStr = DateFormat('MMMM dd, yyyy').format(order.placedAt);
    final rawDiscount = order.subtotal.amount +
        order.shipping.amount +
        order.tax.amount -
        order.total.amount;
    final hasDiscount = rawDiscount > 0.0;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Invoice', style: DesignTokens.sectionInnerTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined,
                color: DesignTokens.textWhite, size: 22),
            onPressed: () => SmSnackbar.info(context, 'Print not available yet.'),
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
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textMuted),
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
                _InvRow(label: 'Order No.', value: order.orderNumber),
                _InvRow(label: 'Date', value: dateStr),
                _InvRow(label: 'Payment', value: order.paymentMethod),
                _InvRow(label: 'TXN', value: txn),
                const _InvRow(label: 'Payment Status', value: 'Paid'),
                _InvRow(
                    label: 'Shipping Address', value: order.shippingAddress),
                const _InvRow(
                    label: 'Vendor', value: 'StyleMint Official Store'),
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
                      horizontal: 8, vertical: 8),
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
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            item.productName,
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textLight),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${item.qty}',
                            textAlign: TextAlign.end,
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textLight),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            item.unitPrice.amount.toStringAsFixed(0),
                            textAlign: TextAlign.end,
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textLight),
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            (item.qty * item.unitPrice.amount)
                                .toStringAsFixed(0),
                            textAlign: TextAlign.end,
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textLight),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(color: DesignTokens.borderDefault, height: 20),

                // Subtotals
                _TotalRow(
                    label: 'Sub Total',
                    value: formatMoney(order.subtotal)),
                const SizedBox(height: 8),
                _TotalRow(
                  label: 'Shipping',
                  value: order.shipping.amount == 0
                      ? 'FREE'
                      : formatMoney(order.shipping),
                ),
                const SizedBox(height: 8),
                _TotalRow(
                    label: 'Tax (Estimated 13%)',
                    value: formatMoney(order.tax)),
                if (hasDiscount) ...[
                  const SizedBox(height: 8),
                  _TotalRow(
                    label: 'Promo Code Discount',
                    value: '-${formatMoney(Money(amount: rawDiscount, currency: order.total.currency))}',
                    valueColor: DesignTokens.colorError,
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
                      formatMoney(order.total),
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
              onPressed: () =>
                  SmSnackbar.success(context, 'Invoice saved to your downloads.'),
              icon: const Icon(Icons.download_outlined,
                  size: 18, color: Colors.black),
              label: const Text(
                'Save Invoice',
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
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Totals row ────────────────────────────────────────────────────────────────

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textMuted)),
        const Spacer(),
        Text(value,
            style: DesignTokens.smallRegular.copyWith(
                color: valueColor ?? DesignTokens.textLight)),
      ],
    );
  }
}
