import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:uuid/uuid.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({required this.remoteDataSource});

  final CartRemoteDataSource remoteDataSource;
  static const _uuid = Uuid();

  // Dio's own connectionError/timeout types already cover "no internet" —
  // a client-side pre-flight connectivity check was previously gating every
  // call here and, when it misfired, silently skipped the request entirely
  // (no error, no retry, request never left the device).
  NetworkExceptions _mapError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return NetworkExceptions.noInternetConnection();
      }
      return NetworkExceptions.server(e.message.toString());
    } else if (e is NetworkExceptions) {
      return e;
    }
    return NetworkExceptions.unexpectedError();
  }

  @override
  Future<Either<NetworkExceptions, Cart>> getCart() async {
    try {
      final dto = await remoteDataSource.getCart();
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
    String? reelTagContextId,
    required String idempotencyKey,
  }) async {
    try {
      final dto = await remoteDataSource.addToCart(
        productId: productId,
        quantity: quantity,
        variantId: variantId,
        reelTagContextId: reelTagContextId,
        idempotencyKey: idempotencyKey,
      );
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    try {
      final dto = await remoteDataSource.updateCartItem(
        itemId: itemId,
        quantity: quantity,
      );
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> removeCartItem(String itemId) async {
    try {
      final dto = await remoteDataSource.removeCartItem(itemId);
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> applyPromo(String code) async {
    try {
      final dto = await remoteDataSource.applyPromo(
        code: code,
        idempotencyKey: _uuid.v4(),
      );
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> removePromo() async {
    try {
      final dto = await remoteDataSource.removePromo(_uuid.v4());
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, Cart>> saveForLater(String lineId) async {
    try {
      await remoteDataSource.saveForLater(
        lineId: lineId,
        idempotencyKey: _uuid.v4(),
      );
      final dto = await remoteDataSource.getCart();
      return right(dto.toDomain());
    } catch (e) {
      return left(_mapError(e));
    }
  }
}
