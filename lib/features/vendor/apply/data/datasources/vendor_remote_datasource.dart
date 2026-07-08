import 'package:dio/dio.dart' show FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/data/models/vendor_application_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';

class VendorRemoteDataSource {
  VendorRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<VendorApplicationDto> getApplicationStatus() async {
    final response = await apiClient.get('/v1/vendor/application');
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Creates (or idempotently returns) the caller's current Draft
  /// application. Safe to call every time the wizard starts.
  Future<VendorApplicationDto> createOrGetDraft({
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/application/draft',
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Wizard 1A — business identity.
  Future<VendorApplicationDto> patchStep1Business({
    required String brandName,
    required String legalBusinessName,
    required String countryCode,
    required BusinessType businessType,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.patch(
      '/v1/vendor/application/draft/step-1',
      data: {
        'brandName': brandName,
        'legalBusinessName': legalBusinessName,
        'countryCode': countryCode,
        'businessType': businessType.code,
      },
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Wizard 1B — commission range.
  Future<VendorApplicationDto> patchStep2Commission({
    required double commissionMinPercent,
    required double commissionMaxPercent,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.patch(
      '/v1/vendor/application/draft/step-2',
      data: {
        'commissionMinPercent': commissionMinPercent,
        'commissionMaxPercent': commissionMaxPercent,
      },
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Wizard 1C — profile (website + tax id).
  Future<VendorApplicationDto> patchStep3Profile({
    required String? website,
    required String? taxId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.patch(
      '/v1/vendor/application/draft/step-3',
      data: {
        if (website != null) 'website': website,
        if (taxId != null) 'taxId': taxId,
      },
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Closes the wizard draft — validates completeness and transitions
  /// Draft → Submitted.
  Future<VendorApplicationDto> submitDraft({
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/application/draft/submit',
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Legacy single-shot endpoint. Carries fields the draft wizard has no
  /// step for (address, catalog size, price range, brand story, bank
  /// account) — called as a best-effort follow-up after the wizard steps.
  Future<VendorApplicationDto> submitLegacyApplication({
    required VendorApplicationForm form,
    required String idempotencyKey,
  }) async {
    final bank = form.bankAccount;
    final response = await apiClient.post(
      '/v1/vendor/apply',
      data: {
        'brandName': form.brandName,
        'legalBusinessName': form.legalBusinessName,
        'countryCode': form.countryCode,
        'businessType': form.businessType.code,
        'commissionMinPercent': form.commissionMinPercent,
        'commissionMaxPercent': form.commissionMaxPercent,
        if (form.website != null) 'website': form.website,
        'taxId': form.taxId,
        if (form.addressLine1 != null) 'addressLine1': form.addressLine1,
        if (form.addressLine2 != null) 'addressLine2': form.addressLine2,
        if (form.city != null) 'city': form.city,
        if (form.stateProvince != null) 'stateProvince': form.stateProvince,
        if (form.postalCode != null) 'postalCode': form.postalCode,
        if (form.catalogSize != null) 'catalogSize': form.catalogSize!.code,
        if (form.priceRangeMinAmount != null)
          'priceRangeMinAmount': form.priceRangeMinAmount,
        if (form.priceRangeMaxAmount != null)
          'priceRangeMaxAmount': form.priceRangeMaxAmount,
        if (form.priceRangeCurrency != null)
          'priceRangeCurrency': form.priceRangeCurrency,
        if (form.brandStory != null) 'brandStory': form.brandStory,
        if (bank != null)
          'bankAccount': {
            'accountHolderName': bank.accountHolderName,
            'bankName': bank.bankName,
            'accountType': bank.accountType.code,
            'routingNumber': bank.routingNumber,
            'accountNumber': bank.accountNumber,
            if (bank.w9StorageUri != null) 'w9StorageUri': bank.w9StorageUri,
            'taxAttestationAccepted': bank.taxAttestationAccepted,
          },
      },
      options: _idempotent(idempotencyKey),
    );
    return VendorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET /v1/accounts/{accountId}/kyc-sessions/active — returns the raw
  /// session map, or `null` when the account has no active session yet
  /// (the backend returns `Ok(null)`, not a 404, for that case).
  Future<Map<String, dynamic>?> getActiveKycSession(String accountId) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/kyc-sessions/active',
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>?;
  }

  /// POST /v1/accounts/{accountId}/kyc-sessions — starts a new session.
  /// "Manual" reflects that Style Mint has no automated ID-verification
  /// provider wired up yet — sessions are reviewed by an admin.
  Future<Map<String, dynamic>> startKycSession(
    String accountId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/kyc-sessions',
      data: {'provider': 'Manual'},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// POST .../verification-documents/upload-blob (multipart) — stores the
  /// raw file and returns {blobReference, contentHash, contentSizeBytes,
  /// contentType, originalFilename} to feed into [registerKycDocument].
  Future<Map<String, dynamic>> uploadKycBlob(
    String accountId,
    String filePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await apiClient.rawPost(
      '/v1/accounts/$accountId/verification-documents/upload-blob',
      data: formData,
      options: Options(headers: {'requiresToken': true}),
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /v1/accounts/{accountId}/verification-documents — registers a
  /// previously-uploaded blob against a KYC session. `documentType` is the
  /// backend `VerificationDocumentType` int (Pan=7, Citizenship=8,
  /// BusinessRegistration=9, TaxDocument=10 for vendor docs); `side` is
  /// always NotApplicable(1) — these are single-page documents.
  Future<KYCDocumentDto> registerKycDocument({
    required String accountId,
    required String sessionId,
    required int documentType,
    required Map<String, dynamic> blob,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/verification-documents',
      data: {
        'sessionId': sessionId,
        'documentType': documentType,
        'side': 1, // NotApplicable
        'blobReference': blob['blobReference'],
        'contentHash': blob['contentHash'],
        'contentSizeBytes': blob['contentSizeBytes'],
        'contentType': blob['contentType'],
        if (blob['originalFilename'] != null)
          'originalFilename': blob['originalFilename'],
      },
      options: _idempotent(idempotencyKey),
    );
    return KYCDocumentDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<KYCDocumentDto>> getKYCDocuments({
    required String accountId,
    required String sessionId,
  }) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/verification-documents'
      '/by-session/$sessionId',
      options: Options(headers: {'requiresToken': true}),
    );
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
