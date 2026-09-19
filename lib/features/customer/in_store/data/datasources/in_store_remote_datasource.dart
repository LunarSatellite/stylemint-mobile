import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/models/endless_aisle_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/models/product_reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/models/store_product_dto.dart';

/// One page of `GET /v1/public/vendors/{vendorAccountId}/products`.
typedef VendorProductsPage = ({
  List<StoreProductDto> products,
  String? nextCursor,
});

/// Reads for the shopper's in-store screens.
class InStoreRemoteDataSource {
  InStoreRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/public/reels/by-product/{productId}?pageSize=` — published
  /// reels tagging the product (`PagedResult<ReelDto>`). Anonymous allowed;
  /// a signed-in shopper's token still goes along.
  Future<List<ProductReelDto>> getProductReels(
    String productId, {
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/v1/public/reels/by-product/${Uri.encodeComponent(productId)}',
      queryParameters: <String, dynamic>{'pageSize': pageSize},
    );
    return ProductReelDto.listFromPage(response);
  }

  /// `GET /v1/public/codes/{code}/endless-aisle` — what a shopper standing in
  /// front of this code can do next: order the item wherever they are, and
  /// the seller's recorded collection points. Read-only and scan-free; the
  /// `resolve` call already counted this scan. Anonymous allowed.
  ///
  /// A code pointing at a person's profile is a 400 from the backend ("no
  /// aisle to extend"), and an unknown or revoked one is a 404.
  Future<EndlessAisleDto> getEndlessAisle(String code) async {
    final response = await apiClient.get(
      '/v1/public/codes/${Uri.encodeComponent(code)}/endless-aisle',
    );
    return EndlessAisleDto.fromJson(readJsonObject(response));
  }

  Future<void> addScannedProductToCart({
    required String code,
    required CodeScanVia via,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/omnichannel/codes/${Uri.encodeComponent(code)}/cart',
      data: <String, dynamic>{'via': via.wireName, 'quantity': 1},
      options: Options(
        headers: <String, dynamic>{
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }

  /// `GET /v1/public/vendors/{vendorAccountId}/products?cursor=&pageSize=` —
  /// the vendor's publicly listed products, newest first
  /// (`PagedResult<ProductDto>`). Anonymous allowed; an unknown vendor is an
  /// empty page.
  Future<VendorProductsPage> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/v1/public/vendors/${Uri.encodeComponent(vendorAccountId)}/products',
      queryParameters: <String, dynamic>{
        'pageSize': pageSize,
        'cursor': ?cursor,
      },
    );
    return (
      products: StoreProductDto.listFromPage(response),
      nextCursor: readNextCursor(response),
    );
  }
}
