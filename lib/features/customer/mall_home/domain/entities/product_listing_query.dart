import 'package:freezed_annotation/freezed_annotation.dart' show immutable;

/// Sort orders of `GET v1/public/products`.
enum ProductSort {
  newest('newest'),
  bestselling('bestselling'),
  rating('rating'),
  priceAsc('price_asc'),
  priceDesc('price_desc');

  const ProductSort(this.wire);

  final String wire;

  /// Unknown or missing values fall back to [newest], the server default.
  static ProductSort parse(String? raw) {
    final value = raw?.trim().toLowerCase();
    for (final sort in values) {
      if (sort.wire == value) return sort;
    }
    return newest;
  }
}

/// The filters of the public product listing. The same keys are used for the
/// `/products` app route and the API query, so a Home "See all" maps
/// straight onto the listing. Value equality: it keys the listing provider.
@immutable
class ProductListingQuery {
  const ProductListingQuery({
    this.sort = ProductSort.newest,
    this.categoryId,
    this.categorySlug,
    this.vendorAccountId,
    this.minPrice,
    this.maxPrice,
    this.inStock = false,
    this.onSale = false,
    this.minRating,
    this.search,
    this.size,
    this.color,
    this.optionValueIds = const <String>[],
  });

  factory ProductListingQuery.fromQueryParameters(Map<String, String> params) {
    String? text(String key) {
      final value = params[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    double? number(String key) {
      final value = double.tryParse(text(key) ?? '');
      return value == null || value.isNaN || value < 0 ? null : value;
    }

    bool flag(String key) => text(key)?.toLowerCase() == 'true';

    return ProductListingQuery(
      sort: ProductSort.parse(text(keySort)),
      categoryId: text(keyCategoryId),
      categorySlug: text(keyCategorySlug),
      vendorAccountId: text(keyVendorAccountId),
      minPrice: number(keyMinPrice),
      maxPrice: number(keyMaxPrice),
      inStock: flag(keyInStock),
      onSale: flag(keyOnSale),
      minRating: number(keyMinRating),
      search: text(keySearch),
      size: text(keySize),
      color: text(keyColor),
      // A GoRouter route carries one `optionValue` key, so ids travel
      // comma-separated in the app URL and repeated on the wire.
      optionValueIds: List.unmodifiable([
        for (final id in (text(keyOptionValue) ?? '').split(','))
          if (id.trim().isNotEmpty) id.trim(),
      ]),
    );
  }

  static const keySort = 'sort';
  static const keyCategoryId = 'categoryId';
  static const keyCategorySlug = 'categorySlug';
  static const keyVendorAccountId = 'vendorAccountId';
  static const keyMinPrice = 'minPrice';
  static const keyMaxPrice = 'maxPrice';
  static const keyInStock = 'inStock';
  static const keyOnSale = 'onSale';
  static const keyMinRating = 'minRating';
  static const keySearch = 'q';
  static const keySize = 'size';
  static const keyColor = 'color';
  static const keyOptionValue = 'optionValue';

  final ProductSort sort;
  final String? categoryId;
  final String? categorySlug;
  final String? vendorAccountId;
  final double? minPrice;
  final double? maxPrice;
  final bool inStock;
  final bool onSale;
  final double? minRating;
  final String? search;

  /// Matched case-insensitively against the values of Size-kind options.
  final String? size;

  /// Same, against Colour-kind options. US spelling on the wire.
  final String? color;

  /// `options[].values[].id`s from a product detail. Values of one option are
  /// OR'd server-side; different options are AND'd.
  final List<String> optionValueIds;

  /// Filters the viewer set in the filter sheet (not scope or sort).
  int get activeFilterCount =>
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (inStock ? 1 : 0) +
      (onSale ? 1 : 0) +
      (minRating != null ? 1 : 0) +
      (size != null ? 1 : 0) +
      (color != null ? 1 : 0) +
      optionValueIds.length;

  ProductListingQuery withSort(ProductSort value) => _copy(sort: value);

  /// Replaces every filter-sheet value at once.
  ProductListingQuery withFilters({
    required bool inStock,
    required bool onSale,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? size,
    String? color,
    List<String> optionValueIds = const <String>[],
  }) => ProductListingQuery(
    sort: sort,
    categoryId: categoryId,
    categorySlug: categorySlug,
    vendorAccountId: vendorAccountId,
    search: search,
    minPrice: minPrice,
    maxPrice: maxPrice,
    inStock: inStock,
    onSale: onSale,
    minRating: minRating,
    size: _clean(size),
    color: _clean(color),
    optionValueIds: List.unmodifiable(optionValueIds),
  );

  /// Drops one filter — what the removable chips call.
  ProductListingQuery without({
    bool price = false,
    bool inStock = false,
    bool onSale = false,
    bool rating = false,
    bool size = false,
    bool color = false,
    String? optionValueId,
  }) => ProductListingQuery(
    sort: sort,
    categoryId: categoryId,
    categorySlug: categorySlug,
    vendorAccountId: vendorAccountId,
    search: search,
    minPrice: price ? null : minPrice,
    maxPrice: price ? null : maxPrice,
    inStock: inStock ? false : this.inStock,
    onSale: onSale ? false : this.onSale,
    minRating: rating ? null : minRating,
    size: size ? null : this.size,
    color: color ? null : this.color,
    optionValueIds: optionValueId == null
        ? optionValueIds
        : List.unmodifiable([
            for (final id in optionValueIds)
              if (id != optionValueId) id,
          ]),
  );

  /// Keeps scope (category, vendor, search) and sort.
  ProductListingQuery clearFilters() =>
      withFilters(inStock: false, onSale: false);

  /// The query of `GET v1/public/products` (without cursor and page size),
  /// and the `/products` app route's parameters — both string-only, so
  /// option-value ids are comma-separated here.
  Map<String, String> toQueryParameters() => {
    keySort: sort.wire,
    keyCategoryId: ?categoryId,
    keyCategorySlug: ?categorySlug,
    keyVendorAccountId: ?vendorAccountId,
    if (minPrice case final value?) keyMinPrice: _formatNumber(value),
    if (maxPrice case final value?) keyMaxPrice: _formatNumber(value),
    if (inStock) keyInStock: 'true',
    if (onSale) keyOnSale: 'true',
    if (minRating case final value?) keyMinRating: _formatNumber(value),
    keySearch: ?search,
    keySize: ?size,
    keyColor: ?color,
    if (optionValueIds.isNotEmpty) keyOptionValue: optionValueIds.join(','),
  };

  /// The same query for Dio, where `optionValue` is a repeatable key
  /// (`?optionValue=a&optionValue=b`) as the catalog contract requires.
  Map<String, dynamic> toApiParameters() => {
    ...toQueryParameters(),
    if (optionValueIds.isNotEmpty) keyOptionValue: optionValueIds,
  };

  ProductListingQuery _copy({ProductSort? sort}) => ProductListingQuery(
    sort: sort ?? this.sort,
    categoryId: categoryId,
    categorySlug: categorySlug,
    vendorAccountId: vendorAccountId,
    minPrice: minPrice,
    maxPrice: maxPrice,
    inStock: inStock,
    onSale: onSale,
    minRating: minRating,
    search: search,
    size: size,
    color: color,
    optionValueIds: optionValueIds,
  );

  static String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _formatNumber(double value) =>
      value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();

  @override
  bool operator ==(Object other) =>
      other is ProductListingQuery &&
      other.sort == sort &&
      other.categoryId == categoryId &&
      other.categorySlug == categorySlug &&
      other.vendorAccountId == vendorAccountId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.inStock == inStock &&
      other.onSale == onSale &&
      other.minRating == minRating &&
      other.search == search &&
      other.size == size &&
      other.color == color &&
      other.optionValueIds.join(',') == optionValueIds.join(',');

  @override
  int get hashCode => Object.hash(
    sort,
    categoryId,
    categorySlug,
    vendorAccountId,
    minPrice,
    maxPrice,
    inStock,
    onSale,
    minRating,
    search,
    size,
    color,
    Object.hashAll(optionValueIds),
  );
}
