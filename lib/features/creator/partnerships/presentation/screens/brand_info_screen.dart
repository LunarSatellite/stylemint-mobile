import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Seed data (passed in from the catalog list) ──────────────────────────────

/// Initial values populated from the brand catalog list
/// (`GET /v1/brands`). Real description / rating / success rate /
/// category values are fetched after mount via [brandDetailProvider]
/// and [brandTrustProvider] and override these seeds once loaded.
class BrandInfoData {
  const BrandInfoData({
    required this.name,
    required this.logoUrl,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.vendorProfileId,
  });

  final String name;
  final String? logoUrl;
  final double commissionMinPercent;
  final double commissionMaxPercent;

  /// AccountId of the vendor profile — primary key used to fetch
  /// detail/trust on mount. Empty means the screen was opened without
  /// a known vendor (and the Apply button stays disabled).
  final String vendorProfileId;

  String get seedCommissionLabel =>
      '${commissionMinPercent.toStringAsFixed(0)}-'
      '${commissionMaxPercent.toStringAsFixed(0)}%';
}

// ── Screen ───────────────────────────────────────────────────────────────────

class BrandInfoScreen extends ConsumerStatefulWidget {
  const BrandInfoScreen({super.key, required this.data});
  final BrandInfoData data;

  @override
  ConsumerState<BrandInfoScreen> createState() => _BrandInfoScreenState();
}

class _BrandInfoScreenState extends ConsumerState<BrandInfoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _descExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          'Brand Details',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      bottomNavigationBar: _ApplyButton(seed: widget.data),
      body: Column(
        children: [
          _BrandHeader(seed: widget.data, expanded: _descExpanded, onToggle: () {
            setState(() => _descExpanded = !_descExpanded);
          }),
          TabBar(
            controller: _tabController,
            indicatorColor: DesignTokens.primaryGreen,
            indicatorWeight: 2,
            labelColor: DesignTokens.primaryGreen,
            unselectedLabelColor: DesignTokens.textMuted,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
            tabs: const [
              Tab(text: 'Top Products'),
              Tab(text: 'Sample Campaigns'),
              Tab(text: 'Partnership Terms'),
            ],
          ),
          const Divider(height: 1, color: DesignTokens.borderDefault),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TopProductsTab(),
                _SampleCampaignsTab(),
                _PartnershipTermsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header (logo + name + rating + commission + description + metrics) ───────

class _BrandHeader extends ConsumerWidget {
  const _BrandHeader({
    required this.seed,
    required this.expanded,
    required this.onToggle,
  });

  final BrandInfoData seed;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorId = seed.vendorProfileId;

    // Detail (description, business type, commission range) — fetches
    // when we have a vendor id; stays in loading state until then.
    final detailAsync = vendorId.isEmpty
        ? const AsyncValue<BrandDetailDto>.data(_emptyDetail)
        : ref.watch(brandDetailProvider(vendorId));

    // Trust (rating, success rate) — optional. Vendors without a trust
    // row yet return 404, which we surface as "no rating yet".
    final trustAsync = vendorId.isEmpty
        ? const AsyncValue<BrandTrustDto>.data(_emptyTrust)
        : ref.watch(brandTrustProvider(vendorId));

    final detail = detailAsync.asData?.value;
    final trust = trustAsync.asData?.value;

    final name = detail?.businessName.isNotEmpty == true
        ? detail!.businessName
        : seed.name;
    final logoUrl = detail?.logoUrl ?? seed.logoUrl;
    final category = detail?.businessTypeLabel ?? '';
    final commissionLabel = detail?.commissionRangeLabel ?? seed.seedCommissionLabel;
    final description = detail?.description;
    final rating = trust == null ? null : trust.score;
    final successRate = trust == null ? null : trust.partnershipCompletionRatePercent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + name + rating + commission
          Row(
            children: [
              SizedBox(width: 64, height: 64, child: _BrandLogo(name: name, logoUrl: logoUrl)),
              const SizedBox(width: DesignTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: DesignTokens.secondaryYellow,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating == null ? '--' : rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '· $category',
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 13,
                                color: DesignTokens.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    _CommissionChip(commissionLabel),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Description — only rendered once the detail endpoint has a
          // real description. While loading or on null/empty description
          // we skip the tile entirely so we never show "placeholder" text.
          if (description != null && description.isNotEmpty) ...[
            _ExpandableDescription(
              text: description,
              expanded: expanded,
              onToggle: onToggle,
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
          // Metrics
          _MetricRow(
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_package-2-outline.png',
              width: 18,
              height: 18,
              color: DesignTokens.textMuted,
            ),
            label: 'Avg Order Value',
            // No backend field today; honest placeholder until a brand-level
            // AOV endpoint exists. The list endpoint, brand detail, and
            // trust score all return no AOV — don't fabricate one.
            value: '--',
          ),
          const SizedBox(height: DesignTokens.s8),
          _MetricRow(
            icon: Icons.handshake_outlined,
            label: 'Success Rate with Creators',
            value: successRate == null ? '--' : '${successRate.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: DesignTokens.s4),
        ],
      ),
    );
  }

  // Sentinel used when there is no vendor id at all (so the providers
  // aren't even watched). The screen guards on this and renders nothing
  // detail-specific in that path.
  static const _emptyDetail = BrandDetailDto(
    id: '',
    accountId: '',
    businessName: '',
    businessType: 0,
    commissionRangeMinPercent: 0,
    commissionRangeMaxPercent: 0,
  );
  static const _emptyTrust = BrandTrustDto(
    vendorAccountId: '',
    score: 0,
    tier: 0,
    totalPartnerships: 0,
    verifiedByCount: 0,
    partnershipCompletionRatePercent: 0,
    paymentReliabilityPercent: 0,
    communicationResponseRatePercent: 0,
    briefQualityPercent: 0,
    creatorSatisfactionPercent: 0,
  );
}

// ── Brand logo (initials fallback) ───────────────────────────────────────────

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          logoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: DesignTokens.textWhite,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ── Description with Read More ────────────────────────────────────────────────

class _ExpandableDescription extends StatelessWidget {
  const _ExpandableDescription({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 13,
      height: 1.5,
      color: DesignTokens.textLight,
    );
    if (expanded) {
      return RichText(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(text: text),
            const TextSpan(text: '  '),
            WidgetSpan(
              child: GestureDetector(
                onTap: onToggle,
                child: const Text(
                  'Show Less',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Collapsed — show 3 lines max
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.clip,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(
            text: text.length > 120 ? '${text.substring(0, 120)}.. ' : text,
          ),
          WidgetSpan(
            child: GestureDetector(
              onTap: onToggle,
              child: const Text(
                'Read More',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric row ────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    this.icon,
    this.iconWidget,
    required this.label,
    required this.value,
  }) : assert(icon != null || iconWidget != null);

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget ?? Icon(icon!, size: 15, color: DesignTokens.textMuted),
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
        Text(
          value,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

// ── Commission chip ───────────────────────────────────────────────────────────

class _CommissionChip extends StatelessWidget {
  const _CommissionChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF87CEEB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label Commissions',
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D1B4B),
        ),
      ),
    );
  }
}

// ── Top Products tab ──────────────────────────────────────────────────────────

/// Real per-brand top-products endpoint does not exist on the backend
/// today (`StyleMint.Modules.Catalog.Service.ProductService` only
/// exposes `PageForVendorAsync` — vendor-self-only — so a creator
/// cannot list another vendor's products). Show an honest empty
/// state until that endpoint ships.
class _TopProductsTab extends StatelessWidget {
  const _TopProductsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        const SizedBox(height: DesignTokens.s24),
        Icon(Icons.inventory_2_outlined, size: 48, color: DesignTokens.textLight),
        const SizedBox(height: DesignTokens.s12),
        const Text(
          'No top products yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

// ── Sample Campaigns tab ──────────────────────────────────────────────────────

class _SampleCampaignsTab extends StatelessWidget {
  const _SampleCampaignsTab();

  static const _campaigns = [
    (
      title: 'Nike Zoom Series: Athlete Sprint Edition',
      reels: '5.8k',
      collabs: '269',
      thumbColor: Color(0xFFE8E8E8),
      thumbIcon: Icons.directions_run_rounded,
    ),
    (
      title: 'Nike Tech Fleece Jacket. Athlete Style for Every Age',
      reels: '2.7k',
      collabs: '345',
      thumbColor: Color(0xFFD6CFC7),
      thumbIcon: Icons.checkroom_rounded,
    ),
    (
      title: 'Air Max Collection: Street to Stadium',
      reels: '4.1k',
      collabs: '512',
      thumbColor: Color(0xFF1A3A5C),
      thumbIcon: Icons.sports_soccer_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.s16),
      itemCount: _campaigns.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) {
        final c = _campaigns[i];
        return _CampaignCard(
          title: c.title,
          reels: c.reels,
          collabs: c.collabs,
          thumbColor: c.thumbColor,
          thumbIcon: c.thumbIcon,
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.title,
    required this.reels,
    required this.collabs,
    required this.thumbColor,
    required this.thumbIcon,
  });

  final String title;
  final String reels;
  final String collabs;
  final Color thumbColor;
  final IconData thumbIcon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: thumbColor,
            alignment: Alignment.center,
            child: Icon(thumbIcon, size: 64, color: Colors.black26),
          ),
          Container(
            width: double.infinity,
            color: DesignTokens.bgAppBodyLight,
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s12,
              DesignTokens.s8,
              DesignTokens.s12,
              DesignTokens.s12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/creatordash/material-symbols_animated-images-outline-rounded.png',
                      width: 14,
                      height: 14,
                      color: DesignTokens.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$reels Reels',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s16),
                    const Icon(Icons.handshake_outlined, size: 14, color: DesignTokens.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '$collabs Creator Collabs',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Partnership Terms tab ─────────────────────────────────────────────────────

class _PartnershipTermsTab extends StatelessWidget {
  const _PartnershipTermsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: const [
        _TermsCard(
          title: 'Who Can Join',
          bullets: [
            'Open to all verified StyleMint creators.',
            'Must have synced social account with at least 1,000 engaged followers.',
            'No active policy violations in the last 90 days.',
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        _TermsCard(
          title: 'Reel Content Rules',
          bullets: [
            'Showcase the product in real use; candid framing preferred.',
            'Hook within the first 3 seconds; minimum 15s reel length.',
            'Add the partnership disclosure tag; honour the supplied brief.',
            'No comparative claims against competitors in the same category.',
          ],
        ),
      ],
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.title, required this.bullets});
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5, right: DesignTokens.s8),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        height: 1.5,
                        color: DesignTokens.textLight,
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

// ── Apply for Partnership button ──────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({required this.seed});
  final BrandInfoData seed;

  @override
  Widget build(BuildContext context) {
    final canApply = seed.vendorProfileId.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s8,
          DesignTokens.s16,
          DesignTokens.s16,
        ),
        child: GestureDetector(
          onTap: canApply
              ? () {
                  context.push(
                    RouteNames.partnershipApply
                        .replaceFirst(':partnershipId', _slugify(seed.name)),
                    extra: PartnershipApplyArgs(
                      vendorProfileId: seed.vendorProfileId,
                      vendorName: seed.name,
                      vendorRating: null,
                      vendorCategory: null,
                      commissionMin: seed.commissionMinPercent,
                      commissionMax: seed.commissionMaxPercent,
                    ),
                  );
                }
              : null,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: canApply
                  ? DesignTokens.primaryGreen
                  : DesignTokens.primaryGreen.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Apply for Partnership  →',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _slugify(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
