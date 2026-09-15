import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/repositories/vendor_codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/print/shelf_card_pdf.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/repositories/vendor_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';

/// Shelf cards for every active product code in [store], for "Print all
/// shelf cards". `CodeVm` carries no price, so prices come from the vendor's
/// product list; a product that isn't found there prints without one.
Future<Either<NetworkExceptions, List<ShelfCardData>>> loadStoreShelfCards({
  required VendorCodesRepository codes,
  required VendorProductsRepository products,
  required VendorStore store,
}) async {
  final listed = await codes.listStoreCodes(
    store.id,
    kind: CodeKind.productTag,
  );
  final all = listed.getRight().toNullable();
  if (all == null) {
    return left(
      listed.getLeft().getOrElse(
        () => const NetworkExceptions.unexpectedError(),
      ),
    );
  }
  final active = all
      .where((code) => code.isActive && code.kind == CodeKind.productTag)
      .toList(growable: false);
  if (active.isEmpty) return right(const <ShelfCardData>[]);

  final byId = await _productsById(products);
  final cards = <ShelfCardData>[];
  for (final code in active) {
    final product = byId[code.productId];
    cards.add(
      ShelfCardData(
        title: code.productName ?? product?.name ?? 'StyleMint product',
        url: code.url,
        code: code.code,
        storeName: store.name,
        storeCity: store.city,
        price: product == null ? null : formatMoney(product.price),
      ),
    );
  }
  return right(cards);
}

/// The vendor's products by id, best effort: a failed page stops the walk
/// and the cards print with whatever was found.
Future<Map<String, VendorProduct>> _productsById(
  VendorProductsRepository repository,
) async {
  const pageSize = 50;
  const maxPages = 10;
  final byId = <String, VendorProduct>{};
  String? cursor;
  for (var page = 0; page < maxPages; page++) {
    final result = await repository.getProducts(
      limit: pageSize,
      cursor: cursor,
    );
    final paged = result.getRight().toNullable();
    if (paged == null) break;
    for (final product in paged.items) {
      byId[product.id] = product;
    }
    final next = paged.nextCursor;
    if (!paged.hasMore || next == null) break;
    cursor = next;
  }
  return byId;
}
