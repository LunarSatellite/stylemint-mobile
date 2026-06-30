import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/deletion_request.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/notification_prefs.dart';

abstract interface class SettingsRepository {
  Future<Either<NetworkExceptions, NotificationPreferences>> getNotificationPreferences();

  Future<Either<NetworkExceptions, NotificationPreferences>> updateNotificationPreferences(
    NotificationPreferences prefs,
  );

  Future<Either<NetworkExceptions, String>> getCurrentLanguage();

  Future<Either<NetworkExceptions, Unit>> setLanguage(String languageCode);

  Future<Either<NetworkExceptions, Unit>> deleteAccount(String idempotencyKey, String reason);

  /// Returns null if there is no pending deletion request.
  Future<Either<NetworkExceptions, DeletionRequest?>> getPendingDeletion();

  Future<Either<NetworkExceptions, Unit>> cancelDeletion(String requestId);

  Future<Either<NetworkExceptions, Unit>> logout();
}
