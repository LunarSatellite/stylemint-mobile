import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

/// Network-free [ApiClient] for widget smoke tests. Returns shape-valid empty
/// payloads keyed loosely by path so every screen reaches its data/empty state
/// without touching the network. All DTO.fromJson parsers are null-defensive,
/// so an empty map/list is enough to render.
class FakeApiClient extends ApiClient {
  FakeApiClient() : super(dio: Dio());

  dynamic _canned(String uri) {
    // List endpoint (returns a bare JSON array).
    if (uri.contains('payout-destinations')) return <dynamic>[];
    // Paged / collection endpoints (return { items: [] }).
    if (uri.contains('comments') ||
        uri.contains('matches') ||
        uri.contains('activity') ||
        uri.contains('product-inquiries') ||
        uri.contains('creators-you-may-like') ||
        uri.contains('feed')) {
      return <String, dynamic>{'items': <dynamic>[]};
    }
    // Single-object endpoints (return {} — parsers fill defaults).
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async =>
      _canned(uri);

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) async =>
      _canned(uri);

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async =>
      <String, dynamic>{};

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async =>
      null;
}
