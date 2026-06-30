import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/trending_product_card.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Static mock products shared by both Trending and Category screens.
final _trendingProducts = [
  TrendingProduct(
    id: 'pt1',
    name: 'Cera Ve Alpine Apple Berry Foaming Face Wash',
    imageUrl: '',
    price: const Money(amount: 5000, currency: 'NPR'),
    rating: 5.0,
    soldToday: 1500,
  ),
  TrendingProduct(
    id: 'pt2',
    name: 'Nike Air Jordan Travis Scott Limited Edition',
    imageUrl: '',
    price: const Money(amount: 25000, currency: 'NPR'),
    rating: 4.8,
    soldToday: 800,
  ),
  TrendingProduct(
    id: 'pt3',
    name: 'MetaQuest 3 Pro 2026 VR Headset',
    imageUrl: '',
    price: const Money(amount: 135000, currency: 'NPR'),
    rating: 4.4,
    soldToday: 156,
  ),
  TrendingProduct(
    id: 'pt4',
    name: 'Winter Long Puffer Jackets',
    imageUrl: '',
    price: const Money(amount: 5000, currency: 'NPR'),
    rating: 4.5,
    soldToday: 89,
  ),
  TrendingProduct(
    id: 'pt5',
    name: 'HyperX Black Stealth Pro Gaming Headset',
    imageUrl: '',
    price: const Money(amount: 5000, currency: 'NPR'),
    rating: 4.6,
    soldToday: 80,
  ),
  TrendingProduct(
    id: 'pt6',
    name: 'Think! High Protein Organic Fiber Rich Bar',
    imageUrl: '',
    price: const Money(amount: 5000, currency: 'NPR'),
    rating: 5.0,
    soldToday: 77,
  ),
  TrendingProduct(
    id: 'pt7',
    name: 'Iphone 17 Pro Max Pitaka Copper Brown Case',
    imageUrl: '',
    price: const Money(amount: 5000, currency: 'NPR'),
    rating: 4.9,
    soldToday: 66,
  ),
];

/// Generic product list screen — used for "Trending Products" and
/// "[Category] Products" views.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key, required this.title});

  final String title;

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
        title: Text(title, style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _trendingProducts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => TrendingProductCard(
          product: _trendingProducts[i],
          onTap: () => context.push(
            RouteNames.productDetail.replaceFirst(
                ':productId', _trendingProducts[i].id),
          ),
        ),
      ),
    );
  }
}
