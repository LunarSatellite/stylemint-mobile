import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';

abstract class NotificationsRepository {
  /// Recent activity for the signed-in creator, newest first.
  /// Source: `GET /v1/creator/activity`.
  Future<Either<NetworkExceptions, List<ActivityItem>>> getRecentActivity({
    int pageSize,
  });
}
