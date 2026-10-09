import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
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
      final items = await remoteDataSource.getCreatorActivity(
        pageSize: pageSize,
      );
      return right(items);
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<ActivityItem>>> getInbox({
    int pageSize = 30,
  }) async {
    try {
      final rows = await remoteDataSource.getInbox(pageSize: pageSize);
      return right(rows.map((row) => row.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
