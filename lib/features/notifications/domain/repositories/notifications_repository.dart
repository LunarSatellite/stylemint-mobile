import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';

abstract class NotificationsRepository {
  /// Recent activity for the signed-in user, newest first, from the
  /// notification inbox (`GET /api/v1/notifications/inbox`).
  Future<Either<NetworkExceptions, List<ActivityItem>>> getRecentActivity({
    int pageSize,
  });
}
