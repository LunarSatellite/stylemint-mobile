import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/data/datasources/group_cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/repositories/group_cart_repository.dart';

class GroupCartRepositoryImpl implements GroupCartRepository {
  GroupCartRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final GroupCartRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<GroupCart>>> getGroupCarts() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getGroupCarts();
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
  Future<Either<NetworkExceptions, GroupCart>> getGroupCart(String cartId) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getGroupCart(cartId);
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
  Future<Either<NetworkExceptions, GroupCart>> createGroupCart(String name) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createGroupCart(name, _uuid.v4());
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
  Future<Either<NetworkExceptions, GroupCart>> joinGroupCart(String inviteCode) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.joinGroupCart(inviteCode, _uuid.v4());
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
  Future<Either<NetworkExceptions, GroupCartItem>> addToGroupCart(
    String cartId,
    String productId,
    int qty,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.addToGroupCart(
          cartId,
          productId,
          qty,
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
  Future<Either<NetworkExceptions, Unit>> removeFromGroupCart(
    String cartId,
    String itemId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removeFromGroupCart(cartId, itemId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> checkoutGroupCart(String cartId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.checkoutGroupCart(cartId, _uuid.v4());
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
