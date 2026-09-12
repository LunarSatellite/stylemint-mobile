import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';

abstract interface class LiveCommerceRepository {
  Future<Either<NetworkExceptions, List<LiveSession>>> getLive();

  Future<Either<NetworkExceptions, List<LiveSession>>> getUpcoming();

  Future<Either<NetworkExceptions, LiveSession>> getById(String id);
}
