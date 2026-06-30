import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/partnership_apply_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
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
      bottomNavigationBar: _ApplyButton(data: d),
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
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.textWhite,
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
                  iconWidget: Image.asset('assets/images/creatordash/material-symbols_package-2-outline.png', width: 18, height: 18, color: DesignTokens.textMuted),
                  label: 'Avg Order Value',
                  value: d.avgOrderValue,
                ),
                const SizedBox(height: DesignTokens.s8),
                _MetricRow(
                  icon: Icons.handshake_outlined,
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
                    Image.asset('assets/images/creatordash/material-symbols_animated-images-outline-rounded.png', width: 14, height: 14, color: DesignTokens.textMuted),
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
            'Must have synced social accounts before participating.',
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        const _ReelContentRulesCard(),
      ],
    );
  }
}

class _ReelContentRulesCard extends StatelessWidget {
  const _ReelContentRulesCard();

  static const _bulletColor = Color(0xFF26C6DA);

  static const _bullets = [
    null, // first bullet uses RichText
    'Showcase Nike Running Shoes in action — jogging, sprinting, workouts, or styling shots.',
    'Minimum reel length: 8 seconds',
    'Reel must clearly feature Nike Zoom Series branding or product visuals.',
    'No third-party brand logos allowed in the reel.',
  ];

  Widget _dot() => const Padding(
        padding: EdgeInsets.only(top: 5, right: DesignTokens.s8),
        child: Icon(Icons.circle, size: 5, color: DesignTokens.textLight),
      );

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
            const Text(
              '2. Reel Content Rules',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            // First bullet with teal link
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dot(),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          height: 1.5,
                          color: DesignTokens.textLight,
                        ),
                        children: const [
                          TextSpan(text: 'Use the hero video provided in the campaign details. Or download it by '),
                          TextSpan(
                            text: 'clicking here',
                            style: TextStyle(color: _bulletColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            for (final b in _bullets.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dot(),
                    Expanded(
                      child: Text(
                        b!,
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

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rr);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
  const _ApplyButton({required this.data});
  final BrandInfoData data;

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
            final min = _parseMin(data.commission);
            final max = _parseMax(data.commission);
            context.push(
              RouteNames.partnershipApply
                  .replaceFirst(':partnershipId', _slugify(data.name)),
              extra: PartnershipApplyArgs(
                partnershipId: _slugify(data.name),
                vendorName: data.name,
                vendorRating: data.stars,
                vendorCategory: data.category,
                commissionMin: min,
                commissionMax: max,
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
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Parses "12-20%" → 12.0, "18%" → 18.0
double _parseMin(String s) {
  final n = s.replaceAll('%', '').trim();
  if (n.contains('-')) return double.tryParse(n.split('-')[0].trim()) ?? 0;
  return double.tryParse(n) ?? 0;
}

double _parseMax(String s) {
  final n = s.replaceAll('%', '').trim();
  if (n.contains('-')) return double.tryParse(n.split('-')[1].trim()) ?? 0;
  return double.tryParse(n) ?? 0;
}

String _slugify(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
