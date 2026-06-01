import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/datasources/settings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/models/notification_prefs_dto.dart';
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
        final dto = NotificationPreferencesDto(
          pushEnabled: prefs.pushEnabled,
          emailEnabled: prefs.emailEnabled,
          orderUpdates: prefs.orderUpdates,
          promotional: prefs.promotional,
          reelLikes: prefs.reelLikes,
          newFollowers: prefs.newFollowers,
          quietHoursEnabled: prefs.quietHoursEnabled,
          quietHoursStart: prefs.quietHoursStart,
          quietHoursEnd: prefs.quietHoursEnd,
        );
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
  Future<Either<NetworkExceptions, Unit>> deleteAccount(
    String accountId,
    String idempotencyKey,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAccount(accountId, idempotencyKey);
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
