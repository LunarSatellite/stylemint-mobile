import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `GET api/v1/public/search/suggest` response. Rows without an id or name
/// are dropped; a missing group reads as empty.
class SearchSuggestionsDto {
  const SearchSuggestionsDto({
    required this.query,
    this.products = const [],
    this.brands = const [],
    this.creators = const [],
    this.categories = const [],
    this.hashtags = const [],
  });

  factory SearchSuggestionsDto.fromJson(Map<String, dynamic> json) =>
      SearchSuggestionsDto(
        query: readString(json['query']),
        products: _objects(json['products']),
        brands: _objects(json['brands']),
        creators: _objects(json['creators']),
        categories: _objects(json['categories']),
        hashtags: _objects(json['hashtags']),
      );

  final String query;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> brands;
  final List<Map<String, dynamic>> creators;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> hashtags;

  SearchSuggestions toDomain() => SearchSuggestions(
    query: query,
    products: [for (final json in products) ?_product(json)],
    brands: [for (final json in brands) ?_brand(json)],
    creators: [for (final json in creators) ?_creator(json)],
    categories: [for (final json in categories) ?_category(json)],
    hashtags: [for (final json in hashtags) ?_hashtag(json)],
  );

  static List<Map<String, dynamic>> _objects(Object? raw) => raw is List
      ? [
          for (final item in raw)
            if (item is Map) Map<String, dynamic>.from(item),
        ]
      : const [];

  static SuggestedProduct? _product(Map<String, dynamic> json) {
    final id = readString(json['id']);
    final name = readString(json['name']);
    if (id.isEmpty || name.isEmpty) return null;
    return SuggestedProduct(
      id: id,
      name: name,
      imageUrl: readOptionalString(json['imageUrl']),
      price: readSuggestMoney(json['price']),
    );
  }

  static SuggestedBrand? _brand(Map<String, dynamic> json) {
    final id = readString(json['vendorAccountId']);
    final name = readString(json['name']);
    if (id.isEmpty || name.isEmpty) return null;
    return SuggestedBrand(
      vendorAccountId: id,
      name: name,
      logoUrl: readOptionalString(json['logoUrl']),
      isVerified: readBool(json['isVerified']),
    );
  }

  static SuggestedCreator? _creator(Map<String, dynamic> json) {
    final id = readString(json['accountId']);
    final handle = readOptionalString(json['handle'])?.replaceFirst('@', '');
    final name = readOptionalString(json['displayName']) ?? handle;
    if (id.isEmpty || name == null || name.isEmpty) return null;
    return SuggestedCreator(
      accountId: id,
      displayName: name,
      handle: handle == null || handle.isEmpty ? null : handle,
      avatarUrl: readOptionalString(json['avatarUrl']),
      isVerified: readBool(json['isVerified']),
    );
  }

  static SuggestedCategory? _category(Map<String, dynamic> json) {
    final id = readString(json['id']);
    final slug = readOptionalString(json['slug']);
    final name = readString(json['name']);
    if ((id.isEmpty && slug == null) || name.isEmpty) return null;
    return SuggestedCategory(id: id, slug: slug, name: name);
  }

  static SuggestedHashtag? _hashtag(Map<String, dynamic> json) {
    final tag = readString(json['tag']).replaceFirst('#', '').trim();
    if (tag.isEmpty) return null;
    final count = readInt(json['usageCount']);
    return SuggestedHashtag(tag: tag, usageCount: count < 0 ? 0 : count);
  }
}

/// A `{amount, currency}` money object, or null.
Money? readSuggestMoney(Object? raw) {
  if (raw is! Map) return null;
  final amount = readOptionalDouble(raw['amount']);
  if (amount == null) return null;
  return Money(
    amount: amount,
    currency: readOptionalString(raw['currency']) ?? 'NPR',
  );
}
