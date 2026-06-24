import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/screens/brand_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Static brand catalogue ────────────────────────────────────────────────────

final _nikeData = BrandInfoData(
  name: 'Nike Official Store',
  logo: const _NikeLogo(),
  stars: 4.9,
  category: 'Athletic & Sportswear',
  commission: '12-20%',
  description:
      'Nike is one of the world\'s most recognizable and iconic sportswear '
      'brands, founded in 1964 by Bill Bowerman and Phil Knight. Nike designs, '
      'develops, and markets footwear, apparel, equipment, and accessories.',
  avgOrderValue: 'Rs 12,899.98',
  successRate: '97%',
  products: const [
    BrandProduct(
      name: 'Nike Air Jordan Travis Scott Limited Edition',
      price: 'Rs 25,000',
      sales: 245,
      thumbnailColor: Color(0xFF6B4C3B),
      thumbnailIcon: Icons.sports_basketball_rounded,
    ),
    BrandProduct(
      name: 'Nike Air Max Reds 2025',
      price: 'Rs 18,000',
      sales: 233,
      thumbnailColor: Color(0xFFB71C1C),
      thumbnailIcon: Icons.directions_run_rounded,
    ),
    BrandProduct(
      name: 'Nike Air Jordan Autumn Bloom Ultra Light Sneakers',
      price: 'Rs 32,500',
      sales: 208,
      thumbnailColor: Color(0xFFE65100),
      thumbnailIcon: Icons.directions_walk_rounded,
    ),
    BrandProduct(
      name: 'Nike Tech Fleece Jacket',
      price: 'Rs 12,000',
      sales: 178,
      thumbnailColor: Color(0xFF37474F),
      thumbnailIcon: Icons.checkroom_rounded,
    ),
    BrandProduct(
      name: 'Nike Omi Multi Court Sneakers',
      price: 'Rs 16,000',
      sales: 148,
      thumbnailColor: Color(0xFF0277BD),
      thumbnailIcon: Icons.sports_tennis_rounded,
    ),
  ],
);

final _sephoraData = BrandInfoData(
  name: 'Sephora Beauty',
  logo: const _SephoraLogo(),
  stars: 5.0,
  category: 'Beauty & Cosmetic',
  commission: '15-25%',
  description:
      'Sephora is a leading multinational retailer of personal care and beauty '
      'products. With over 2,700 stores worldwide, Sephora carries skincare, '
      'makeup, haircare, and fragrance from both indie and prestige brands.',
  avgOrderValue: 'Rs 4,299.50',
  successRate: '94%',
  products: const [
    BrandProduct(
      name: 'Rare Beauty Soft Pinch Blush',
      price: 'Rs 3,500',
      sales: 312,
      thumbnailColor: Color(0xFFE91E63),
      thumbnailIcon: Icons.face_retouching_natural_rounded,
    ),
    BrandProduct(
      name: 'Charlotte Tilbury Flawless Filter',
      price: 'Rs 6,800',
      sales: 289,
      thumbnailColor: Color(0xFFFF8F00),
      thumbnailIcon: Icons.auto_awesome_rounded,
    ),
    BrandProduct(
      name: 'NARS Radiant Creamy Concealer',
      price: 'Rs 4,200',
      sales: 265,
      thumbnailColor: Color(0xFF4A148C),
      thumbnailIcon: Icons.brush_rounded,
    ),
    BrandProduct(
      name: 'Drunk Elephant Protini Polypeptide Cream',
      price: 'Rs 9,500',
      sales: 198,
      thumbnailColor: Color(0xFF00796B),
      thumbnailIcon: Icons.spa_rounded,
    ),
  ],
);

final _pumaData = BrandInfoData(
  name: 'Puma',
  logo: const _CircleLogo(
    bg: Colors.black,
    child: Center(
      child: Icon(Icons.directions_run_rounded, color: Colors.white, size: 22),
    ),
  ),
  stars: 5.0,
  category: 'Fitness & Sports',
  commission: '10-20%',
  description:
      'PUMA is one of the world\'s leading sports brands, designing and '
      'developing footwear, apparel, and accessories. PUMA collaborates with '
      'renowned designers and brands to bring sport inspiration into street culture.',
  avgOrderValue: 'Rs 8,450.00',
  successRate: '91%',
  products: const [
    BrandProduct(
      name: 'PUMA RS-X Reinvention Sneakers',
      price: 'Rs 14,000',
      sales: 198,
      thumbnailColor: Color(0xFF212121),
      thumbnailIcon: Icons.directions_run_rounded,
    ),
    BrandProduct(
      name: 'PUMA Evolve Court Slide Sandals',
      price: 'Rs 5,500',
      sales: 176,
      thumbnailColor: Color(0xFF455A64),
      thumbnailIcon: Icons.beach_access_rounded,
    ),
    BrandProduct(
      name: 'PUMA Better Foam Emerge Running Shoes',
      price: 'Rs 12,500',
      sales: 154,
      thumbnailColor: Color(0xFF880E4F),
      thumbnailIcon: Icons.sports_score_rounded,
    ),
    BrandProduct(
      name: 'PUMA Men\'s Essential Logo Tee',
      price: 'Rs 3,200',
      sales: 132,
      thumbnailColor: Color(0xFF1B5E20),
      thumbnailIcon: Icons.checkroom_rounded,
    ),
  ],
);

final _kharayoData = BrandInfoData(
  name: 'Kharayo Bakes',
  logo: const _CircleLogo(
    bg: Color(0xFF8B1A1A),
    child: Center(
      child: Text(
        'K',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 18,
        ),
      ),
    ),
  ),
  stars: 4.8,
  category: 'Food',
  commission: '8-12%',
  description:
      'Kharayo Bakes is a premium artisan bakery brand offering handcrafted '
      'pastries, cakes, and desserts made from locally sourced ingredients. '
      'Known for quality and taste, they deliver across major cities.',
  avgOrderValue: 'Rs 1,850.00',
  successRate: '88%',
  products: const [
    BrandProduct(
      name: 'Classic Butter Croissant Box (6 pcs)',
      price: 'Rs 1,200',
      sales: 432,
      thumbnailColor: Color(0xFFBF360C),
      thumbnailIcon: Icons.bakery_dining_rounded,
    ),
    BrandProduct(
      name: 'Dark Chocolate Truffle Cake (1 kg)',
      price: 'Rs 3,500',
      sales: 287,
      thumbnailColor: Color(0xFF4E342E),
      thumbnailIcon: Icons.cake_rounded,
    ),
    BrandProduct(
      name: 'Strawberry Cheesecake Slice',
      price: 'Rs 850',
      sales: 356,
      thumbnailColor: Color(0xFFC62828),
      thumbnailIcon: Icons.favorite_rounded,
    ),
    BrandProduct(
      name: 'Assorted Macaron Gift Box',
      price: 'Rs 2,200',
      sales: 213,
      thumbnailColor: Color(0xFFAD1457),
      thumbnailIcon: Icons.redeem_rounded,
    ),
  ],
);

final _ultimateData = BrandInfoData(
  name: 'Ultimate Lifestyle',
  logo: const _CircleLogo(
    bg: Color(0xFF1C1C2E),
    child: Center(
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
  ),
  stars: 4.7,
  category: 'Tech',
  commission: '15-20%',
  description:
      'Ultimate Lifestyle curates premium tech accessories and smart home '
      'products designed to elevate everyday living. From wireless audio to '
      'minimalist gadgets, every product is built for the modern consumer.',
  avgOrderValue: 'Rs 7,320.00',
  successRate: '85%',
  products: const [
    BrandProduct(
      name: 'UL Pro Wireless Earbuds',
      price: 'Rs 8,500',
      sales: 189,
      thumbnailColor: Color(0xFF1A237E),
      thumbnailIcon: Icons.headphones_rounded,
    ),
    BrandProduct(
      name: 'Minimalist Leather Wallet with Tracker',
      price: 'Rs 4,200',
      sales: 165,
      thumbnailColor: Color(0xFF37474F),
      thumbnailIcon: Icons.account_balance_wallet_rounded,
    ),
    BrandProduct(
      name: 'Portable MagSafe Charger 10000mAh',
      price: 'Rs 6,800',
      sales: 143,
      thumbnailColor: Color(0xFF004D40),
      thumbnailIcon: Icons.battery_charging_full_rounded,
    ),
    BrandProduct(
      name: 'Smart LED Desk Lamp',
      price: 'Rs 5,500',
      sales: 121,
      thumbnailColor: Color(0xFF4A148C),
      thumbnailIcon: Icons.lightbulb_rounded,
    ),
  ],
);

final _zaraData = BrandInfoData(
  name: 'Zara Clothing',
  logo: const _CircleLogo(
    bg: Colors.white,
    child: Center(
      child: Text(
        'ZARA',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 8,
          letterSpacing: 1,
        ),
      ),
    ),
  ),
  stars: 4.7,
  category: 'Fashion',
  commission: '12-18%',
  description:
      'Zara is a global fashion retailer renowned for its fast-fashion model, '
      'delivering new collections to stores twice a week. Part of the Inditex '
      'group, Zara blends runway trends with accessible everyday style.',
  avgOrderValue: 'Rs 5,600.00',
  successRate: '89%',
  products: const [
    BrandProduct(
      name: 'Oversized Blazer with Belt',
      price: 'Rs 9,990',
      sales: 243,
      thumbnailColor: Color(0xFF212121),
      thumbnailIcon: Icons.checkroom_rounded,
    ),
    BrandProduct(
      name: 'Wide Leg Trousers',
      price: 'Rs 5,990',
      sales: 198,
      thumbnailColor: Color(0xFF37474F),
      thumbnailIcon: Icons.accessibility_new_rounded,
    ),
    BrandProduct(
      name: 'Floral Print Midi Dress',
      price: 'Rs 7,490',
      sales: 176,
      thumbnailColor: Color(0xFFAD1457),
      thumbnailIcon: Icons.dry_cleaning_rounded,
    ),
    BrandProduct(
      name: 'Leather Crossbody Bag',
      price: 'Rs 11,990',
      sales: 142,
      thumbnailColor: Color(0xFF4E342E),
      thumbnailIcon: Icons.shopping_bag_rounded,
    ),
  ],
);

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  int _selectedFilter = 0;

  static const _filters = [
    'All',
    'Fashion',
    'Accessories',
    'Sports',
    'Fitness',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      bottomNavigationBar: const _BrandsBottomNav(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: DesignTokens.s20),
              const Text(
                'Brand Partnerships',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              _buildStatCards(),
              const SizedBox(height: DesignTokens.s24),
              _SectionTitle('Recommended Brands for You'),
              const SizedBox(height: DesignTokens.s12),
              GestureDetector(
                onTap: () =>
                    context.push(RouteNames.brandInfo, extra: _nikeData),
                child: const _RecommendedCard(
                  logo: _NikeLogo(),
                  name: 'Nike Official Store',
                  stars: 4.9,
                  category: 'Athletic & Sportswear',
                  reason:
                      'We recommended this because it matches your fashion category',
                  commission: '12-20%',
                  products: '234 available',
                  creators: '1,235 active',
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              GestureDetector(
                onTap: () =>
                    context.push(RouteNames.brandInfo, extra: _sephoraData),
                child: const _RecommendedCard(
                  logo: _SephoraLogo(),
                  name: 'Sephora Beauty',
                  stars: 5.0,
                  category: 'Beauty & Cosmetic',
                  reason:
                      'We recommended this because there is high conversion in Beauty Products',
                  commission: '15-25%',
                  products: '567 available',
                  creators: '892 active',
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              _SectionTitle('Browse all Brands'),
              const SizedBox(height: DesignTokens.s12),
              _FilterChipsRow(
                filters: _filters,
                selected: _selectedFilter,
                onSelect: (i) => setState(() => _selectedFilter = i),
              ),
              const SizedBox(height: DesignTokens.s16),
              GestureDetector(
                onTap: () =>
                    context.push(RouteNames.brandInfo, extra: _pumaData),
                child: const _BrandRow(
                  logo: _CircleLogo(
                    bg: Colors.black,
                    child: Center(
                      child: Icon(
                        Icons.directions_run_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  name: 'Puma',
                  stars: 5.0,
                  category: 'Fitness & Sports',
                  commission: '10-20% Commissions',
                ),
              ),
              GestureDetector(
                onTap: () =>
                    context.push(RouteNames.brandInfo, extra: _kharayoData),
                child: const _BrandRow(
                  logo: _CircleLogo(
                    bg: Color(0xFF8B1A1A),
                    child: Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  name: 'Kharayo Bakes',
                  stars: 4.8,
                  category: 'Food',
                  commission: '8-12% Commissions',
                ),
              ),
              GestureDetector(
                onTap: () =>
                    context.push(RouteNames.brandInfo, extra: _ultimateData),
                child: const _BrandRow(
                  logo: _CircleLogo(
                    bg: Color(0xFF1C1C2E),
                    child: Center(
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
                  ),
                  name: 'Ultimate Lifestyle',
                  stars: 4.7,
                  category: 'Tech',
                  commission: '15-20% Commissions',
                ),
              ),
              GestureDetector(
                onTap: () =>
                    context.push(RouteNames.brandInfo, extra: _zaraData),
                child: const _BrandRow(
                  logo: _CircleLogo(
                    bg: Colors.white,
                    child: Center(
                      child: Text(
                        'ZARA',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 8,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  name: 'Zara Clothing',
                  stars: 4.7,
                  category: 'Fashion',
                  commission: '12-18% Commissions',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Consumer(
          builder: (_, ref, __) {
            final path = ref.watch(avatarImagePathProvider);
            return ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: path != null
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : Container(
                        color: DesignTokens.bgAppBodyLight,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_rounded,
                            size: 22, color: DesignTokens.textMuted),
                      ),
              ),
            );
          },
        ),
        const Spacer(),
        _IconBtn(icon: Icons.search_rounded),
        const SizedBox(width: DesignTokens.s8),
        _IconBtn(icon: Icons.notifications_none_rounded),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(RouteNames.activePartnerships),
            child: const _StatSummaryCard(
              bg: DesignTokens.primaryGreen,
              iconBg: Color(0xFF27AE60),
              imagePath: 'assets/images/creatordash/Partnership.png',
              label: 'Active Partnerships',
              value: '3',
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(RouteNames.partnershipRequests),
            child: const _StatSummaryCard(
              bg: DesignTokens.bgAppBody,
              iconBg: DesignTokens.bgAppBodyLight,
              imagePath: 'assets/images/creatordash/Pending.png',
              label: 'Pending Requests',
              value: '2',
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textWhite,
      ),
    );
  }
}

// ── Top-bar icon button ───────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: DesignTokens.textLight),
    );
  }
}

// ── Stat summary card (Active / Pending) ──────────────────────────────────────

class _StatSummaryCard extends StatelessWidget {
  const _StatSummaryCard({
    required this.bg,
    required this.iconBg,
    required this.label,
    required this.value,
    this.icon,
    this.imagePath,
  });

  final Color bg;
  final Color iconBg;
  final IconData? icon;
  final String label;
  final String value;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: imagePath != null ? Colors.transparent : iconBg,
                  shape: BoxShape.circle,
                ),
                child: imagePath != null
                    ? Image.asset(
                        imagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : Icon(icon, size: 20, color: Colors.white),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 18,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommended brand card ────────────────────────────────────────────────────

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard({
    required this.logo,
    required this.name,
    required this.stars,
    required this.category,
    required this.reason,
    required this.commission,
    required this.products,
    required this.creators,
  });

  final Widget logo;
  final String name;
  final double stars;
  final String category;
  final String reason;
  final String commission;
  final String products;
  final String creators;

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
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: DesignTokens.secondaryYellow,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${stars.toStringAsFixed(1)} Stars',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.secondaryYellow,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• $category',
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
          const SizedBox(height: DesignTokens.s12),
          Text(
            reason,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          const _DashedDivider(),
          const SizedBox(height: DesignTokens.s12),
          _MetricRow(
            icon: Icons.monetization_on_outlined,
            label: 'Commission Range',
            trailing: _CommissionChip(commission),
          ),
          const SizedBox(height: DesignTokens.s8),
          _MetricRow(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            trailingText: products,
          ),
          const SizedBox(height: DesignTokens.s8),
          _MetricRow(
            icon: Icons.people_outline_rounded,
            label: 'Creators',
            trailingText: creators,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.trailingText,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final String? trailingText;

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
        if (trailing != null) trailing!,
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
      ],
    );
  }
}

class _CommissionChip extends StatelessWidget {
  const _CommissionChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreenLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.primaryGreen, width: 0.8),
      ),
      child: Text(
        label,
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

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (i) {
          final active = i == selected;
          return Padding(
            padding: EdgeInsets.only(right: i < filters.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? DesignTokens.primaryGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? DesignTokens.primaryGreen
                        : DesignTokens.borderDefault,
                  ),
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : DesignTokens.textMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Browse brand row ──────────────────────────────────────────────────────────

class _BrandRow extends StatelessWidget {
  const _BrandRow({
    required this.logo,
    required this.name,
    required this.stars,
    required this.category,
    required this.commission,
  });

  final Widget logo;
  final String name;
  final double stars;
  final String category;
  final String commission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.s12,
        horizontal: DesignTokens.s4,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: DesignTokens.borderDefault, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 46, height: 46, child: logo),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: DesignTokens.secondaryYellow,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${stars.toStringAsFixed(1)} Stars',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.secondaryYellow,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• $category',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  commission,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: DesignTokens.textMuted,
          ),
        ],
      ),
    );
  }
}

// ── Brand logo helpers ────────────────────────────────────────────────────────

class _CircleLogo extends StatelessWidget {
  const _CircleLogo({required this.bg, required this.child});
  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: child,
    );
  }
}

class _NikeLogo extends StatelessWidget {
  const _NikeLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '✓',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _SephoraLogo extends StatelessWidget {
  const _SephoraLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
          child: const Center(
            child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BrandsBottomNav extends StatelessWidget {
  const _BrandsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => context.go(RouteNames.creatorHome),
          ),
          _NavBtn(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            onTap: () => context.push(RouteNames.creatorAnalytics),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.reelImport),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: DesignTokens.primaryGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          _NavBtn(
            icon: Icons.storefront_outlined,
            label: 'Brands',
            active: true,
            onTap: null,
          ),
          _NavBtn(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () => context.push(
              RouteNames.creatorProfile.replaceFirst(':accountId', 'me'),
              extra: const CreatorProfileArgs(
                accountId: 'me',
                displayName: 'Danny Perierra',
                handle: '@wandererperierra',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? DesignTokens.primaryGreen : DesignTokens.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
