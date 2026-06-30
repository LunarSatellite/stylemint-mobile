import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ActivePartnershipsScreen extends StatefulWidget {
  const ActivePartnershipsScreen({super.key});

  @override
  State<ActivePartnershipsScreen> createState() =>
      _ActivePartnershipsScreenState();
}

class _ActivePartnershipsScreenState extends State<ActivePartnershipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Active Partnerhips',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.primaryGreen,
          indicatorWeight: 2,
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [Tab(text: 'Active'), Tab(text: 'Ended')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ActiveTab(),
          _EndedTab(),
        ],
      ),
    );
  }
}

// ── Active tab ────────────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterSortRow(
          onFilter: () => _showFilterSheet(context),
          onSort: () => _showSortSheet(context),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s32,
            ),
            children: const [
              _PartnershipCard(
                logo: _NikeLogo(),
                name: 'Nike Official Store',
                productsTagged: 46,
                commissionPct: 18,
                startDate: '7 Aug, 2025',
                totalEarnings: 'Rs 64,909.23',
                activeCampaigns: 4,
              ),
              SizedBox(height: DesignTokens.s12),
              _PartnershipCard(
                logo: _UltimaLogo(),
                name: 'Ultima Lifestyle',
                productsTagged: 27,
                commissionPct: 20,
                startDate: '22 Nov, 2025',
                totalEarnings: 'Rs 1,23,342.98',
                activeCampaigns: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Ended tab ─────────────────────────────────────────────────────────────────

class _EndedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_outlined, size: 48, color: DesignTokens.textMuted),
          SizedBox(height: DesignTokens.s12),
          Text(
            'No ended partnerships.',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter / Sort row ─────────────────────────────────────────────────────────

class _FilterSortRow extends StatelessWidget {
  const _FilterSortRow({required this.onFilter, required this.onSort});
  final VoidCallback onFilter;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      child: Row(
        children: [
          _PillButton(
            icon: Icons.tune_rounded,
            label: 'Filter',
            onTap: onFilter,
          ),
          const SizedBox(width: DesignTokens.s8),
          _PillButton(
            icon: Icons.keyboard_arrow_down_rounded,
            label: 'Sort By',
            iconTrailing: true,
            onTap: onSort,
          ),
        ],
      ),
    );
  }
}

void _showFilterSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _FilterSheetContent(),
  );
}

void _showSortSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SortSheetContent(),
  );
}

// ── Sort bottom sheet ─────────────────────────────────────────────────────────

class _SortSheetContent extends StatefulWidget {
  const _SortSheetContent();

  @override
  State<_SortSheetContent> createState() => _SortSheetContentState();
}

class _SortSheetContentState extends State<_SortSheetContent> {
  int _selected = 0;

  static const _options = [
    'Newest First',
    'Oldest First',
    'Highest Earnings',
    'Lowest Earnings',
    'Name (A–Z)',
    'Name (Z–A)',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sort By',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textLight,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          ...List.generate(_options.length, (i) {
            final selected = _selected == i;
            return InkWell(
              onTap: () => setState(() => _selected = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _options[i],
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? DesignTokens.textWhite
                              : DesignTokens.textLight,
                        ),
                      ),
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? DesignTokens.primaryGreen
                              : DesignTokens.borderDefault,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: DesignTokens.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: DesignTokens.s8),
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = 0),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconTrailing = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 15, color: DesignTokens.textLight);
    final labelWidget = Text(
      label,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: DesignTokens.textLight,
      ),
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: iconTrailing
              ? [labelWidget, const SizedBox(width: 4), iconWidget]
              : [iconWidget, const SizedBox(width: 6), labelWidget],
        ),
      ),
    );
  }
}

// ── Partnership card ──────────────────────────────────────────────────────────

class _PartnershipCard extends StatelessWidget {
  const _PartnershipCard({
    required this.logo,
    required this.name,
    required this.productsTagged,
    required this.commissionPct,
    required this.startDate,
    required this.totalEarnings,
    required this.activeCampaigns,
  });

  final Widget logo;
  final String name;
  final int productsTagged;
  final int commissionPct;
  final String startDate;
  final String totalEarnings;
  final int activeCampaigns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand header
          Row(
            children: [
              SizedBox(width: 44, height: 44, child: logo),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.sell_outlined,
                          size: 13,
                          color: DesignTokens.textMuted,
                        ),
                        const SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 12,
                              color: DesignTokens.textMuted,
                            ),
                            children: [
                              TextSpan(
                                text: '$productsTagged',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.textWhite,
                                ),
                              ),
                              const TextSpan(text: ' Products tagged'),
                              TextSpan(
                                text: ' • $commissionPct% commissions',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Message',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
                decoration: TextDecoration.underline,
                decorationColor: DesignTokens.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          const _DashedDivider(),
          const SizedBox(height: DesignTokens.s12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Start Date',
            trailingText: startDate,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.monetization_on_outlined,
            label: 'Total Earnings',
            trailing: _EarningsChip(totalEarnings),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.campaign_outlined,
            label: 'Active Campaigns',
            trailingText: '$activeCampaigns',
          ),
          const SizedBox(height: DesignTokens.s16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'End Partnership',
                  filled: false,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _ActionButton(
                  label: 'View Analytics',
                  filled: true,
                  onTap: () => context.push(RouteNames.creatorAnalytics),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: DesignTokens.textMuted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textLight,
          ),
        ),
        const Spacer(),
        if (trailingText != null)
          Text(
            trailingText!,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _EarningsChip extends StatelessWidget {
  const _EarningsChip(this.amount);
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreenLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        amount,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: filled ? DesignTokens.primaryGreen : DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: filled ? Colors.white : DesignTokens.textLight,
          ),
        ),
      ),
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedPainter()),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 1;
    double x = 0;
    const dash = 6.0;
    const gap = 4.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheetContent extends StatefulWidget {
  const _FilterSheetContent();

  @override
  State<_FilterSheetContent> createState() => _FilterSheetContentState();
}

class _FilterSheetContentState extends State<_FilterSheetContent> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  int _selectedStatus = -1;

  static const _statusOptions = [
    'Newest',
    'Highest Earnings',
    'Lowest Earnings',
    'Name',
  ];

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filter Partnership',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textLight,
                    size: 22,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          // Commission Range
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Commission Range',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _RangeField(
                    controller: _fromCtrl,
                    hint: 'From',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '—',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: _RangeField(
                    controller: _toCtrl,
                    hint: 'To',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          // Status
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Status',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          ...List.generate(_statusOptions.length, (i) {
            final selected = _selectedStatus == i;
            return InkWell(
              onTap: () => setState(() => _selectedStatus = i),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? DesignTokens.primaryGreen
                              : DesignTokens.borderDefault,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Center(
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: DesignTokens.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Text(
                      _statusOptions[i],
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? DesignTokens.textWhite
                            : DesignTokens.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: DesignTokens.s16),
          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _fromCtrl.clear();
                        _toCtrl.clear();
                        _selectedStatus = -1;
                      });
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Apply',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
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

class _RangeField extends StatelessWidget {
  const _RangeField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        color: DesignTokens.textWhite,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          color: DesignTokens.textMuted,
        ),
        filled: true,
        fillColor: DesignTokens.bgAppBodyLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DesignTokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DesignTokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: DesignTokens.primaryGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Logo widgets ──────────────────────────────────────────────────────────────

class _NikeLogo extends StatelessWidget {
  const _NikeLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '✓',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _UltimaLogo extends StatelessWidget {
  const _UltimaLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        shape: BoxShape.circle,
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: const Center(
        child: Text(
          'ULTIM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 7,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
