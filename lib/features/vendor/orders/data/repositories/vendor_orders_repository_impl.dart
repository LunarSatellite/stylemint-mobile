import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_return_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/bulk_action_result.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/packing_slip.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
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
            .map(
              (e) =>
                  VendorOrderDto.fromJson(e as Map<String, dynamic>).toDomain(),
            )
            .toList(growable: false);
        return right(
          PagedResult(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? limit,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
          ),
        );
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
  Future<Either<NetworkExceptions, int>> getSubOrderCount(int state) async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getSubOrderCount(state);
        return right(count);
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
  Future<Either<NetworkExceptions, VendorOrder>> getOrderDetail(
    String orderId,
  ) async {
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
  Future<Either<NetworkExceptions, PagedResult<VendorReturnRequest>>>
  listReturns({
    VendorReturnRequestState? state,
    String? cursor,
    int pageSize = 25,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.listReturns(
          state: state == null ? null : _stateToCode(state),
          cursor: cursor,
          pageSize: pageSize,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => VendorReturnRequestDto.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList(growable: false);
        return right(
          PagedResult(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? pageSize,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
          ),
        );
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
  Future<Either<NetworkExceptions, VendorReturnRequest>> acceptReturn(
    String returnRequestId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.acceptReturn(
          returnRequestId,
          _uuid.v4(),
        );
        return right(VendorReturnRequestDto.fromJson(data).toDomain());
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
  Future<Either<NetworkExceptions, VendorReturnRequest>> rejectReturn(
    String returnRequestId,
    String reason,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.rejectReturn(
          returnRequestId,
          reason,
          _uuid.v4(),
        );
        return right(VendorReturnRequestDto.fromJson(data).toDomain());
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

  /// Inverse of [VendorReturnRequestDto._stateFromCode] — backend
  /// `ReturnRequestState`: Submitted=1, Approved=2, Rejected=3, Completed=4.
  static int _stateToCode(VendorReturnRequestState state) => switch (state) {
    VendorReturnRequestState.submitted => 1,
    VendorReturnRequestState.approved => 2,
    VendorReturnRequestState.rejected => 3,
    VendorReturnRequestState.completed => 4,
  };

  @override
  Future<Either<NetworkExceptions, VendorOrder>> markReadyToShip(
    String orderId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.markReadyToShip(
          orderId,
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
  Future<Either<NetworkExceptions, VendorOrder>> addTracking(
    String orderId, {
    required String carrier,
    required String trackingNumber,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.addTracking(
          orderId,
          carrier,
          trackingNumber,
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
  Future<Either<NetworkExceptions, VendorOrder>> markDelivered(
    String orderId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.markDelivered(orderId, _uuid.v4());
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
  Future<Either<NetworkExceptions, PackingSlip>> getPackingSlip(
    String orderId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.getPackingSlip(orderId);
        return right(_parsePackingSlip(orderId, json));
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
  Future<Either<NetworkExceptions, BulkActionResult>> bulkMarkReadyToShip(
    List<String> orderIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.bulkReadyToShip(
          orderIds,
          _uuid.v4(),
        );
        return right(_parseBulkResult(json, orderIds));
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
  Future<Either<NetworkExceptions, BulkActionResult>> bulkPackingSlips(
    List<String> orderIds,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.bulkPackingSlips(orderIds);
        return right(_parseBulkResult(json, orderIds));
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

  /// Maps the backend `PackingSlipDto`: its lines are published as `items`
  /// and its delivery address as `shipTo`.
  static PackingSlip _parsePackingSlip(
    String orderId,
    Map<String, dynamic> json,
  ) {
    final shipTo = json['shipTo'] as Map<String, dynamic>?;
    final lines =
        (json['lines'] as List<dynamic>? ??
                json['items'] as List<dynamic>? ??
                const <dynamic>[])
            .cast<Map<String, dynamic>>();
    return PackingSlip(
      orderId: orderId,
      orderNumber: json['orderNumber'] as String? ?? '',
      packingSlipNumber: json['packingSlipNumber'] as String?,
      receiverName: shipTo?['receiverName'] as String?,
      shippingAddress: _formatAddress(shipTo),
      carrier: json['carrier'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      items: lines
          .map(
            (l) => PackingSlipItem(
              productName:
                  (l['productTitleSnapshot'] as String?) ??
                  (l['productName'] as String?) ??
                  '',
              quantity: (l['quantity'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList(growable: false),
    );
  }

  static String? _formatAddress(Map<String, dynamic>? a) {
    if (a == null) return null;
    final parts = <String>[
      (a['addressLine1'] as String?) ?? '',
      (a['city'] as String?) ?? '',
      [
        (a['state'] as String?) ?? '',
        (a['zipCode'] as String?) ?? '',
      ].where((s) => s.isNotEmpty).join(' '),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// Confirmed against `BulkResult<T>` (backend `Shared.Core.Results`): each
  /// row is `{index, success, value, errorCode, errorMessage, field}` — the
  /// requested sub-order id is NOT echoed back directly, so rows are
  /// correlated to `requestedIds` by their submitted `index`, falling back to
  /// `value.subOrderId` if the index is ever missing or out of range.
  static BulkActionResult _parseBulkResult(
    Map<String, dynamic> json,
    List<String> requestedIds,
  ) {
    final rows =
        (json['items'] as List<dynamic>? ??
                json['results'] as List<dynamic>? ??
                const <dynamic>[])
            .cast<Map<String, dynamic>>();
    if (rows.isEmpty) {
      return BulkActionResult(succeededIds: requestedIds, failed: const {});
    }
    final succeeded = <String>[];
    final failed = <String, String>{};
    for (final row in rows) {
      final index = row['index'] as int?;
      final value = row['value'] as Map<String, dynamic>?;
      final id = (index != null && index >= 0 && index < requestedIds.length)
          ? requestedIds[index]
          : (value?['subOrderId'] as String?) ??
                (row['id'] as String?) ??
                (row['subOrderId'] as String?) ??
                '';
      final errorCode = row['errorCode'] as String? ?? row['error'] as String?;
      if (errorCode == null) {
        succeeded.add(id);
      } else {
        failed[id] = errorCode;
      }
    }
    return BulkActionResult(succeededIds: succeeded, failed: failed);
  }
}
