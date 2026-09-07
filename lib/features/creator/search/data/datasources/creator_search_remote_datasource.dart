import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/data/models/creator_search_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';

/// GET /api/v1/customer/search?type=brands|products|creators — the same
/// real Discovery search endpoint every account type uses (a creator is
/// still a Customer role-profile on the same Account per the multi-role
/// model), just scoped to what a creator actually searches for: brands to
/// pitch/partner with, products to make content about, or other creators.
class CreatorSearchRemoteDataSource {
  CreatorSearchRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _typeNames = {
    CreatorSearchType.brands: 'brands',
    CreatorSearchType.products: 'products',
    CreatorSearchType.creators: 'creators',
  };

  Future<List<SearchBrandResultDto>> searchBrands(String query) async {
    final m = await _search(query, CreatorSearchType.brands);
    return _listOf(m, 'brands', SearchBrandResultDto.fromJson);
  }

  Future<List<SearchProductResultDto>> searchProducts(String query) async {
    final m = await _search(query, CreatorSearchType.products);
    return _listOf(m, 'products', SearchProductResultDto.fromJson);
  }

  Future<List<SearchCreatorResultDto>> searchCreators(String query) async {
    final m = await _search(query, CreatorSearchType.creators);
    return _listOf(m, 'creators', SearchCreatorResultDto.fromJson);
  }

  Future<Map<String, dynamic>> _search(String query, CreatorSearchType type) async {
    final response = await apiClient.get(
      '/api/v1/customer/search',
      queryParameters: {
        'q': query,
        'type': _typeNames[type],
        'limit': 20,
      },
    );
    return response as Map<String, dynamic>;
  }

  List<T> _listOf<T>(
    Map<String, dynamic> envelope,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      (envelope[key] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(growable: false);
}
