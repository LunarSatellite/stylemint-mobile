import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';

void main() {
  test('size, colour and option values round-trip through the query', () {
    const params = {
      'sort': 'price_asc',
      'categorySlug': 'fashion',
      'size': 'M',
      'color': 'Emerald',
      'optionValue': 'aa01,bb01',
    };

    final query = ProductListingQuery.fromQueryParameters(params);

    expect(query.size, 'M');
    expect(query.color, 'Emerald');
    expect(query.optionValueIds, ['aa01', 'bb01']);
    expect(query.toQueryParameters(), params);
  });

  test('option values repeat on the wire', () {
    final query = ProductListingQuery.fromQueryParameters(const {
      'optionValue': 'aa01,bb01',
      'size': 'M',
    });

    expect(query.toApiParameters()['optionValue'], ['aa01', 'bb01']);
    expect(query.toApiParameters()['size'], 'M');
  });

  test('blank and missing option filters are dropped', () {
    final query = ProductListingQuery.fromQueryParameters(const {
      'optionValue': ' , ',
      'size': '  ',
    });

    expect(query.optionValueIds, isEmpty);
    expect(query.size, isNull);
    expect(query.toQueryParameters().containsKey('optionValue'), isFalse);
    expect(query.toQueryParameters().containsKey('size'), isFalse);
  });

  test('each option filter counts towards the filter badge', () {
    final query = ProductListingQuery.fromQueryParameters(const {
      'size': 'M',
      'color': 'Emerald',
      'optionValue': 'aa01,bb01',
      'inStock': 'true',
    });

    expect(query.activeFilterCount, 5);
  });

  test('withFilters trims, and keeps scope and sort', () {
    final query = ProductListingQuery.fromQueryParameters(const {
      'sort': 'rating',
      'categorySlug': 'fashion',
      'q': 'linen',
    }).withFilters(
      inStock: true,
      onSale: false,
      size: '  L  ',
      color: '',
      optionValueIds: const ['aa01'],
    );

    expect(query.size, 'L');
    expect(query.color, isNull);
    expect(query.optionValueIds, ['aa01']);
    expect(query.sort, ProductSort.rating);
    expect(query.categorySlug, 'fashion');
    expect(query.search, 'linen');
  });

  test('clearFilters drops the option filters too', () {
    final query = ProductListingQuery.fromQueryParameters(const {
      'size': 'M',
      'color': 'Emerald',
      'optionValue': 'aa01',
      'categorySlug': 'fashion',
    }).clearFilters();

    expect(query.activeFilterCount, 0);
    expect(query.categorySlug, 'fashion');
  });

  test('without() removes exactly one filter', () {
    final query = ProductListingQuery.fromQueryParameters(const {
      'size': 'M',
      'color': 'Emerald',
      'optionValue': 'aa01,bb01',
    });

    expect(query.without(size: true).size, isNull);
    expect(query.without(size: true).color, 'Emerald');
    expect(query.without(optionValueId: 'aa01').optionValueIds, ['bb01']);
  });

  test('queries differing only by option filters are not equal', () {
    final a = ProductListingQuery.fromQueryParameters(const {'size': 'M'});
    final b = ProductListingQuery.fromQueryParameters(const {'size': 'L'});
    final c = ProductListingQuery.fromQueryParameters(const {'size': 'M'});

    expect(a, isNot(b));
    expect(a, c);
    expect(a.hashCode, c.hashCode);
  });
}
