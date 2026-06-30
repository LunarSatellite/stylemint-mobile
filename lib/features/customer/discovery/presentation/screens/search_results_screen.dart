import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_creator_card.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── MOCK DATA ────────────────────────────────────────────────────────────────

class _MockProduct {
  const _MockProduct({
    required this.name,
    required this.price,
    required this.rating,
    this.imageColor = const Color(0xFF27272A),
  });

  final String name;
  final String price;
  final double rating;
  final Color imageColor;
}

class _MockBrand {
  const _MockBrand({
    required this.name,
    required this.category,
    required this.rating,
    required this.productCount,
    required this.logoColor,
    required this.logoText,
  });

  final String name;
  final String category;
  final double rating;
  final int productCount;
  final Color logoColor;
  final String logoText;
}

// Nike-specific results
const _nikeProducts = [
  _MockProduct(name: 'Nike Air Jordan Travis Scott Limited Edition', price: 'Rs 25,000', rating: 4.9, imageColor: Color(0xFF3A3A3A)),
  _MockProduct(name: 'Nike Air Max 2025', price: 'Rs 18,000', rating: 4.9, imageColor: Color(0xFFB71C1C)),
  _MockProduct(name: 'Nike Air Jordan 6 Retro Low', price: 'Rs 32,000', rating: 4.0, imageColor: Color(0xFF1C1C1C)),
  _MockProduct(name: 'Nike Air Force 1 \'07 LV8', price: 'Rs 14,500', rating: 4.7, imageColor: Color(0xFFECEFF1)),
  _MockProduct(name: 'Air Jordan 1 Low SE', price: 'Rs 12,000', rating: 5.0, imageColor: Color(0xFFD7CCC8)),
  _MockProduct(name: 'Jordan Spizike Low SE', price: 'Rs 17,500', rating: 3.2, imageColor: Color(0xFF3E2723)),
];

const _nikeBrands = [
  _MockBrand(name: 'Nike', category: 'Fitness & Sports', rating: 5.0, productCount: 345, logoColor: Color(0xFF000000), logoText: '✓'),
  _MockBrand(name: 'Jordan Brand', category: 'Footwear & Apparel', rating: 4.9, productCount: 128, logoColor: Color(0xFF212121), logoText: '✈'),
];

final _nikeCreators = [
  DiscoverCreator(id: 'cr1', name: 'Air Nomad', handle: '@immovableroyale', avatarUrl: '', category: 'Travel, Fitness & Sports', description: '', rating: 4.0, followers: 101000, isFollowing: true),
  DiscoverCreator(id: 'cr2', name: 'Sneaker King', handle: '@sneakerking_np', avatarUrl: '', category: 'Sneakers & Streetwear', description: '', rating: 4.8, followers: 243000, isFollowing: false),
];

final _nikeReelViews = ['12.3m', '408k', '1.5m', '989k', '2.1m', '845k'];
final _nikeReelColors = [
  const Color(0xFF263238),
  const Color(0xFFB71C1C),
  const Color(0xFF1A237E),
  const Color(0xFF1B5E20),
  const Color(0xFF37474F),
  const Color(0xFF4A148C),
];

// Generic fallback results
const _genericProducts = [
  _MockProduct(name: 'StyleMint Tote Bag — Black Edition', price: 'Rs 1,500', rating: 4.6, imageColor: Color(0xFF212121)),
  _MockProduct(name: 'Oversized Linen Shirt — White / M', price: 'Rs 2,200', rating: 4.3, imageColor: Color(0xFFECEFF1)),
  _MockProduct(name: 'MetaQuest 3 Pro 2026 VR Headset', price: 'Rs 1,35,000', rating: 4.4, imageColor: Color(0xFF37474F)),
  _MockProduct(name: 'HyperX Black Stealth Pro Gaming Headset', price: 'Rs 5,000', rating: 4.6, imageColor: Color(0xFF1C1C1C)),
];

const _genericBrands = [
  _MockBrand(name: 'StyleMint', category: 'Fashion & Lifestyle', rating: 4.7, productCount: 210, logoColor: Color(0xFF2ECC71), logoText: 'SM'),
  _MockBrand(name: 'TechVault', category: 'Electronics & Gadgets', rating: 4.5, productCount: 95, logoColor: Color(0xFF1565C0), logoText: 'TV'),
];

final _genericCreators = [
  DiscoverCreator(id: 'gc1', name: 'Shree Teen', handle: '@alieen.ace43', avatarUrl: '', category: 'Travel & Skincare', description: '', rating: 4.9, followers: 52300, isFollowing: false),
  DiscoverCreator(id: 'gc2', name: 'Immovable Royale', handle: '@immovableroyale', avatarUrl: '', category: 'Beauty, Skincare & Wellness', description: '', rating: 4.0, followers: 101000, isFollowing: true),
];

// Returns Nike data when query contains "nike", generic data otherwise.
bool _isNikeQuery(String q) => q.toLowerCase().contains('nike');

List<_MockProduct> _productsFor(String q) => _isNikeQuery(q) ? _nikeProducts : _genericProducts;
List<_MockBrand> _brandsFor(String q) => _isNikeQuery(q) ? _nikeBrands : _genericBrands;
List<DiscoverCreator> _creatorsFor(String q) => _isNikeQuery(q) ? _nikeCreators : _genericCreators;
List<String> _reelViewsFor(String q) => _nikeReelViews; // same layout, different vibe
List<Color> _reelColorsFor(String q) => _nikeReelColors;
int _resultCountFor(String q) => _isNikeQuery(q) ? 142 : 38;

// ─── SEARCH RESULTS SCREEN ────────────────────────────────────────────────────
class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Search Results', style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Result count subtitle
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              'Showing ${_resultCountFor(widget.query)} results for "${widget.query}"',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 13,
              ),
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: DesignTokens.primaryGreen,
            unselectedLabelColor: DesignTokens.textMuted,
            indicatorColor: DesignTokens.primaryGreen,
            indicatorWeight: 2,
            dividerColor: DesignTokens.borderDefault,
            labelStyle: DesignTokens.smallRegular.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: DesignTokens.smallRegular.copyWith(fontSize: 14),
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Creators'),
              Tab(text: 'Reels'),
              Tab(text: 'Brands'),
            ],
          ),

          // Sort By pill + tab content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: _SortByPill(),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProductsTab(products: _productsFor(widget.query)),
                      _CreatorsTab(creators: _creatorsFor(widget.query)),
                      _ReelsTab(views: _reelViewsFor(widget.query), colors: _reelColorsFor(widget.query)),
                      _BrandsTab(brands: _brandsFor(widget.query)),
                    ],
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

// ─── SORT BY PILL ─────────────────────────────────────────────────────────────
class _SortByPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // ponytail: no sort sheet yet
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort By',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: DesignTokens.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── PRODUCTS TAB ─────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products});
  final List<_MockProduct> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, i) => _ProductResultTile(product: products[i]),
    );
  }
}

class _ProductResultTile extends StatelessWidget {
  const _ProductResultTile({required this.product});

  final _MockProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: product.imageColor,
              child: const Icon(Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight, size: 22),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      product.price,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded,
                        size: 14, color: DesignTokens.secondaryYellow),
                    const SizedBox(width: 3),
                    Text(
                      '${product.rating.toStringAsFixed(1)} Stars',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Save for later',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Cart icon
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Icon(
              Icons.shopping_cart_outlined,
              color: DesignTokens.textMuted,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CREATORS TAB ─────────────────────────────────────────────────────────────
class _CreatorsTab extends StatelessWidget {
  const _CreatorsTab({required this.creators});
  final List<DiscoverCreator> creators;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: creators.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => DiscoverCreatorCard(creator: creators[i]),
    );
  }
}

// ─── REELS TAB ────────────────────────────────────────────────────────────────
class _ReelsTab extends StatelessWidget {
  const _ReelsTab({required this.views, required this.colors});
  final List<String> views;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.85,
      ),
      itemCount: views.length,
      itemBuilder: (_, i) => _ReelThumbnail(
        views: views[i],
        color: colors[i % colors.length],
      ),
    );
  }
}

class _ReelThumbnail extends StatelessWidget {
  const _ReelThumbnail({required this.views, required this.color});

  final String views;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: color),
        Positioned(
          bottom: 8,
          left: 8,
          child: Row(
            children: [
              const Icon(Icons.remove_red_eye_outlined,
                  size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                views,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── BRANDS TAB ───────────────────────────────────────────────────────────────
class _BrandsTab extends StatelessWidget {
  const _BrandsTab({required this.brands});
  final List<_MockBrand> brands;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: brands.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, i) => _BrandResultTile(brand: brands[i]),
    );
  }
}

class _BrandResultTile extends StatelessWidget {
  const _BrandResultTile({required this.brand});

  final _MockBrand brand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              brand.logoText,
              style: TextStyle(
                color: brand.logoColor,
                fontWeight: FontWeight.w900,
                fontSize: brand.logoText.length == 1 ? 22 : 14,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + rating + product count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand.name,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: DesignTokens.secondaryYellow),
                    const SizedBox(width: 3),
                    Text(
                      '${brand.rating.toStringAsFixed(1)} Stars',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ' • ${brand.category}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${brand.productCount} Products',
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFF4FC3F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right_rounded, color: DesignTokens.iconLight),
        ],
      ),
    );
  }
}
