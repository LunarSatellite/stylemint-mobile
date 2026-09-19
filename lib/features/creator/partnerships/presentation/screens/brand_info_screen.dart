import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/brand_partnership_record_panel.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Seed data (passed in from the catalog list) ──────────────────────────────

/// Initial values populated from the brand catalog list
/// (`GET /v1/brands`). The real description, category and commission range
/// are fetched after mount via [brandDetailProvider] and override these
/// seeds once loaded.
class BrandInfoData {
  const BrandInfoData({
    required this.name,
    required this.logoUrl,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.vendorAccountId,
  });

  final String name;
  final String? logoUrl;
  final double commissionMinPercent;
  final double commissionMaxPercent;

  /// The vendor's **account** id — what `GET /v1/brands` returns as
  /// `accountId` and what the brand detail endpoint is addressed by. It was
  /// called `vendorProfileId` while holding this, which is how a request
  /// keyed by profile id came to be sent an account id. The profile id
  /// arrives with the brand detail, as its `id`.
  ///
  /// Empty means the screen was opened without a known vendor, and the
  /// Apply button stays disabled.
  final String vendorAccountId;

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
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.popOrHome(),
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
              // The record leads: it is the thing a creator is on this
              // screen to weigh, and it is the only tab whose content is
              // measured rather than illustrative.
              Tab(text: 'Partnership Record'),
              Tab(text: 'Top Products'),
              // "Sample Campaigns" and "Partnership Terms" stood here.
              // Both are gone, tab and body; see the note above
              // [_TopProductsTab] for what each of them was actually
              // showing and why no honest version of either can be built
              // against today's backend.
            ],
          ),
          const Divider(height: 1, color: DesignTokens.borderDefault),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                BrandPartnershipRecordPanel(
                  vendorAccountId: widget.data.vendorAccountId,
                ),
                const _TopProductsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header (logo + name + category + commission + description) ───────────────

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
    final vendorId = seed.vendorAccountId;

    // Detail (description, business type, commission range) — fetches
    // when we have a vendor id; stays in loading state until then.
    final detailAsync = vendorId.isEmpty
        ? const AsyncValue<BrandDetailDto>.data(_emptyDetail)
        : ref.watch(brandDetailProvider(vendorId));

    final detail = detailAsync.asData?.value;

    final name = detail?.businessName.isNotEmpty == true
        ? detail!.businessName
        : seed.name;
    final logoUrl = detail?.logoUrl ?? seed.logoUrl;
    final category = detail?.businessTypeLabel ?? '';
    final commissionLabel = detail?.commissionRangeLabel ?? seed.seedCommissionLabel;
    final description = detail?.description;

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
          // Logo + name + category + commission
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
                    // No star rating. There was one, and it read 0.0 for
                    // every brand on the platform — see
                    // `brand_partnership_record_dto.dart`. Nothing on
                    // StyleMint rates a brand, so nothing here draws a
                    // rating; the Partnership Record tab carries what is
                    // actually known.
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          color: DesignTokens.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
          //
          // "Success Rate with Creators" stood below this and read 0% for
          // every brand. It is gone, not defaulted: nothing on the platform
          // records a "completed" partnership outcome, so there is no
          // success rate to state. What is recorded lives on the
          // Partnership Record tab, each figure with its denominator.
          _MetricRow(
            iconWidget: Image.asset(
              'assets/images/creatordash/material-symbols_package-2-outline.png',
              width: 18,
              height: 18,
              color: DesignTokens.textMuted,
            ),
            label: 'Avg Order Value',
            // No backend field today; honest placeholder until a brand-level
            // AOV endpoint exists. Neither the list endpoint nor brand
            // detail returns an AOV — don't fabricate one.
            value: '--',
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
              child: Semantics(
                button: true,
                label: 'Show less of the brand description',
                excludeSemantics: true,
                onTap: onToggle,
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
            child: Semantics(
              button: true,
              label: 'Read the full brand description',
              excludeSemantics: true,
              onTap: onToggle,
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
//
// ── Two tabs were removed from this screen, 2026-09-20 ──────────────────
//
// **Sample Campaigns.** The tab body was a `static const` list of three
// campaigns — 'Nike Zoom Series: Athlete Sprint Edition', 'Nike Tech
// Fleece Jacket. Athlete Style for Every Age' and 'Air Max Collection:
// Street to Stadium' — each with a reel count ('5.8k', '2.7k', '4.1k')
// and a creator-collab count ('269', '345', '512'). None of it came from
// anywhere. It rendered for **every** brand, so a creator weighing up a
// small Nepali vendor was shown Nike's campaigns attributed to that
// vendor, with six invented engagement figures beside them.
//
// There is no endpoint behind it and no endpoint to wire it to. The
// sibling `brand_detail_screen.dart` had a real-looking version that
// fetched `GET /v1/partnerships/{id}/campaigns`; that route does not
// exist in lead360 — `CreatorPartnershipsController` serves
// `/partnerships`, `/partnerships/{id}`, `/{id}/accept`, `/{id}/decline`,
// `/{id}/terms/active`, `/{id}/terms/versions`, `/{id}/potential-earnings`
// and `/creator/partnerships/{id}/recipes`, and nothing else. The only
// campaign routes on the platform are `/v1/vendor/campaign-workspaces`
// (`[Authorize(Roles = "Vendor")]`, scoped to the calling vendor's own
// account), `/v1/admin/campaigns` and `/v1/public/campaigns/active` —
// none of which lists one brand's campaigns to a creator. So the tab is
// gone rather than emptied: an empty "No sample campaigns yet" would
// state that this brand has run none, which is not something the
// platform knows.
//
// **Partnership Terms.** The tab body was two `_TermsCard`s of hardcoded
// bullets, likewise identical for every brand: 'Must have synced social
// account with at least 1,000 engaged followers', 'No active policy
// violations in the last 90 days', 'Hook within the first 3 seconds;
// minimum 15s reel length', and four more. Terms on StyleMint are
// authored **per partnership by the vendor** (`PublishTermsVm` ->
// `POST /v1/vendor/partnerships/{id}/terms`, read back at
// `GET /v1/partnerships/{id}/terms/active`), so they are keyed by a
// partnership id. A creator on this screen has no partnership with this
// brand yet — that is the decision the screen exists to support — so
// there is nothing to key the lookup by and no terms to show. An invented
// follower threshold is worse than no threshold: it can talk a creator
// out of applying. `brand_detail_screen.dart` keeps its Partnership Terms
// tab, because there the partnership id is in hand and the terms are the
// vendor's own.
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

// ── Apply for Partnership button ──────────────────────────────────────────────

class _ApplyButton extends ConsumerWidget {
  const _ApplyButton({required this.seed});
  final BrandInfoData seed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = seed.vendorAccountId;

    // `POST /v1/creator/partnerships/request` stores whatever id it is
    // given as the partnership's VendorProfileId, with no lookup — so it
    // has to be handed the profile id, which the brand detail response
    // carries as its `id`. Until that lands we still have the account id
    // the catalog supplied, which is what this screen has always sent.
    final detail = accountId.isEmpty
        ? null
        : ref.watch(brandDetailProvider(accountId)).asData?.value;
    final vendorProfileId = (detail != null && detail.id.isNotEmpty)
        ? detail.id
        : accountId;

    final canApply = vendorProfileId.isNotEmpty;

    void apply() {
      context.push(
        RouteNames.partnershipApply
            .replaceFirst(':partnershipId', _slugify(seed.name)),
        extra: PartnershipApplyArgs(
          vendorProfileId: vendorProfileId,
          vendorName: seed.name,
          vendorRating: null,
          vendorCategory: null,
          commissionMin: seed.commissionMinPercent,
          commissionMax: seed.commissionMaxPercent,
        ),
      );
    }

    // The disabled state used to be a 40%-alpha fill and nothing else, so
    // "you cannot apply to this brand" was carried by colour alone. It now
    // carries a glyph and a word as well.
    final label = canApply
        ? 'Apply for Partnership  →'
        : 'Apply unavailable';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s8,
          DesignTokens.s16,
          DesignTokens.s16,
        ),
        child: Semantics(
          button: true,
          enabled: canApply,
          label: canApply
              ? 'Apply for Partnership'
              : 'Apply for Partnership. Unavailable — this brand was opened '
                    'without a vendor id.',
          excludeSemantics: true,
          onTap: canApply ? apply : null,
          child: GestureDetector(
            onTap: canApply ? apply : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s8,
              ),
              decoration: BoxDecoration(
                color: canApply
                    ? DesignTokens.primaryGreen
                    : DesignTokens.primaryGreen.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!canApply) ...[
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
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
