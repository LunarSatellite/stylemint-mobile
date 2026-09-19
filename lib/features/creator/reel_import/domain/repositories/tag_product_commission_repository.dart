import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';

/// The real commission terms for the products on screen.
///
/// Its own port rather than another method on `ReelImportRepository`: this is
/// a read about partnership terms, not about importing a reel, and the
/// screens that draw it can fail to load it without the import flow failing.
// A port, not a callback: it is overridden wholesale in tests and named so
// the data layer has something to implement.
// ignore: one_member_abstracts
abstract interface class TagProductCommissionRepository {
  /// `GET /v1/creator/tag-products/commission?productIds=…`.
  ///
  /// **Batched deliberately.** The endpoint takes up to 50 ids per call and
  /// exists so a list of products costs one request instead of one per card;
  /// implementations chunk rather than issue a call per product.
  ///
  /// The creator is taken from the bearer token. No partnership id is ever
  /// sent as proof of membership.
  ///
  /// Returns the answers keyed by product id. A product the server did not
  /// answer for is simply absent from the map — and absent means nothing is
  /// drawn for it, not that it earns nothing.
  Future<Either<NetworkExceptions, Map<String, TagProductCommission>>>
  getCommissions(List<String> productIds);
}
