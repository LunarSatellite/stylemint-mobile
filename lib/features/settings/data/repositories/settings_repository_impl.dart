import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/models/notification_prefs_dto.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/deletion_request.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final SettingsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, NotificationPreferences>> getNotificationPreferences() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getNotificationPreferences();
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
  Future<Either<NetworkExceptions, NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = NotificationPreferencesDto.fromDomain(prefs);
        final result = await remoteDataSource.updateNotificationPreferences(dto);
        return right(result.toDomain());
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
  Future<Either<NetworkExceptions, String>> getCurrentLanguage() async {
    if (await networkInfo.isConnected) {
      try {
        final code = await remoteDataSource.getCurrentLanguage();
        return right(code);
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
  Future<Either<NetworkExceptions, Unit>> setLanguage(String languageCode) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setLanguage(languageCode);
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

  @override
  Future<Either<NetworkExceptions, Unit>> deleteAccount(String idempotencyKey, String reason) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAccount(idempotencyKey, reason);
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

  @override
  Future<Either<NetworkExceptions, DeletionRequest?>> getPendingDeletion() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getPendingDeletion();
        return right(dto?.toDomain());
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
  Future<Either<NetworkExceptions, Unit>> cancelDeletion(String requestId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.cancelDeletion(requestId);
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

  @override
  Future<Either<NetworkExceptions, Unit>> logout() async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logout();
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
