import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/customer_return_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/carbon_impact.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
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
  Future<Either<NetworkExceptions, OrderDetail>> getOrderDetail(
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
  Future<Either<NetworkExceptions, OrderInvoice>> getOrderInvoice(
    String orderNumber,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getOrderInvoice(orderNumber);
      return right(dto.toDomain());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      }
      if (e is NetworkExceptions) return left(e);
      return left(NetworkExceptions.unexpectedError());
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
  Future<Either<NetworkExceptions, OrderTimeline>> getOrderTimeline(
    String orderNumber,
  ) => guardedNetworkCall(
    networkInfo,
    () async =>
        (await remoteDataSource.getOrderTimeline(orderNumber)).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, PagedResult<CustomerReturn>>> getMyReturns({
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(networkInfo, () async {
    final data = await remoteDataSource.getMyReturns(
      pageSize: pageSize,
      cursor: cursor,
    );
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) =>
              CustomerReturnDto.fromJson(e as Map<String, dynamic>).toDomain(),
        )
        .toList(growable: false);
    final nextCursor = data['nextCursor'] as String?;
    return PagedResult<CustomerReturn>(
      items: items,
      totalCount: (data['totalCount'] as num?)?.toInt() ?? items.length,
      pageSize: (data['pageSize'] as num?)?.toInt() ?? pageSize,
      nextCursor: nextCursor,
      previousCursor: data['previousCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? nextCursor != null,
    );
  });

  @override
  Future<Either<NetworkExceptions, CustomerReturn>> getReturn(
    String returnId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getReturn(returnId)).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, List<ReplacementOption>>>
  getReplacementOptions(String originalVariantId) => guardedNetworkCall(
    networkInfo,
    () => remoteDataSource.getReplacementOptions(originalVariantId),
  );

  @override
  Future<Either<NetworkExceptions, String?>> requestReturn(
    String orderId, {
    required String subOrderId,
    required String subOrderLineId,
    required int quantity,
    required String reason,
    required List<String> photoUrls,
    ReturnResolutionChoice resolution = ReturnResolutionChoice.refund,
    String? replacementVariantId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final returnId = await remoteDataSource.requestReturn(
          orderId,
          subOrderId,
          subOrderLineId,
          quantity,
          reason,
          photoUrls,
          resolution == ReturnResolutionChoice.replacement ? 2 : 1,
          replacementVariantId,
          _uuid.v4(),
        );
        return right(returnId);
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
  Future<Either<NetworkExceptions, String>> uploadReturnPhoto(
    String filePath,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final url = await remoteDataSource.uploadReturnPhoto(filePath);
      return right(url);
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(NetworkExceptions.unexpectedError());
      }
    }
  }

  @override
  Future<Either<NetworkExceptions, bool>> getReplenishmentPreference() async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await remoteDataSource.getReplenishmentPreference());
    } catch (error) {
      return left(mapDioExceptionToNetworkException(error));
    }
  }

  @override
  Future<Either<NetworkExceptions, bool>> setReplenishmentPreference(
    bool enabled,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(
        await remoteDataSource.setReplenishmentPreference(enabled, _uuid.v4()),
      );
    } catch (error) {
      return left(mapDioExceptionToNetworkException(error));
    }
  }

  @override
  Future<Either<NetworkExceptions, List<ReorderSuggestionDto>>>
  getReorderSuggestions() async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final suggestions = await remoteDataSource.getReorderSuggestions();
      return right(suggestions);
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(NetworkExceptions.unexpectedError());
      }
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> dismissReorderSuggestion(
    String productId,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.dismissReorderSuggestion(productId);
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
  }

  @override
  Future<Either<NetworkExceptions, CarbonImpact>> getCarbonImpact() async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getCarbonImpact();
      return right(dto.toDomain());
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          return left(const NetworkExceptions.notFound());
        }
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(const NetworkExceptions.unexpectedError());
      }
    }
  }

  @override
  Future<Either<NetworkExceptions, OrderCarePlan>> getOrderCarePlan(
    String orderNumber,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getOrderCarePlan(orderNumber);
      return right(dto.toDomain());
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          return left(const NetworkExceptions.notFound());
        }
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(const NetworkExceptions.unexpectedError());
      }
    }
  }

  @override
  Future<Either<NetworkExceptions, WarrantyClaim>> submitWarrantyClaim({
    required String orderNumber,
    required String subOrderLineId,
    required WarrantyIssueKind issueKind,
    required String description,
    List<String> evidenceUrls = const [],
  }) => _deliveryCall(
    () async => (await remoteDataSource.submitWarrantyClaim(
      orderNumber: orderNumber,
      subOrderLineId: subOrderLineId,
      issueKind: issueKind,
      description: description,
      evidenceUrls: evidenceUrls,
      idempotencyKey: _uuid.v4(),
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, List<WarrantyClaim>>> getWarrantyClaims() =>
      _deliveryCall(
        () async => (await remoteDataSource.getWarrantyClaims())
            .map((dto) => dto.toDomain())
            .toList(growable: false),
      );
  @override
  Future<Either<NetworkExceptions, DeliveryPackageStatus>>
  getDeliveryPackageStatus(String trackingNumber) => _deliveryCall(
    () async => (await remoteDataSource.getDeliveryPackageStatus(
      trackingNumber,
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, DeliveryAcceptance>> getDeliveryAcceptance(
    String trackingNumber,
  ) => _deliveryCall(
    () async => (await remoteDataSource.getDeliveryAcceptance(
      trackingNumber,
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, DeliveryAcceptance>>
  recordDeliveryAcceptance(
    String trackingNumber, {
    required DeliveryAcceptanceOutcome outcome,
    bool? sealIntact,
    String? issueNote,
    List<DeliveryReceivedItemInput> receivedItems =
        const <DeliveryReceivedItemInput>[],
    String? scannedTrackingCode,
  }) => _deliveryCall(
    () async => (await remoteDataSource.recordDeliveryAcceptance(
      trackingNumber,
      // A fresh key per send; the backend treats the same outcome sent
      // again as a harmless repeat and a different one as a 409.
      _uuid.v4(),
      outcome: outcome,
      sealIntact: sealIntact,
      issueNote: issueNote,
      receivedItems: receivedItems,
      scannedTrackingCode: scannedTrackingCode,
    )).toDomain(),
  );

  /// Delivery acceptance calls keep 404 and 409 apart (the acceptance card
  /// acts on both) and keep the backend's validation sentence for 400s.
  Future<Either<NetworkExceptions, T>> _deliveryCall<T>(
    Future<T> Function() call,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return left(const NetworkExceptions.noInternetConnection());
      }
      return right(await call());
    } on DioException catch (e) {
      return left(switch (e.response?.statusCode) {
        404 => const NetworkExceptions.notFound(),
        409 => const NetworkExceptions.conflict(),
        _ => mapDioExceptionToNetworkException(e),
      });
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (_) {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
