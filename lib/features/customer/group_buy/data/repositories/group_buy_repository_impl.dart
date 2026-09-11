import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/data/datasources/group_buy_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/data/models/group_buy_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/entities/group_buy.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/repositories/group_buy_repository.dart';

class GroupBuyRepositoryImpl implements GroupBuyRepository {
  GroupBuyRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final GroupBuyRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<GroupBuy>>> getActiveForProduct(
    String productId,
  ) async {
    final either = await _call(() async {
      final data = await remoteDataSource.listActive(pageSize: 50);
      return _itemsFrom(data)
          .where((g) => g.productId == productId)
          .toList(growable: false);
    });
    return either;
  }

  @override
  Future<Either<NetworkExceptions, List<GroupBuy>>> getMine() async {
    return _call(() async {
      final data = await remoteDataSource.listMine(pageSize: 50);
      return _itemsFrom(data);
    });
  }

  @override
  Future<Either<NetworkExceptions, GroupBuy>> start({
    required String productId,
    required int targetBuyerCount,
    required double discountPercent,
    required DateTime expiresAt,
  }) async {
    return _call(() async {
      final json = await remoteDataSource.start(
        productId: productId,
        targetBuyerCount: targetBuyerCount,
        discountPercent: discountPercent,
        expiresUtc: expiresAt,
        idempotencyKey: _uuid.v4(),
      );
      return GroupBuyDto.fromJson(json).toDomain();
    });
  }

  @override
  Future<Either<NetworkExceptions, GroupBuy>> join(String groupBuyId) async {
    return _call(() async {
      final json = await remoteDataSource.join(groupBuyId, _uuid.v4());
      return GroupBuyDto.fromJson(json).toDomain();
    });
  }

  List<GroupBuy> _itemsFrom(Map<String, dynamic> data) =>
      (data['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => GroupBuyDto.fromJson(e as Map<String, dynamic>).toDomain())
          .toList(growable: false);

  Future<Either<NetworkExceptions, T>> _call<T>(
    Future<T> Function() body,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await body());
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
}
