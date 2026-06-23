import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Data model ────────────────────────────────────────────────────────────────

class BrandInfoData {
  const BrandInfoData({
    required this.name,
    required this.logo,
    required this.stars,
    required this.category,
    required this.commission,
    required this.description,
    required this.avgOrderValue,
    required this.successRate,
    required this.products,
  });

  final String name;
  final Widget logo;
  final double stars;
  final String category;
  final String commission;
  final String description;
  final String avgOrderValue;
  final String successRate;
  final List<BrandProduct> products;
}

class BrandProduct {
  const BrandProduct({
    required this.name,
    required this.price,
    required this.sales,
    required this.thumbnailColor,
    this.thumbnailIcon = Icons.checkroom_rounded,
  });

  final String name;
  final String price;
  final int sales;
  final Color thumbnailColor;
  final IconData thumbnailIcon;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BrandInfoScreen extends StatefulWidget {
  const BrandInfoScreen({super.key, required this.data});
  final BrandInfoData data;

  @override
  State<BrandInfoScreen> createState() => _BrandInfoScreenState();
}

class _BrandInfoScreenState extends State<BrandInfoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _expanded = false;

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
    final d = widget.data;
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
      bottomNavigationBar: _ApplyButton(brandName: d.name),
      body: Column(
        children: [
          // Header section (non-scrolling above tabs)
          Padding(
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
                    SizedBox(width: 64, height: 64, child: d.logo),
                    const SizedBox(width: DesignTokens.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
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
                                '${d.stars.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: DesignTokens.secondaryYellow,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '· ${d.category}',
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 13,
                                  color: DesignTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _CommissionChip(d.commission),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                // Description
                _ExpandableDescription(
                  text: d.description,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
                const SizedBox(height: DesignTokens.s12),
                // Metrics
                _MetricRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Avg Order Value',
                  value: d.avgOrderValue,
                ),
                const SizedBox(height: DesignTokens.s8),
                _MetricRow(
                  icon: Icons.verified_outlined,
                  label: 'Success Rate with Creators',
                  value: d.successRate,
                ),
                const SizedBox(height: DesignTokens.s4),
              ],
            ),
          ),
          // Tab bar
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
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TopProductsTab(products: d.products),
                const _SampleCampaignsTab(),
                const _PartnershipTermsTab(),
              ],
            ),
          ),
        ],
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
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

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
        color: DesignTokens.primaryGreenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.primaryGreen, width: 0.8),
      ),
      child: Text(
        '$label Commissions',
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}

// ── Top Products tab ──────────────────────────────────────────────────────────

class _TopProductsTab extends StatelessWidget {
  const _TopProductsTab({required this.products});
  final List<BrandProduct> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      itemCount: products.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, i) => _ProductRow(rank: i + 1, product: products[i]),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.rank, required this.product});
  final int rank;
  final BrandProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: product.thumbnailColor,
              child: Icon(
                product.thumbnailIcon,
                color: Colors.white.withValues(alpha: 0.7),
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${product.price} · ${product.sales} sales',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
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

// ── Sample Campaigns tab ──────────────────────────────────────────────────────

class _SampleCampaignsTab extends StatelessWidget {
  const _SampleCampaignsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: DesignTokens.textMuted,
          ),
          SizedBox(height: DesignTokens.s12),
          Text(
            'No sample campaigns available.',
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
            'Creators with 1,000+ followers on any platform',
            'Content must be fashion or lifestyle related',
            'Account must be at least 3 months old',
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        _TermsCard(
          title: 'Reel Content Rules',
          bullets: [
            'Tag at least one product per reel',
            'No competitor brand mentions in the same reel',
            'Must use provided hashtags in caption',
            'Minimum 15 seconds of product visibility',
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        _TermsCard(
          title: 'Payout Policy',
          bullets: [
            'Commissions are paid out monthly',
            'Minimum payout threshold: Rs 1,000',
            'Payment via linked bank account or wallet',
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
                      color: DesignTokens.primaryGreen,
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
  const _ApplyButton({required this.brandName});
  final String brandName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s8,
          DesignTokens.s16,
          DesignTokens.s16,
        ),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Partnership request sent to $brandName!'),
                backgroundColor: DesignTokens.primaryGreen,
              ),
            );
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: DesignTokens.primaryGreen,
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Apply for Partnership  →',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
