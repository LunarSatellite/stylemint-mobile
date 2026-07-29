import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/datasources/subscription_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/account_subscription_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/subscription_plan_dto.dart';

/// Domain repository for subscription plans / current subscription.
class SubscriptionRepository {
  SubscriptionRepository({required this.remote});

  final SubscriptionRemoteDataSource remote;

  Future<Either<NetworkExceptions, List<SubscriptionPlanDto>>> listPlans() async {
    try {
      return Right(await remote.listPlans());
    } catch (e) {
      return Left(mapDioExceptionToNetworkException(e));
    }
  }

  Future<Either<NetworkExceptions, AccountSubscriptionDto?>> getMine() async {
    try {
      return Right(await remote.getMine());
    } catch (e) {
      return Left(mapDioExceptionToNetworkException(e));
    }
  }

  Future<Either<NetworkExceptions, AccountSubscriptionDto>> upgrade({
    required String planId,
  }) async {
    try {
      return Right(await remote.upgrade(planId: planId));
    } catch (e) {
      return Left(mapDioExceptionToNetworkException(e));
    }
  }
}
