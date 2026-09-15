import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

/// Discover-tab reads and feedback. Home and product listings come from the
/// Mall repositories.
abstract interface class DiscoverRepository {
  /// `GET api/v1/public/search/suggest`. [query] must already be normalized
  /// and at least [minSuggestQueryLength] long; a shorter one is 400
  /// `validation.too_short`.
  Future<Either<NetworkExceptions, SearchSuggestions>> suggest(
    String query, {
    int limit,
  });

  /// `GET v1/public/collections` — every published collection, paged.
  Future<Either<NetworkExceptions, CatalogPage<HomeCollection>>>
  getCollections({String? cursor, int pageSize});

  /// `POST api/v1/customer/feed/not-interested`.
  Future<Either<NetworkExceptions, Unit>> markNotInterested(
    NotInterestedTarget target, {
    String? reason,
  });

  /// `DELETE api/v1/customer/feed/not-interested/{targetKind}/{targetId}`.
  Future<Either<NetworkExceptions, Unit>> undoNotInterested(
    NotInterestedTarget target,
  );

  /// `GET api/v1/customer/feed/not-interested`, newest first.
  Future<Either<NetworkExceptions, List<NotInterestedSignal>>>
  getNotInterested();

  /// `POST v1/customer/reels/{reelId}/report`.
  Future<Either<NetworkExceptions, Unit>> reportReel(
    String reelId,
    ReelReportReason reason,
  );
}
