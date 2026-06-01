import 'package:dio/dio.dart' show FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/models/creator_application_dto.dart';

class CreatorRemoteDataSource {
  CreatorRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorApplicationDto> getApplicationStatus() async {
    final response = await apiClient.get('/v1/creator/application');
    return CreatorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CreatorApplicationDto> submitApplication({
    required String fullName,
    required String handle,
    required List<Map<String, dynamic>> platforms,
    required List<String> categories,
    required String bio,
    String? portfolioUrl,
    String? identityDocUrl,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/apply',
      data: {
        'fullName': fullName,
        'handle': handle,
        'platforms': platforms,
        'categories': categories,
        'bio': bio,
        if (portfolioUrl != null) 'portfolioUrl': portfolioUrl,
        if (identityDocUrl != null) 'identityDocUrl': identityDocUrl,
      },
      options: _idempotent(idempotencyKey),
    );
    return CreatorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): /v1/creator/documents not found; re-evaluate identity doc upload path
  Future<String> uploadIdentityDoc(String filePath, String idempotencyKey) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await apiClient.rawPost(
      '/v1/creator/documents',
      data: formData,
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
