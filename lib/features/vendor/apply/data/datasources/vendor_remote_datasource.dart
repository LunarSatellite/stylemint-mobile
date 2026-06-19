import 'package:dio/dio.dart' show FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/data/models/vendor_application_dto.dart';

class VendorRemoteDataSource {
  VendorRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<VendorApplicationDto> getApplicationStatus() async {
    final response = await apiClient.get('/v1/vendor/application');
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  Future<VendorApplicationDto> submitApplication({
    required String businessName,
    required String businessType,
    required String taxId,
    required String businessRegistrationNumber,
    String? website,
    required String countryRegion,
    required String streetAddress,
    required String city,
    required String country,
    required String zipCode,
    required String state,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/apply',
      data: {
        'businessName': businessName,
        'businessType': businessType,
        'taxId': taxId,
        'businessRegistrationNumber': businessRegistrationNumber,
        if (website != null) 'website': website,
        'countryRegion': countryRegion,
        'streetAddress': streetAddress,
        'city': city,
        'country': country,
        'zipCode': zipCode,
        'state': state,
      },
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): POST /v1/vendor/kyc/upload not found. Use POST /v1/accounts/{accountId}/verification-documents
  Future<KYCDocumentDto> uploadKYCDocument({
    required String filePath,
    required String documentType,
    required String idempotencyKey,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'documentType': documentType,
    });
    final response = await apiClient.rawPost(
      '/v1/vendor/kyc/upload',
      data: formData,
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    final data = response.data as Map<String, dynamic>;
    return KYCDocumentDto.fromJson(data);
  }

  // TODO(swagger): GET /v1/vendor/kyc/documents not found. Use GET /v1/accounts/{accountId}/verification-documents/by-session/{sessionId}
  Future<List<KYCDocumentDto>> getKYCDocuments() async {
    final response = await apiClient.get('/v1/vendor/kyc/documents');
    final list = response as List<dynamic>;
    return list
        .map((e) => KYCDocumentDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
