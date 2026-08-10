import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_messaging_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ActivePartnershipsScreen extends ConsumerStatefulWidget {
  const ActivePartnershipsScreen({super.key});

  @override
  ConsumerState<ActivePartnershipsScreen> createState() =>
      _ActivePartnershipsScreenState();
}

class _ActivePartnershipsScreenState
    extends ConsumerState<ActivePartnershipsScreen>
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
          'Active Partnerships',
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
          _ActiveTab(state: ref.watch(partnershipsNotifierProvider)),
          _EndedTab(state: ref.watch(partnershipsNotifierProvider)),
        ],
      ),
    );
  }
}

// ── Active tab ────────────────────────────────────────────────────────────────

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.state});

  final PartnershipsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FilterSortRow(
          onFilter: () => _showFilterSheet(context),
          onSort: () => _showSortSheet(context),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (_, active, _) => active.isEmpty
          ? const _EmptyPartnerships()
          : RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: () async {},
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s12,
                  DesignTokens.s16,
                  DesignTokens.s32,
                ),
                itemCount: active.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, i) => _PartnershipCard(
                  partnershipId: active[i].id,
                  vendorProfileId: active[i].vendorProfileId,
                  vendorAccountId: active[i].vendorAccountId,
                  logo: _VendorAvatar(
                    url: active[i].vendorLogoUrl,
                    name: active[i].vendorName,
                  ),
                  name: active[i].vendorName.isNotEmpty
                      ? active[i].vendorName
                      : 'Brand',
                  productsTagged: active[i].productsCount,
                  commissionPct: active[i].commissionRate.round(),
                  startDate: DateFormat('d MMM, yyyy').format(
                    active[i].startedAt,
                  ),
                  totalEarnings: formatMoney(active[i].totalEarned),
                  activeCampaigns: 0,
                ),
              ),
            ),
      loadFailure: (f) => _ErrorBody(
        message: NetworkExceptions.getMessage(f),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _EmptyPartnerships extends StatelessWidget {
  const _EmptyPartnerships();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_outlined,
              size: 48, color: DesignTokens.textMuted),
          SizedBox(height: DesignTokens.s12),
          Text(
            'No active partnerships.',
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

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: DesignTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Vendor avatar ─────────────────────────────────────────────────────────────

class _VendorAvatar extends StatelessWidget {
  const _VendorAvatar({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        shape: BoxShape.circle,
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: DesignTokens.textWhite,
        ),
      ),
    );
  }
}

// ── Ended tab ─────────────────────────────────────────────────────────────────

class _EndedTab extends StatelessWidget {
  const _EndedTab({required this.state});

  final PartnershipsState state;

  @override
  Widget build(BuildContext context) {
    return _body();
  }

  Widget _body() {
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (_, _, ended) => ended.isEmpty
          ? _empty()
          : RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: () async {},
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s12,
                  DesignTokens.s16,
                  DesignTokens.s32,
                ),
                itemCount: ended.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, i) => _EndedPartnershipCard(ended[i]),
              ),
            ),
      loadFailure: (f) => _ErrorBody(
        message: NetworkExceptions.getMessage(f),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );

  Widget _empty() => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined,
                size: 48, color: DesignTokens.textMuted),
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

class _EndedPartnershipCard extends StatelessWidget {
  const _EndedPartnershipCard(this.partnership);

  final EndedPartnership partnership;

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
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: _VendorAvatar(
                  url: partnership.vendorLogoUrl,
                  name: partnership.vendorName,
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnership.vendorName.isNotEmpty
                          ? partnership.vendorName
                          : 'Brand',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${partnership.commissionRate.round()}% commission',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Ended',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          const _DashedDivider(),
          const SizedBox(height: DesignTokens.s12),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Start Date',
            trailingText: DateFormat('d MMM, yyyy').format(partnership.startedAt),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Ended On',
            trailingText: DateFormat('d MMM, yyyy').format(partnership.endedAt),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
              width: 15,
              height: 15,
              color: DesignTokens.textMuted,
            ),
            label: 'Total Earnings',
            trailing: _EarningsChip(formatMoney(partnership.totalEarned)),
          ),
          if (partnership.endReason != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.info_outline_rounded,
              label: 'Reason',
              trailingText: partnership.endReason!,
            ),
          ],
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

Future<void> _showFilterSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _FilterSheetContent(),
  );
}

Future<void> _showSortSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
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
    required this.partnershipId,
    required this.vendorProfileId,
    this.vendorAccountId,
    required this.logo,
    required this.name,
    required this.productsTagged,
    required this.commissionPct,
    required this.startDate,
    required this.totalEarnings,
    required this.activeCampaigns,
  });

  final String partnershipId;
  final String vendorProfileId;
  final String? vendorAccountId;
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
                        Image.asset(
                          'assets/images/creatordash/material-symbols_package-2-outline.png',
                          width: 13,
                          height: 13,
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
              _PartnershipCardMenu(
                partnershipId: partnershipId,
                name: name,
                vendorProfileId: vendorProfileId,
                vendorAccountId: vendorAccountId,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  final accountId =
                      (vendorAccountId != null && vendorAccountId!.isNotEmpty)
                          ? vendorAccountId
                          : null;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                    // rating/category aren't carried by the active-
                    // partnership data — honestly left at 0/'' rather than
                    // fabricated (same convention as brands_screen.dart's
                    // _toBrandInfoData for fields the endpoint lacks).
                    builder: (_) => BrandMessagingScreen(
                      args: BrandMessagingArgs(
                        brandName: name,
                        rating: 0,
                        category: '',
                          otherParticipantId: accountId,
                          profileId: accountId == null ? vendorProfileId : null,
                        ),
                      ),
                    ),
                  );
                },
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.s8),
                child: Text(
                  '·',
                  style: TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showTermsSheet(context, partnershipId),
                child: const Text(
                  'View Terms',
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
            ],
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
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
              width: 15,
              height: 15,
              color: DesignTokens.textMuted,
            ),
            label: 'Total Earnings',
            trailing: _EarningsChip(totalEarnings),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_package-2-outline.png',
              width: 15,
              height: 15,
              color: DesignTokens.textMuted,
            ),
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
                  // No end/leave/terminate method exists anywhere on the
                  // creator partnerships repository/domain interface (unlike
                  // vendor's partnerships repo, which has end()) — this is a
                  // genuine backend contract gap, not just unwired UI.
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ending a partnership is coming soon.'),
                    ),
                  ),
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

Future<void> _showTermsSheet(BuildContext context, String partnershipId) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TermsBottomSheet(partnershipId: partnershipId),
  );
}

// Three-dot popup menu attached to each active partnership item card.
// Includes the Messages action that wires into the existing
// BrandMessagingScreen + ChatView pipeline (Realtime SignalR-backed
// conversations with the brand). Other entries delegate to existing
// handlers (terms sheet, analytics route, end-partnership snackbar).
class _PartnershipCardMenu extends StatelessWidget {
  const _PartnershipCardMenu({
    required this.partnershipId,
    required this.name,
    required this.vendorProfileId,
    this.vendorAccountId,
  });

  final String partnershipId;
  final String name;
  final String vendorProfileId;
  final String? vendorAccountId;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: DesignTokens.iconLight,
        size: 22,
      ),
      color: DesignTokens.bgAppBody,
      tooltip: 'Partnership actions',
      onSelected: (value) {
        switch (value) {
          case 'messages':
            // Prefer the backend-populated vendor account id to skip the
            // /v1/accounts/by-profile/{id} lookup (which 404s when
            // vendorProfileId is a VendorProfile.Id rather than a
            // RoleProfile.Id). Only fall back to profileId when no
            // account id is available.
            final accountId =
                (vendorAccountId != null && vendorAccountId!.isNotEmpty)
                    ? vendorAccountId
                    : null;
            context.push(
              RouteNames.brandMessaging,
              extra: BrandMessagingArgs(
                brandName: name,
                rating: 0,
                category: '',
                otherParticipantId: accountId,
                profileId: accountId == null ? vendorProfileId : null,
              ),
            );
            break;
          case 'terms':
            _showTermsSheet(context, partnershipId);
            break;
          case 'analytics':
            context.push(RouteNames.creatorAnalytics);
            break;
          case 'end':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ending a partnership is coming soon.'),
              ),
            );
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem<String>(
          value: 'messages',
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: DesignTokens.textWhite),
              SizedBox(width: 12),
              Text(
                'Messages',
                style: TextStyle(color: DesignTokens.textWhite),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'terms',
          child: Row(
            children: [
              Icon(Icons.description_outlined,
                  size: 18, color: DesignTokens.textWhite),
              SizedBox(width: 12),
              Text(
                'View Terms',
                style: TextStyle(color: DesignTokens.textWhite),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'analytics',
          child: Row(
            children: [
              Icon(Icons.insights_rounded,
                  size: 18, color: DesignTokens.textWhite),
              SizedBox(width: 12),
              Text(
                'View Analytics',
                style: TextStyle(color: DesignTokens.textWhite),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'end',
          child: Row(
            children: [
              Icon(Icons.handshake_outlined,
                  size: 18, color: DesignTokens.colorError),
              SizedBox(width: 12),
              Text(
                'End Partnership',
                style: TextStyle(color: DesignTokens.colorError),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TermsBottomSheet extends ConsumerWidget {
  const _TermsBottomSheet({required this.partnershipId});

  final String partnershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final termsAsync = ref.watch(partnershipTermsProvider(partnershipId));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Partnership Terms',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: DesignTokens.textLight, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          termsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                    color: DesignTokens.primaryGreen),
              ),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                'Could not load terms.',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
            data: (terms) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TermsSection(index: 1, section: terms.whoCanJoin),
                    const SizedBox(height: DesignTokens.s24),
                    _TermsSection(index: 2, section: terms.reelContentRules),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.index, required this.section});
  final int index;
  final TermsSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$index. ${section.heading}',
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (section.bullets.isEmpty)
          const Text('—',
              style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.textMuted))
        else
          for (final b in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: DesignTokens.s8),
                    child: Icon(Icons.circle,
                        size: 6, color: DesignTokens.textLight),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.icon,
    this.iconWidget,
    this.trailingText,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final String? trailingText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget ??
            Icon(icon ?? Icons.circle, size: 15, color: DesignTokens.textMuted),
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
        ?trailing,
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
