import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/data/datasources/vendor_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/repositories/vendor_repository.dart';
import 'package:uuid/uuid.dart';

class VendorRepositoryImpl implements VendorRepository {
  VendorRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  static NetworkExceptions _mapDioException(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401) return const NetworkExceptions.auth();
    if (status == 404) return const NetworkExceptions.notFound();
    if (status == 409) return const NetworkExceptions.conflict();
    if (status == 422) {
      final data = e.response?.data;
      final code = data is Map ? (data['errorCode'] as String? ?? 'validation_error') : 'validation_error';
      return NetworkExceptions.validation(code: code);
    }
    if (status != null && status >= 500) return const NetworkExceptions.serverUnavailable();
    return NetworkExceptions.server(e.message ?? 'Unknown error');
  }

  @override
  Future<Either<NetworkExceptions, VendorApplication>> getApplicationStatus() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getApplicationStatus();
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          // 404 = no application on file yet → let the UI show the apply form.
          if (e.response?.statusCode == 404) {
            return left(const NetworkExceptions.notFound());
          }
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, VendorApplication>> submitApplication(
    VendorApplicationForm form,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      // /v1/vendor/apply is the endpoint that's actually live on this
      // backend and carries every field the wizard collects in one shot.
      // The draft/step-* wizard endpoints are attempted afterward on a
      // best-effort basis — they 404/error on this deployment today, so
      // their failure must never block a successful submission.
      final dto = await remoteDataSource.submitLegacyApplication(
        form: form,
        idempotencyKey: _uuid.v4(),
      );
      try {
        await remoteDataSource.createOrGetDraft(idempotencyKey: _uuid.v4());
        await remoteDataSource.patchStep1Business(
          brandName: form.brandName,
          legalBusinessName: form.legalBusinessName,
          countryCode: form.countryCode,
          businessType: form.businessType,
          idempotencyKey: _uuid.v4(),
        );
        await remoteDataSource.patchStep3Profile(
          website: form.website,
          taxId: form.taxId,
          idempotencyKey: _uuid.v4(),
        );
        await remoteDataSource.patchStep2Commission(
          commissionMinPercent: form.commissionMinPercent,
          commissionMaxPercent: form.commissionMaxPercent,
          idempotencyKey: _uuid.v4(),
        );
        await remoteDataSource.submitDraft(idempotencyKey: _uuid.v4());
      } catch (_) {
        // Best-effort only — the legacy call above already submitted the
        // application; the wizard-draft mirror isn't required to succeed.
      }
      return right(dto.toDomain());
    } catch (e) {
      if (e is DioException) {
        return left(_mapDioException(e));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(NetworkExceptions.unexpectedError());
      }
    }
  }

  @override
  Future<Either<NetworkExceptions, KYCDocument>> uploadKYCDocument(
    String filePath,
    KYCDocumentType documentType, {
    required String accountId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final sessionId = await _ensureActiveKycSessionId(accountId);
        final blob = await remoteDataSource.uploadKycBlob(accountId, filePath);
        final dto = await remoteDataSource.registerKycDocument(
          accountId: accountId,
          sessionId: sessionId,
          documentType: _documentTypeCode(documentType),
          blob: blob,
          idempotencyKey: _uuid.v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<KYCDocument>>> getKYCDocuments({
    required String accountId,
    required String sessionId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getKYCDocuments(
          accountId: accountId,
          sessionId: sessionId,
        );
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, String?>> getActiveKycSessionId({
    required String accountId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final session = await remoteDataSource.getActiveKycSession(accountId);
        return right(session?['id'] as String?);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  /// Returns the account's active KYC session id, starting a new one
  /// (Pending, backend-default lifetime) if none exists yet.
  Future<String> _ensureActiveKycSessionId(String accountId) async {
    final active = await remoteDataSource.getActiveKycSession(accountId);
    if (active != null) return active['id'] as String;
    final started = await remoteDataSource.startKycSession(accountId, _uuid.v4());
    return started['id'] as String;
  }

  /// Vendor-facing subset of the backend `VerificationDocumentType` enum
  /// (7-10 — see StyleMint.Modules.Identity.Enums.VerificationDocumentType).
  static int _documentTypeCode(KYCDocumentType type) => switch (type) {
    KYCDocumentType.pan => 7,
    KYCDocumentType.citizenship => 8,
    KYCDocumentType.businessReg => 9,
    KYCDocumentType.taxDoc => 10,
  };
}
