import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final OrdersRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<TrackedOrder>>> getTrackedOrders({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getTrackedOrders(
          limit: limit,
          cursor: cursor,
        );
        return right(dtos.map((dto) => dto.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, OrderDetail>> getOrderDetail(String orderId) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getOrderDetail(orderId);
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
  Future<Either<NetworkExceptions, Unit>> cancelOrder(
    String orderId, {
    required OrderCancellationReason reason,
    String? note,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.cancelOrder(
          orderId,
          _uuid.v4(),
          reason: reason.value,
          note: note,
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

  @override
  Future<Either<NetworkExceptions, Unit>> requestReturn(String orderId, String reason) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.requestReturn(orderId, reason, _uuid.v4());
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
