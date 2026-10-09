import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/delivery_confirmation_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/delivery_confirmation_repository.dart';

class DeliveryConfirmationRepositoryImpl
    implements DeliveryConfirmationRepository {
  DeliveryConfirmationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final DeliveryConfirmationRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<DeliveryConfirmFailure, DeliveryConfirmation>> confirmByQr(
    String qrPayload,
  ) => _confirm({'qrPayload': qrPayload});

  @override
  Future<Either<DeliveryConfirmFailure, DeliveryConfirmation>> confirmByCode({
    required String packageNumber,
    required String code,
  }) => _confirm({'packageNumber': packageNumber, 'code': code});

  Future<Either<DeliveryConfirmFailure, DeliveryConfirmation>> _confirm(
    Map<String, dynamic> body,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const DeliveryConfirmOtherFailure(offline: true));
    }
    try {
      final json = await remoteDataSource.confirm(
        body: body,
        idempotencyKey: _uuid.v4(),
      );
      return right(confirmationFromJson(json));
    } on DioException catch (e) {
      return left(failureFromDio(e));
    } on Object {
      return left(const DeliveryConfirmOtherFailure());
    }
  }

  /// `200 { orderId, subOrderId, packageNumber, status, deliveredUtc }`.
  static DeliveryConfirmation confirmationFromJson(Map<String, dynamic> json) =>
      DeliveryConfirmation(
        orderId: _text(json['orderId']) ?? '',
        subOrderId: _text(json['subOrderId']) ?? '',
        packageNumber: _text(json['packageNumber']) ?? '',
        status: _text(json['status']) ?? 'Delivered',
        deliveredUtc: switch (json['deliveredUtc']) {
          final String v => DateTime.tryParse(v)?.toUtc(),
          _ => null,
        },
      );

  /// The contract's `delivery_proof.*` codes first, then the statuses they
  /// travel with for a server that left the code out.
  static DeliveryConfirmFailure failureFromDio(DioException e) {
    final response = e.response;
    if (response == null) {
      return switch (e.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          const DeliveryConfirmOtherFailure(offline: true),
        _ => const DeliveryConfirmOtherFailure(),
      };
    }
    final body = response.data;
    final code = body is Map ? _text(body['errorCode'])?.toLowerCase() : null;
    switch (code) {
      case 'delivery_proof.not_recipient':
        return const DeliveryConfirmNotRecipient();
      case 'delivery_proof.expired':
        return const DeliveryConfirmExpired();
      case 'delivery_proof.invalid':
        return const DeliveryConfirmInvalid();
      case 'delivery_proof.too_many_attempts':
        return const DeliveryConfirmTooManyAttempts();
      case 'delivery_proof.already_confirmed':
        return const DeliveryConfirmAlreadyConfirmed();
    }
    final status = response.statusCode ?? 0;
    if (code == null && status == 403) return const DeliveryConfirmNotRecipient();
    if (code == null && status == 429) {
      return const DeliveryConfirmTooManyAttempts();
    }
    if (code == null && (status == 400 || status == 404 || status == 422)) {
      return const DeliveryConfirmInvalid();
    }
    final message = body is Map
        ? _text(body['detail']) ?? _text(body['title'])
        : null;
    return DeliveryConfirmOtherFailure(
      // A 5xx body is often a gateway's HTML page — never shown.
      message: status >= 500 ? null : message,
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
