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

  @override
  Future<Either<NetworkExceptions, VendorApplication>> getApplicationStatus() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getApplicationStatus();
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
  Future<Either<NetworkExceptions, VendorApplication>> submitApplication(
    VendorApplicationForm form,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.submitApplication(
          businessName: form.businessName,
          businessType: form.businessType.name,
          taxId: form.taxId,
          ownerFullName: form.ownerFullName,
          ownerPhone: form.ownerPhone,
          ownerEmail: form.ownerEmail,
          description: form.description,
          website: form.website,
          categories: form.categories,
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
  Future<Either<NetworkExceptions, KYCDocument>> uploadKYCDocument(
    String filePath,
    KYCDocumentType documentType,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.uploadKYCDocument(
          filePath: filePath,
          documentType: documentType.name,
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
  Future<Either<NetworkExceptions, List<KYCDocument>>> getKYCDocuments() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getKYCDocuments();
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
}
