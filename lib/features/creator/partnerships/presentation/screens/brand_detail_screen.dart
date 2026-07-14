import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_apply_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final _partnershipProvider = FutureProvider.autoDispose
    .family<PartnershipDetailDto, String>((ref, id) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get('/v1/partnerships/$id');
  return PartnershipDetailDto.fromJson(res as Map<String, dynamic>);
});

final _campaignsProvider = FutureProvider.autoDispose
    .family<List<SampleCampaignDto>, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.get('/v1/partnerships/$id/campaigns');
  final list =
      (res is List ? res : (res as Map<String, dynamic>?)?['data'] as List?) ??
          [];
  return list
      .map((e) => SampleCampaignDto.fromJson(e as Map<String, dynamic>))
      .toList();
});

class BrandDetailScreen extends ConsumerWidget {
  const BrandDetailScreen({super.key, required this.partnershipId});

  final String partnershipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnershipAsync = ref.watch(_partnershipProvider(partnershipId));
    final termsAsync = ref.watch(partnershipTermsProvider(partnershipId));
    final campaignsAsync = ref.watch(_campaignsProvider(partnershipId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 18, color: DesignTokens.textWhite),
            onPressed: () => context.pop(),
          ),
          title: const Text('Brand Details',
              style: DesignTokens.sectionInnerTitle),
        ),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(
              child: partnershipAsync.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen),
                  ),
                ),
                error: (_, __) => const SizedBox(),
                data: (p) => _BrandHeader(partnership: p),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  labelColor: DesignTokens.primaryGreen,
                  unselectedLabelColor: DesignTokens.textLight,
                  indicatorColor: DesignTokens.primaryGreen,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: DesignTokens.smallRegular
                      .copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: DesignTokens.smallRegular,
                  tabs: const [
                    Tab(text: 'Top Products'),
                    Tab(text: 'Sample Campaigns'),
                    Tab(text: 'Partnership Terms'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _TopProductsTab(),
              _SampleCampaignsTab(campaignsAsync: campaignsAsync),
              _PartnershipTab(termsAsync: termsAsync),
            ],
          ),
        ),
        bottomNavigationBar: _ApplyButton(
          onPressed: partnershipAsync.asData?.value != null
              ? () {
                  final p = partnershipAsync.asData!.value;
                  context.push(
                    '/creator/partnerships/${p.id}/apply',
                    extra: PartnershipApplyArgs(
                      partnershipId: p.id,
                      vendorName: p.vendorName,
                      vendorLogoUrl: p.vendorLogoUrl,
                      vendorRating: p.vendorRating,
                      vendorCategory: p.vendorCategory,
                      commissionMin: p.commissionMinPercent,
                      commissionMax: p.commissionMaxPercent,
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }
}

// ── Brand header ────────────────────────────────────────────────────────────

class _BrandHeader extends StatefulWidget {
  const _BrandHeader({required this.partnership});
  final PartnershipDetailDto partnership;

  @override
  State<_BrandHeader> createState() => _BrandHeaderState();
}

class _BrandHeaderState extends State<_BrandHeader> {
  bool _descExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.partnership;
    final commission = p.commissionMinPercent == p.commissionMaxPercent
        ? '${p.commissionMaxPercent.toStringAsFixed(0)}% Commission'
        : '${p.commissionMinPercent.toStringAsFixed(0)}-'
            '${p.commissionMaxPercent.toStringAsFixed(0)}% Commissions';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s8, DesignTokens.s16, DesignTokens.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _VendorLogo(url: p.vendorLogoUrl),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.vendorName,
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.textWhite),
                    ),
                    if (p.vendorRating != null || p.vendorCategory != null) ...[
                      const SizedBox(height: 2),
                      _RatingCategory(
                          rating: p.vendorRating, category: p.vendorCategory),
                    ],
                    const SizedBox(height: DesignTokens.s8),
                    _CommissionChip(label: commission),
                  ],
                ),
              ),
            ],
          ),
          // Description
          if (p.description != null && p.description!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            _ExpandableText(
              text: p.description!,
              expanded: _descExpanded,
              onToggle: () =>
                  setState(() => _descExpanded = !_descExpanded),
            ),
          ],
          // Stats
          if (p.avgOrderValue != null || p.successRatePercent != null) ...[
            const SizedBox(height: DesignTokens.s12),
            _StatsSection(
                avgOrderValue: p.avgOrderValue,
                successRatePercent: p.successRatePercent),
          ],
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    );
  }
}

class _VendorLogo extends StatelessWidget {
  const _VendorLogo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(url!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _StoreFallback())
          : const _StoreFallback(),
    );
  }
}

class _StoreFallback extends StatelessWidget {
  const _StoreFallback();
  @override
  Widget build(BuildContext context) => const Icon(Icons.store_rounded,
      color: DesignTokens.textLight, size: 28);
}

class _RatingCategory extends StatelessWidget {
  const _RatingCategory({this.rating, this.category});
  final double? rating;
  final String? category;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (rating != null) ...[
          const Icon(Icons.star_rounded,
              size: 14, color: DesignTokens.secondaryYellow),
          const SizedBox(width: 2),
          Text(rating!.toStringAsFixed(1),
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textWhite)),
          if (category != null)
            Text(' · ',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight)),
        ],
        if (category != null)
          Expanded(
            child: Text(
              category!,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _CommissionChip extends StatelessWidget {
  const _CommissionChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8, vertical: 3),
      decoration: BoxDecoration(
        color: DesignTokens.chipsSelectedFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: DesignTokens.smallRegular
              .copyWith(color: DesignTokens.primaryGreen)),
    );
  }
}

class _ExpandableText extends StatelessWidget {
  const _ExpandableText(
      {required this.text,
      required this.expanded,
      required this.onToggle});
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final needsToggle = text.length > 120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: DesignTokens.bodyText,
          maxLines: expanded ? null : 3,
          overflow: expanded ? null : TextOverflow.ellipsis,
        ),
        if (needsToggle)
          GestureDetector(
            onTap: onToggle,
            child: Text(
              expanded ? 'Read Less' : 'Read More',
              style: DesignTokens.bodyText
                  .copyWith(color: DesignTokens.primaryGreen),
            ),
          ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({this.avgOrderValue, this.successRatePercent});
  final double? avgOrderValue;
  final double? successRatePercent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (avgOrderValue != null)
          _StatRow(
            label: 'Avg Order Value',
            value: 'Rs ${_formatMoney(avgOrderValue!)}',
          ),
        if (avgOrderValue != null && successRatePercent != null)
          const SizedBox(height: DesignTokens.s8),
        if (successRatePercent != null)
          _StatRow(
            label: 'Success Rate with Creators',
            value: '${successRatePercent!.toStringAsFixed(0)}%',
          ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 8, color: DesignTokens.textLight),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(label,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight)),
        ),
        Text(value,
            style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Sticky tab bar ───────────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(
      color: DesignTokens.bgAppFoundation,
      child: Column(
        children: [
          tabBar,
          const Divider(
              height: 1, thickness: 1, color: DesignTokens.borderDefault),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate old) => tabBar != old.tabBar;
}

// ── Tabs ─────────────────────────────────────────────────────────────────────

class _TopProductsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        const SizedBox(height: DesignTokens.s24),
        Icon(Icons.inventory_2_outlined,
            size: 48, color: DesignTokens.textLight),
        const SizedBox(height: DesignTokens.s12),
        Text(
          'No top products yet',
          textAlign: TextAlign.center,
          style:
              DesignTokens.bodyText.copyWith(color: DesignTokens.textLight),
        ),
      ],
    );
  }
}

class _SampleCampaignsTab extends StatelessWidget {
  const _SampleCampaignsTab({required this.campaignsAsync});
  final AsyncValue<List<SampleCampaignDto>> campaignsAsync;

  @override
  Widget build(BuildContext context) {
    return campaignsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
      error: (_, __) => Center(
        child: Text("Couldn't load campaigns.",
            style: DesignTokens.bodyText),
      ),
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              const SizedBox(height: DesignTokens.s24),
              Icon(Icons.movie_creation_outlined,
                  size: 48, color: DesignTokens.textLight),
              const SizedBox(height: DesignTokens.s12),
              Text(
                'No sample campaigns yet',
                textAlign: TextAlign.center,
                style: DesignTokens.bodyText
                    .copyWith(color: DesignTokens.textLight),
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
              DesignTokens.s16, DesignTokens.s16, DesignTokens.s24),
          itemCount: campaigns.length,
          itemBuilder: (_, i) => _CampaignCard(campaign: campaigns[i]),
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.campaign});
  final SampleCampaignDto campaign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: campaign.imageUrl != null
                  ? Image.network(
                      campaign.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          // Title
          Text(
            campaign.title,
            style: DesignTokens.mediumSemibold
                .copyWith(color: DesignTokens.textWhite),
          ),
          const SizedBox(height: 4),
          // Stats
          Row(
            children: [
              const Icon(Icons.video_camera_back_outlined,
                  size: 14, color: DesignTokens.textLight),
              const SizedBox(width: 4),
              Text(
                '${_formatCount(campaign.reelCount)} Reels',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight),
              ),
              const SizedBox(width: DesignTokens.s12),
              const Icon(Icons.people_outline_rounded,
                  size: 14, color: DesignTokens.textLight),
              const SizedBox(width: 4),
              Text(
                '${_formatCount(campaign.creatorCollabCount)} Creator Collabs',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: DesignTokens.bgAppBodyLight,
      child: const Center(
        child: Icon(Icons.image_outlined,
            color: DesignTokens.textLight, size: 40),
      ),
    );
  }
}

class _PartnershipTab extends StatelessWidget {
  const _PartnershipTab({required this.termsAsync});
  final AsyncValue<PartnershipTermsDto> termsAsync;

  @override
  Widget build(BuildContext context) {
    return termsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
      error: (_, __) => Center(
        child: Text('Terms unavailable.', style: DesignTokens.bodyText),
      ),
      data: (t) => ListView(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s16,
            DesignTokens.s16, DesignTokens.s24),
        children: [
          _TermsSection(index: 1, section: t.whoCanJoin),
          const SizedBox(height: DesignTokens.s24),
          _TermsSection(index: 2, section: t.reelContentRules),
        ],
      ),
    );
  }
}

// ── Apply button ─────────────────────────────────────────────────────────────

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s8,
            DesignTokens.s16, DesignTokens.s16),
        child: SizedBox(
          width: double.infinity,
          height: DesignTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(DesignTokens.buttonRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Apply for Partnership',
                  style: DesignTokens.oneLinerSemibold
                      .copyWith(color: DesignTokens.buttonPrimaryText),
                ),
                const SizedBox(width: DesignTokens.s8),
                const Icon(Icons.arrow_forward_rounded,
                    color: DesignTokens.buttonPrimaryText, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

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
          style: DesignTokens.mediumSemibold
              .copyWith(color: DesignTokens.textWhite),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (section.bullets.isEmpty)
          Text('—',
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted))
        else
          for (final b in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: DesignTokens.s12),
                    child: Icon(Icons.circle,
                        size: 7, color: DesignTokens.textWhite),
                  ),
                  Expanded(child: Text(b, style: DesignTokens.bodyText)),
                ],
              ),
            ),
      ],
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatCount(int n) {
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return n.toString();
}

String _formatMoney(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intStr = parts[0];
  final buf = StringBuffer();
  final len = intStr.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(',');
    buf.write(intStr[i]);
  }
  return '$buf.${parts[1]}';
}
