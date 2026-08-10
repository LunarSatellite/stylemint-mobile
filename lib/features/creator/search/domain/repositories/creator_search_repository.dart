import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';

/// Type-scoped search for the creator-facing search screen: brands to pitch or
/// partner with, products to make content about, and other creators.
abstract interface class CreatorSearchRepository {
  Future<NetworkEither<List<SearchBrandResult>>> searchBrands(String query);

  Future<NetworkEither<List<SearchProductResult>>> searchProducts(String query);

  Future<NetworkEither<List<SearchCreatorResult>>> searchCreators(String query);
}
