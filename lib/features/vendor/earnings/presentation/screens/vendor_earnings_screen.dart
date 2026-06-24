import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/screens/statement_details_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorEarningsScreen extends StatelessWidget {
  const VendorEarningsScreen({super.key});

  static const _payouts = [
    _PayoutEntry(id: '1', label: 'Rs 12,500 Payout to Bank A/C', accountInfo: '********1268 · 12:35, Jan 20 2026', status: _Status.pending),
    _PayoutEntry(id: '2', label: 'Rs 17,000 Payout to Esewa Wallet', accountInfo: '********22 · 21:32, Jan 16 2026', status: _Status.completed),
    _PayoutEntry(id: '3', label: 'Rs 10,989.99 Payout to Bank A/C', accountInfo: '********4566 · 09:47, Jan 11 2026', status: _Status.failed),
  ];

  static const _methods = [
    _PaymentMethodEntry(label: 'Bank A/C', accountInfo: '********2349 · Chase Bank', isDefault: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Payouts & Earnings', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: DesignTokens.textWhite, size: 22),
            onPressed: () => context.push(RouteNames.vendorChangePaymentMethod),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
        children: [
          // ── Total Balance label ──────────────────────────────────────────────
          Text('Total Balance', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),

          // ── Balance card ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(children: [
              _BalanceRow(
                icon: Icons.savings_outlined,
                iconColor: DesignTokens.primaryGreen,
                iconBg: const Color(0xFF1A3A1A),
                label: 'Available Balance (In NPR)',
                amount: '6,12,589.98',
              ),
              const SizedBox(height: DesignTokens.s16),
              _BalanceRow(
                icon: Icons.hourglass_bottom_outlined,
                iconColor: const Color(0xFFFFB800),
                iconBg: const Color(0xFF2A2000),
                label: 'Pending Balance (In NPR)',
                amount: '4,56,781.52',
              ),
            ]),
          ),
          const SizedBox(height: DesignTokens.s12),

          // ── Next Payout banner ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800),
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A00),
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                ),
                child: const Icon(Icons.account_balance_outlined, color: Color(0xFFFFB800), size: 24),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(
                  'Next Payout: Fri Dec 20, 2024',
                  style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                const SizedBox(height: DesignTokens.s4),
                const Text(
                  'Payouts are processed automatically every Friday & transferred to your Chase Bank ******2349',
                  style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFF333300)),
                ),
              ])),
            ]),
          ),
          const SizedBox(height: DesignTokens.s16),

          // ── Stats row ────────────────────────────────────────────────────────
          Row(children: [
            _StatCard(icon: Icons.inventory_2_outlined, value: '234', label: 'Total Orders'),
            const SizedBox(width: DesignTokens.s8),
            _StatCard(icon: Icons.receipt_long_outlined, value: '12,456', label: 'Average\nOrder Value'),
            const SizedBox(width: DesignTokens.s8),
            _StatCard(icon: Icons.percent_outlined, value: '12%', label: 'Average\nCommission'),
          ]),
          const SizedBox(height: DesignTokens.s20),

          // ── Revenue Breakdown ─────────────────────────────────────────────────
          Text('Revenue Breakdown This Month', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(children: [
              _RevenueRow(icon: Icons.bar_chart_outlined, label: 'Gross Sales', value: 'Rs 12,56,678.98'),
              _RevenueRow(icon: Icons.percent_outlined, label: 'Platform Fee (5%)', value: '-Rs 62,456.00', valueColor: DesignTokens.colorError),
              _RevenueRow(icon: Icons.credit_card_outlined, label: 'Payment Processing', value: '-Rs 28,564.22', valueColor: DesignTokens.colorError),
              _RevenueRow(icon: Icons.people_outline, label: 'Creator Commissions', value: '-Rs 3,42,334.56', valueColor: DesignTokens.colorError),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.s12),
                child: _DashedDivider(),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Net Earnings', style: DesignTokens.mediumSemibold),
                Text('Rs 8,42,334.56', style: DesignTokens.mediumSemibold.copyWith(fontSize: 16)),
              ]),
            ]),
          ),
          const SizedBox(height: DesignTokens.s20),

          // ── Payout History ────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Payout History', style: DesignTokens.mediumSemibold),
            GestureDetector(
              onTap: () => context.push(RouteNames.vendorPayoutHistory),
              child: Row(children: [
                Text('View All', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen)),
                const Icon(Icons.arrow_forward_ios, color: DesignTokens.primaryGreen, size: 12),
              ]),
            ),
          ]),
          const SizedBox(height: DesignTokens.s12),

          // Date group header
          Row(children: [
            const Icon(Icons.calendar_today_outlined, color: DesignTokens.textMuted, size: 14),
            const SizedBox(width: DesignTokens.s6),
            Text('Nov 24-30, 2025 Period', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
          ]),
          const SizedBox(height: DesignTokens.s8),

          Container(
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: _payouts.asMap().entries.map((e) {
                final p = e.value;
                return Column(children: [
                  if (e.key > 0) const Divider(color: DesignTokens.borderDefault, height: 1),
                  _PayoutTile(
                    entry: p,
                    onTap: () => context.push(
                      RouteNames.vendorStatementDetails,
                      extra: VendorPayoutItem(id: p.id, title: p.label, subtitle: p.accountInfo),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
          const SizedBox(height: DesignTokens.s20),

          // ── Payment Methods ───────────────────────────────────────────────────
          Text('Payment Methods', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          Container(
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: _methods.map((m) => _PaymentMethodTile(
                method: m,
                onMenuTap: () => context.push(RouteNames.vendorChangePaymentMethod),
              )).toList(),
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
        ],
      ),
    );
  }
}

// ── Balance row ───────────────────────────────────────────────────────────────

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.icon, required this.iconColor, required this.iconBg, required this.label, required this.amount});
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(DesignTokens.inputRadius)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      const SizedBox(width: DesignTokens.s12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
        const SizedBox(height: 2),
        Text(amount, style: const TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 22, fontWeight: FontWeight.w700, color: DesignTokens.textWhite)),
      ]),
    ]);
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12, horizontal: DesignTokens.s8),
        decoration: DesignTokens.cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: DesignTokens.textMuted, size: 22),
          const SizedBox(height: DesignTokens.s8),
          Text(value, style: const TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: DesignTokens.textWhite)),
          const SizedBox(height: 2),
          Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Revenue row ───────────────────────────────────────────────────────────────

class _RevenueRow extends StatelessWidget {
  const _RevenueRow({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(children: [
        Icon(icon, color: DesignTokens.textMuted, size: 16),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 13))),
        Text(value, style: DesignTokens.smallRegular.copyWith(color: valueColor ?? DesignTokens.textWhite, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
      return Row(children: List.generate(count, (_) => Padding(
        padding: const EdgeInsets.only(right: dashSpace),
        child: Container(width: dashWidth, height: 1, color: DesignTokens.borderDefault),
      )));
    });
  }
}

// ── Payout tile ───────────────────────────────────────────────────────────────

class _PayoutTile extends StatelessWidget {
  const _PayoutTile({required this.entry, required this.onTap});
  final _PayoutEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: const Icon(Icons.payments_outlined, color: DesignTokens.textMuted, size: 20),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(entry.label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(entry.accountInfo, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11)),
            const SizedBox(height: DesignTokens.s6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: entry.status.bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(entry.status.label, style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: entry.status.textColor)),
            ),
          ])),
        ]),
      ),
    );
  }
}

// ── Payment method tile ───────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({required this.method, required this.onMenuTap});
  final _PaymentMethodEntry method;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          ),
          child: const Icon(Icons.account_balance_outlined, color: DesignTokens.textMuted, size: 20),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(method.label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
            if (method.isDefault) ...[
              const SizedBox(width: DesignTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2A3A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Default', style: DesignTokens.smallRegular.copyWith(color: const Color(0xFF4DA6FF), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(method.accountInfo, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
        ])),
        IconButton(
          icon: const Icon(Icons.more_vert, color: DesignTokens.textMuted, size: 20),
          onPressed: onMenuTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

enum _Status {
  pending, completed, failed;

  String get label {
    switch (this) {
      case pending: return 'Pending';
      case completed: return 'Completed';
      case failed: return 'Failed';
    }
  }

  Color get textColor {
    switch (this) {
      case pending: return const Color(0xFFB8860B);
      case completed: return const Color(0xFF1A5C1A);
      case failed: return const Color(0xFF8B1A1A);
    }
  }

  Color get bgColor {
    switch (this) {
      case pending: return const Color(0xFFFFD700);
      case completed: return const Color(0xFF90EE90);
      case failed: return const Color(0xFFFFB6C1);
    }
  }
}

class _PayoutEntry {
  const _PayoutEntry({required this.id, required this.label, required this.accountInfo, required this.status});
  final String id;
  final String label;
  final String accountInfo;
  final _Status status;
}

class _PaymentMethodEntry {
  const _PaymentMethodEntry({required this.label, required this.accountInfo, this.isDefault = false});
  final String label;
  final String accountInfo;
  final bool isDefault;
}
