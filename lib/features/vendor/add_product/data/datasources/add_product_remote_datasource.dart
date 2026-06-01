import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/models/product_form_dto.dart';

class AddProductRemoteDataSource {
  AddProductRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Options _idempotent(String idempotencyKey) => Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      );

  Future<ProductDraftDto> saveDraft(
    ProductDraftDto draft,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/products',
      data: draft.toJson(),
      options: _idempotent(idempotencyKey),
    );
    return ProductDraftDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ProductDraftDto> updateDraft(
    String id,
    ProductDraftDto draft,
    String idempotencyKey,
  ) async {
    final response = await apiClient.patch(
      '/v1/vendor/products/$id/step-1',
      data: draft.toJson(),
      options: _idempotent(idempotencyKey),
    );
    return ProductDraftDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): POST /v1/vendor/products/images not found in Swagger
  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'image.jpg'),
    });
    final opts = Options(headers: {'requiresToken': true});
    final response = await apiClient.rawPost(
      '/v1/vendor/products/images',
      data: formData,
      options: opts,
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
    final data = response as Map<String, dynamic>;
    return data['productId'] as String;
  }
}
