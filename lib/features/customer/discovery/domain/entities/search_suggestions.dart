import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Suggest queries shorter than this (after [normalizeSuggestQuery]) are
/// never sent: the server answers them with 400 `validation.too_short`.
const int minSuggestQueryLength = 2;

/// [raw] as the server normalizes it: trimmed, one leading `#` removed,
/// inner whitespace collapsed to one space, lower-cased.
String normalizeSuggestQuery(String raw) {
  var text = raw.trim();
  if (text.startsWith('#')) text = text.substring(1).trim();
  return text.replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

/// Typeahead suggestions (`GET api/v1/public/search/suggest`), grouped by
/// kind. Every group is present, possibly empty.
class SearchSuggestions {
  const SearchSuggestions({
    required this.query,
    this.products = const [],
    this.brands = const [],
    this.creators = const [],
    this.categories = const [],
    this.hashtags = const [],
  });

  /// The normalized query the server answered.
  final String query;
  final List<SuggestedProduct> products;
  final List<SuggestedBrand> brands;
  final List<SuggestedCreator> creators;
  final List<SuggestedCategory> categories;
  final List<SuggestedHashtag> hashtags;

  bool get isEmpty =>
      products.isEmpty &&
      brands.isEmpty &&
      creators.isEmpty &&
      categories.isEmpty &&
      hashtags.isEmpty;
}

class SuggestedProduct {
  const SuggestedProduct({
    required this.id,
    required this.name,
    this.imageUrl,
    this.price,
  });

  final String id;
  final String name;
  final String? imageUrl;

  /// Not sent by the server today; shown when a later version adds it.
  final Money? price;
}

class SuggestedBrand {
  const SuggestedBrand({
    required this.vendorAccountId,
    required this.name,
    this.logoUrl,
    this.isVerified = false,
  });

  final String vendorAccountId;
  final String name;
  final String? logoUrl;
  final bool isVerified;
}

class SuggestedCreator {
  const SuggestedCreator({
    required this.accountId,
    required this.displayName,
    this.handle,
    this.avatarUrl,
    this.isVerified = false,
  });

  final String accountId;
  final String displayName;

  /// Without the leading `@`.
  final String? handle;
  final String? avatarUrl;
  final bool isVerified;
}

class SuggestedCategory {
  const SuggestedCategory({required this.id, required this.name, this.slug});

  final String id;
  final String? slug;
  final String name;
}

class SuggestedHashtag {
  const SuggestedHashtag({required this.tag, this.usageCount = 0});

  /// Without the leading `#`.
  final String tag;
  final int usageCount;
}
