import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class VendorOrdersRepositoryImpl implements VendorOrdersRepository {
  VendorOrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorOrdersRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<VendorOrder>>> getOrders({
    int limit = 20,
    String? cursor,
    String? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getOrders(
          limit: limit,
          cursor: cursor,
          status: status,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => VendorOrderDto.fromJson(e as Map<String, dynamic>).toDomain())
            .toList(growable: false);
        return right(PagedResult(
          items: items,
          totalCount: data['totalCount'] as int? ?? items.length,
          pageSize: data['pageSize'] as int? ?? limit,
          nextCursor: data['nextCursor'] as String?,
          previousCursor: data['previousCursor'] as String?,
          hasMore: data['hasMore'] as bool? ?? false,
        ));
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
  Future<Either<NetworkExceptions, VendorOrder>> getOrderDetail(String orderId) async {
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
  Future<Either<NetworkExceptions, VendorOrder>> updateOrderStatus(
    String orderId,
    VendorOrderStatus newStatus,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.updateOrderStatus(
          orderId,
          newStatus.name,
          _uuid.v4(),
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
  Future<Either<NetworkExceptions, Unit>> handleReturn(
    String orderId,
    String action,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.handleReturn(orderId, action, _uuid.v4());
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
