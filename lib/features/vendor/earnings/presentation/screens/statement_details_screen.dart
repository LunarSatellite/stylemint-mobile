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
    _OrderLine(
      name: 'Nike Air Jordan Travis Scott',
      qty: 1,
      price: 'Rs 4,001.00',
    ),
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Statement Details', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.download_outlined,
              color: DesignTokens.textWhite,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receipt card with scalloped bottom
            ClipPath(
              clipper: _ScallopedBottomClipper(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s28,
                ),
                decoration: DesignTokens.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A3A1A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: DesignTokens.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ReelCommerce Receipt',
                                style: DesignTokens.smallRegular.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: DesignTokens.textWhite,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'December 18, 2024',
                                style: DesignTokens.smallRegular.copyWith(
                                  color: DesignTokens.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    const Divider(color: DesignTokens.borderDefault, height: 1),
                    const SizedBox(height: DesignTokens.s12),

                    // Detail rows
                    _DetailRow(label: 'Receipt No.', value: 'INV-2024-8912'),
                    _DetailRow(label: 'Date', value: 'December 18, 2024'),
                    _DetailRow(label: 'Payout to Bank', value: 'Chase Bank'),
                    _DetailRow(label: 'Payout to', value: '********1268'),
                    _DetailRow(label: 'TXN', value: 'TXN-292-2039843'),
                    // Payment Status with green badge
                    Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Status',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D2A0D),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: DesignTokens.primaryGreen,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Completed',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.s4),
                    const Divider(color: DesignTokens.borderDefault, height: 1),
                    const SizedBox(height: DesignTokens.s12),

                    // Breakdown
                    _AmountRow(label: 'Sub Total', value: 'Rs 18,000'),
                    _AmountRow(
                      label: 'Processing Fee (2%)',
                      value: '-500',
                      valueColor: DesignTokens.colorError,
                    ),
                    _AmountRow(
                      label: 'Platform Fee (2%)',
                      value: '-500',
                      valueColor: DesignTokens.colorError,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    const Divider(color: DesignTokens.borderDefault, height: 1),
                    const SizedBox(height: DesignTokens.s12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Payout',
                          style: DesignTokens.mediumSemibold.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Rs 17,000',
                          style: DesignTokens.mediumSemibold.copyWith(
                            fontSize: 18,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: DesignTokens.borderDefault),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(
                  Icons.download_outlined,
                  color: DesignTokens.textWhite,
                  size: 18,
                ),
                label: Text(
                  'Download Receipt',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
          ],
        ),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: DesignTokens.s16),
          Flexible(
            child: Text(
              value,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: bold ? DesignTokens.textWhite : DesignTokens.textMuted,
              fontSize: 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: DesignTokens.smallRegular.copyWith(
              color: valueColor ?? DesignTokens.textWhite,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLine {
  const _OrderLine({
    required this.name,
    required this.qty,
    required this.price,
  });
  final String name;
  final int qty;
  final String price;
}

class _ScallopedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 10.0;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - r);
    double x = size.width;
    while (x > 0) {
      path.arcToPoint(
        Offset(x - r * 2, size.height - r),
        radius: const Radius.circular(r),
        clockwise: true,
      );
      x -= r * 2;
    }
    path.lineTo(0, size.height - r);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
