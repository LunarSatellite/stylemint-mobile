import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class SavedItemsRepository {
  Future<Either<NetworkExceptions, PagedResult<SavedItem>>> getSavedItems({
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, Unit>> saveItem(String productId);

  Future<Either<NetworkExceptions, Unit>> removeItem(String savedItemId);
}
