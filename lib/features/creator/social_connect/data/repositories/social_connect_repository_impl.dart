import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/datasources/social_connect_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/repositories/social_connect_repository.dart';
import 'package:uuid/uuid.dart';

class SocialConnectRepositoryImpl implements SocialConnectRepository {
  SocialConnectRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final SocialConnectRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<SocialAccount>>> getConnectedAccounts() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getConnectedAccounts();
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
  Future<Either<NetworkExceptions, SocialAccount>> connectPlatform(
    SocialPlatform platform,
    String authCode,
    String redirectUri,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.connectPlatform(
          platform: platform.name,
          authCode: authCode,
          redirectUri: redirectUri,
          idempotencyKey: const Uuid().v4(),
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
  Future<Either<NetworkExceptions, Unit>> disconnectPlatform(String accountId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.disconnectPlatform(
          accountId,
          const Uuid().v4(),
        );
        return right(unit);
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
