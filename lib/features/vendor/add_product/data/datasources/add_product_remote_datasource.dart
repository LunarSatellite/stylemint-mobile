import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/models/product_form_dto.dart';

/// Talks to the catalog vendor-products wizard (4-step PATCH + publish):
///   POST   /v1/vendor/products              -> start draft (basic)
///   PATCH  /v1/vendor/products/{id}/step-1  -> basic
///   PATCH  /v1/vendor/products/{id}/step-2  -> media
///   PATCH  /v1/vendor/products/{id}/step-3  -> pricing + inventory
///   PATCH  /v1/vendor/products/{id}/step-4  -> shipping
///   POST   /v1/vendor/products/{id}/publish -> publish
/// Each step's body is built from the domain draft in the repository; this
/// source stays thin and just transports the prepared JSON maps.
class AddProductRemoteDataSource {
  AddProductRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Options _idempotent(String idempotencyKey) => Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      );

  Options _authed() => Options(headers: {'requiresToken': true});

  /// Real catalog taxonomy for the Step-1 category picker.
  Future<List<CategoryOptionDto>> fetchCategories() async {
    final response = await apiClient.get('/v1/public/categories');
    final list = (response as List<dynamic>)
        .map((e) => CategoryOptionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return list;
  }

  /// Starts a draft and returns the new product id.
  Future<String> startDraft(
    Map<String, dynamic> body,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/products',
      data: body,
      options: _idempotent(idempotencyKey),
    );
    return _readId(response);
  }

  Future<void> patchStep1(String id, Map<String, dynamic> body) =>
      apiClient.patch('/v1/vendor/products/$id/step-1',
          data: body, options: _authed());

  Future<void> patchStep2(String id, Map<String, dynamic> body) =>
      apiClient.patch('/v1/vendor/products/$id/step-2',
          data: body, options: _authed());

  Future<void> patchStep3(String id, Map<String, dynamic> body) =>
      apiClient.patch('/v1/vendor/products/$id/step-3',
          data: body, options: _authed());

  Future<void> patchStep4(String id, Map<String, dynamic> body) =>
      apiClient.patch('/v1/vendor/products/$id/step-4',
          data: body, options: _authed());

  // TODO(swagger): POST /v1/vendor/products/images not found in Swagger
  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'image.jpg'),
    });
    final response = await apiClient.rawPost(
      '/v1/vendor/products/images',
      data: formData,
      options: _authed(),
    );
    final dto = ImageUploadResponseDto.fromJson(
      response.data as Map<String, dynamic>,
    );
    return dto.url;
  }

  Future<String> publishProduct(String draftId, String idempotencyKey) async {
    final response = await apiClient.post(
      '/v1/vendor/products/$draftId/publish',
      options: _idempotent(idempotencyKey),
    );
    return _readId(response);
  }

  String _readId(dynamic response) {
    final data = response as Map<String, dynamic>;
    // Publish responds with the published ProductDto; the wizard steps respond
    // with the same ProductDto shape. Both carry `id`; tolerate `productId`.
    return (data['id'] ?? data['productId']) as String;
  }
}
