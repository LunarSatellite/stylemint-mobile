import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/barcode_lookup_outcome.dart';

/// Resolves a scanned product barcode to a catalogue product.
///
/// There is no barcode or GTIN endpoint on the backend: neither
/// `/api/v1/customer/search*` nor any lead360 controller exposes one (the
/// only "barcode" in the whole backend is the delivery module's parcel
/// tracking code). Rather than stub a fake lookup, a scan is sent through the
/// product lookup that does exist — the unified catalogue search — with the
/// code as a literal query.
///
/// That search is a text search, so a single hit is treated as the product
/// and several hits are treated as "the search guessed", never as a match.
class BarcodeProductLookup {
  const BarcodeProductLookup({required this.searchDataSource});

  final CustomerSearchRemoteDataSource searchDataSource;

  Future<BarcodeLookupOutcome> find(String rawCode) async {
    final code = normalizeBarcode(rawCode);
    if (code == null) return BarcodeUnmatched(code: rawCode.trim());
    try {
      final results = await searchDataSource.search(code, limit: 5);
      final products = results.products;
      if (products.isEmpty) return BarcodeUnmatched(code: code);
      if (products.length > 1) {
        return BarcodeAmbiguous(code: code, results: results);
      }
      final product = products.first;
      return BarcodeMatched(
        code: code,
        productId: product.productId,
        productName: product.name,
      );
    } on Object catch (error) {
      return BarcodeLookupFailed(code: code, detail: error.toString());
    }
  }
}
