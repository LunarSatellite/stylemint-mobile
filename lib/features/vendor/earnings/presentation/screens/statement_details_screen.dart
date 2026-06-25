import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorPayoutItem {
  const VendorPayoutItem({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  final String id;
  final String title;
  final String subtitle;
}

class StatementDetailsScreen extends StatelessWidget {
  const StatementDetailsScreen({required this.item, super.key});

  final VendorPayoutItem item;

  static const _orderItems = [
    _OrderLine(name: 'Nike Air Max 2025', qty: 1, price: 'Rs 8,499.00'),
    _OrderLine(name: 'Nike Air Jordan Travis Scott', qty: 1, price: 'Rs 4,001.00'),
  ];

  @override
  Widget build(BuildContext context) {
    final title = item.title.isEmpty ? 'Statement Details' : item.title;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Statement Details', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: DesignTokens.textWhite, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Receipt card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Receipt header
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2137),
                    borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF4DA6FF), size: 20),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('EasyCommerce Receipt', style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(title, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A0D),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Completed', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen, fontWeight: FontWeight.w600, fontSize: 11)),
                ),
              ]),
              const SizedBox(height: DesignTokens.s16),
              const Divider(color: DesignTokens.borderDefault, height: 1),
              const SizedBox(height: DesignTokens.s16),

              // Order info
              _DetailRow(label: 'Order Number', value: '#NK2024-8912'),
              _DetailRow(label: 'Payout ID', value: '#PO-${item.id.padLeft(6, '0')}'),
              _DetailRow(label: 'Payment Method', value: item.subtitle.isEmpty ? 'Bank of Kathmandu A/C ******8799' : item.subtitle),
              _DetailRow(label: 'Date', value: 'Jan 23, 2024'),
              const SizedBox(height: DesignTokens.s16),
              const Divider(color: DesignTokens.borderDefault, height: 1),
              const SizedBox(height: DesignTokens.s16),

              // Order items
              Text('Order Items', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
              const SizedBox(height: DesignTokens.s8),
              ..._orderItems.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text('${line.name} x${line.qty}', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontSize: 12))),
                  Text(line.price, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600, fontSize: 12)),
                ]),
              )),
              const SizedBox(height: DesignTokens.s8),
              const Divider(color: DesignTokens.borderDefault, height: 1),
              const SizedBox(height: DesignTokens.s12),

              // Breakdown
              _AmountRow(label: 'Subtotal', value: 'Rs 12,500.00'),
              _AmountRow(label: 'Platform Fee (3%)', value: '- Rs 375.00', valueColor: DesignTokens.colorError),
              _AmountRow(label: 'Creator Commission (10%)', value: '- Rs 1,250.00', valueColor: DesignTokens.colorError),
              const SizedBox(height: DesignTokens.s8),
              const Divider(color: DesignTokens.borderDefault, height: 1),
              const SizedBox(height: DesignTokens.s8),
              _AmountRow(label: 'Net Payout', value: 'Rs 10,875.00', valueColor: DesignTokens.primaryGreen, bold: true),
            ]),
          ),
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DesignTokens.borderDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.download_outlined, color: DesignTokens.textWhite, size: 18),
              label: Text('Download Receipt', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
        const SizedBox(width: DesignTokens.s16),
        Flexible(child: Text(value, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.valueColor, this.bold = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: DesignTokens.smallRegular.copyWith(color: bold ? DesignTokens.textWhite : DesignTokens.textMuted, fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
        Text(value, style: DesignTokens.smallRegular.copyWith(color: valueColor ?? DesignTokens.textWhite, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}

class _OrderLine {
  const _OrderLine({required this.name, required this.qty, required this.price});
  final String name;
  final int qty;
  final String price;
}
