import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/mock_cart_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/mock_product_catalogue.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

/// Static discovery repository — no API calls.
/// Serves PDP, related products, and add-to-cart from [kMockProductCatalogue].
class MockDiscoveryRepository implements DiscoveryRepository {
  final _saved = <String>{};

  @override
  Future<Either<NetworkExceptions, DiscoverData>> getDiscoverData() async {
    await _delay();
    return right(DiscoverData(
      popularSearches: ['#Skincare', '#Linen', '#Fitness', '#TechGadgets'],
      categories: const [
        DiscoverCategory(id: 'c1', label: 'Skincare', emoji: '✨'),
        DiscoverCategory(id: 'c2', label: 'Fashion', emoji: '👗'),
        DiscoverCategory(id: 'c3', label: 'Fitness', emoji: '💪'),
        DiscoverCategory(id: 'c4', label: 'Tech', emoji: '🔌'),
      ],
      trending: kMockProductCatalogue.values
          .take(4)
          .map((p) => TrendingProduct(
                id: p.id,
                name: p.name,
                imageUrl: p.images.first,
                price: p.price,
                rating: p.rating,
                soldToday: (p.soldCount * 0.03).round(),
              ))
          .toList(),
      topCreators: const [],
    ));
  }

  @override
  Future<Either<NetworkExceptions, ProductDetail>> getProductDetail(
    String productId,
  ) async {
    await _delay();
    final product = kMockProductCatalogue[productId];
    if (product == null) return left(const NetworkExceptions.notFound());
    // Reflect live saved / in-cart state.
    return right(product.copyWith(
      isSaved: _saved.contains(productId),
      isInCart: MockCartStore.instance.items.any((i) => i.productId == productId),
    ));
  }

  @override
  Future<Either<NetworkExceptions, PagedResult<ProductReviewPreview>>>
      getProductReviews(
    String productId, {
    int limit = 10,
    String? cursor,
  }) async {
    await _delay();
    return right(const PagedResult(
      items: [],
      totalCount: 0,
      pageSize: 10,
      hasMore: false,
    ));
  }

  @override
  Future<Either<NetworkExceptions, List<RelatedProduct>>> getRelatedProducts(
    String productId,
  ) async {
    await _delay();
    return right(kRelatedFor(productId));
  }

  @override
  Future<Either<NetworkExceptions, Unit>> addToCart({
    required String productId,
    required int qty,
    String? variantId,
  }) async {
    await _delay(ms: 400);
    final product = kMockProductCatalogue[productId];
    if (product == null) return left(const NetworkExceptions.notFound());
    MockCartStore.instance.addOrIncrement(
      productId: productId,
      productName: product.name,
      imageUrl: product.images.first,
      price: product.price,
      quantity: qty,
    );
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, bool>> toggleSaved(
    String productId,
  ) async {
    await _delay(ms: 300);
    final isSaved = _saved.contains(productId);
    if (isSaved) {
      _saved.remove(productId);
    } else {
      _saved.add(productId);
    }
    return right(!isSaved);
  }

  Future<void> _delay({int ms = 500}) =>
      Future<void>.delayed(Duration(milliseconds: ms));
}

