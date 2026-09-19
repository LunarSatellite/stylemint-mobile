import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Query parameters of the in-store routes.
abstract final class InStoreQuery {
  static const String storeId = 'storeId';
  static const String code = 'code';
  static const String via = 'via';
  static const String store = 'store';
  static const String city = 'city';

  /// The vendor's display name.
  static const String vendor = 'vendor';

  /// The vendor's account id.
  static const String vendorId = 'vendorId';
}

/// `/in-store/product/{productId}` with the store and code it was scanned
/// from: `?storeId=&code=&store=&city=`.
String inStoreProductLocation({
  required String productId,
  String? storeId,
  String? code,
  String? via,
  String? storeName,
  String? storeCity,
}) => _location(
  RouteNames.inStoreProduct.replaceFirst(':productId', productId),
  {
    InStoreQuery.storeId: storeId,
    InStoreQuery.code: code,
    InStoreQuery.via: via,
    InStoreQuery.store: storeName,
    InStoreQuery.city: storeCity,
  },
);

/// `/in-store/store/{storeId}?code=&store=&city=&vendor=&vendorId=`.
String inStoreStoreLocation({
  required String storeId,
  String? code,
  String? storeName,
  String? storeCity,
  String? vendorName,
  String? vendorId,
}) => _location(
  RouteNames.inStoreStore.replaceFirst(':storeId', storeId),
  {
    InStoreQuery.code: code,
    InStoreQuery.store: storeName,
    InStoreQuery.city: storeCity,
    InStoreQuery.vendor: vendorName,
    InStoreQuery.vendorId: vendorId,
  },
);

String _location(String path, Map<String, String?> query) {
  final present = <String, String>{
    for (final MapEntry(:key, :value) in query.entries)
      if (value != null && value.trim().isNotEmpty) key: value.trim(),
  };
  return Uri(
    path: path,
    queryParameters: present.isEmpty ? null : present,
  ).toString();
}
