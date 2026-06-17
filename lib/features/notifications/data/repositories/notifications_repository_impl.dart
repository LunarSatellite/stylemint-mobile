import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({required this.remoteDataSource});

  final NotificationsRemoteDataSource remoteDataSource;

  @override
  Future<Either<NetworkExceptions, List<ActivityItem>>> getRecentActivity({
    int pageSize = 20,
  }) async {
    try {
      final dtos = await remoteDataSource.getInbox(pageSize: pageSize);
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
