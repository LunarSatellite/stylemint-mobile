import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_items_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/models/saved_item_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/repositories/saved_items_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class SavedItemsRepositoryImpl implements SavedItemsRepository {
  SavedItemsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final SavedItemsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<SavedItem>>> getSavedItems({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final list = await remoteDataSource.getSavedItems();
        final items = list
            .map((e) =>
                SavedItemDto.fromJson(e as Map<String, dynamic>).toDomain())
            .toList(growable: false);
        // The endpoint returns the full per-account list in one shot.
        return right(PagedResult<SavedItem>(
          items: items,
          totalCount: items.length,
          pageSize: items.length,
          nextCursor: null,
          previousCursor: null,
          hasMore: false,
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
  Future<Either<NetworkExceptions, Unit>> saveItem(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveItem(productId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> removeItem(String savedItemId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removeItem(savedItemId, _uuid.v4());
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
