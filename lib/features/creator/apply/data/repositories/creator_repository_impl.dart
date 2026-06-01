import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';
import 'package:uuid/uuid.dart';

class CreatorRepositoryImpl implements CreatorRepository {
  CreatorRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, CreatorApplication>> getApplicationStatus() async {
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
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CreatorApplication>> submitApplication(
    CreatorApplicationForm form,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.submitApplication(
          fullName: form.fullName,
          handle: form.handle,
          platforms: form.platforms
              .map(
                (p) => {
                  'id': p.id,
                  'name': p.name,
                  'handle': p.handle,
                  'followerCount': p.followerCount,
                  'connected': p.connected,
                },
              )
              .toList(growable: false),
          categories: form.categories,
          bio: form.bio,
          portfolioUrl: form.portfolioUrl,
          identityDocUrl: form.identityDocUrl,
          idempotencyKey: _uuid.v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, String>> uploadIdentityDoc(String filePath) async {
    if (await networkInfo.isConnected) {
      try {
        final url = await remoteDataSource.uploadIdentityDoc(filePath, _uuid.v4());
        return right(url);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(const NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }
}
