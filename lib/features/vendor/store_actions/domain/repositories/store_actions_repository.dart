import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/entities/store_actions.dart';

abstract class StoreActionsRepository {
  /// The signed-in vendor's ranked store to-do list, computed fresh.
  Future<Either<NetworkExceptions, StoreActionQueue>> getStoreActions();
}
