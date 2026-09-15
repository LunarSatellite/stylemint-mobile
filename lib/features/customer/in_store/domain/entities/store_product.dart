import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// One product on a store's "Shop this store" grid: what its card shows.
class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl = '',
  });

  final String id;
  final String name;

  /// The sale price while a flash sale runs, else the default option's price.
  final Money price;

  /// The product's main photo, or `''` when it has none.
  final String imageUrl;
}

/// One page of a vendor's products; `nextCursor` is null on the last page.
typedef StoreProductsPage = ({
  List<StoreProduct> products,
  String? nextCursor,
});
