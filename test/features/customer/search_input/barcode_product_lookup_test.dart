import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/barcode_product_lookup.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/barcode_lookup_outcome.dart';

class _StubSearch extends CustomerSearchRemoteDataSource {
  _StubSearch({this.results, this.error})
    : super(apiClient: ApiClient(dio: Dio()));

  final CustomerSearchResults? results;
  final Exception? error;
  String? lastQuery;

  @override
  Future<CustomerSearchResults> search(String query, {int limit = 20}) async {
    lastQuery = query;
    final failure = error;
    if (failure != null) throw failure;
    return results ?? CustomerSearchResults.empty;
  }
}

SearchResultProduct _product(String id) => SearchResultProduct(
  productId: id,
  name: 'Product $id',
  heroImageUrl: '',
  price: 10,
  currency: 'USD',
  averageRating: 4,
);

CustomerSearchResults _results(List<String> ids) => CustomerSearchResults(
  products: ids.map(_product).toList(),
  brands: const [],
  reels: const [],
  creators: const [],
  totalHits: ids.length,
);

void main() {
  group('normalizeBarcode', () {
    test('accepts a plain EAN-13 and strips stray whitespace', () {
      expect(normalizeBarcode('  5901234 123457 '), '5901234123457');
    });

    test('rejects values too short to be a product code', () {
      expect(normalizeBarcode('123'), isNull);
    });

    test('rejects a QR payload, which the Scan tab owns', () {
      expect(normalizeBarcode('https://stylemint.app/c/ABC123'), isNull);
    });

    test('accepts Code 128 alphanumerics', () {
      expect(normalizeBarcode('SM-2026_A1'), 'SM-2026_A1');
    });
  });

  group('BarcodeProductLookup', () {
    test('one hit is the product', () async {
      final search = _StubSearch(results: _results(['p-1']));
      final outcome = await BarcodeProductLookup(
        searchDataSource: search,
      ).find('5901234123457');

      expect(outcome, isA<BarcodeMatched>());
      expect((outcome as BarcodeMatched).productId, 'p-1');
      expect(search.lastQuery, '5901234123457');
    });

    test('several hits are ambiguous, never a claimed match', () async {
      final outcome = await BarcodeProductLookup(
        searchDataSource: _StubSearch(results: _results(['p-1', 'p-2'])),
      ).find('5901234123457');

      expect(outcome, isA<BarcodeAmbiguous>());
      expect((outcome as BarcodeAmbiguous).results.products, hasLength(2));
    });

    test('no hit reaches the designed unmatched outcome', () async {
      final outcome = await BarcodeProductLookup(
        searchDataSource: _StubSearch(results: _results(const [])),
      ).find('5901234123457');

      expect(outcome, isA<BarcodeUnmatched>());
      expect(outcome.code, '5901234123457');
    });

    test('an unusable code never reaches the network', () async {
      final search = _StubSearch(results: _results(['p-1']));
      final outcome = await BarcodeProductLookup(
        searchDataSource: search,
      ).find('12');

      expect(outcome, isA<BarcodeUnmatched>());
      expect(search.lastQuery, isNull);
    });

    test('a failed lookup is separate from an unmatched one', () async {
      final outcome = await BarcodeProductLookup(
        searchDataSource: _StubSearch(error: Exception('offline')),
      ).find('5901234123457');

      expect(outcome, isA<BarcodeLookupFailed>());
    });
  });
}
