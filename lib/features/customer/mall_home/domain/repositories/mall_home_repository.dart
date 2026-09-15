import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';

abstract interface class MallHomeRepository {
  /// `GET api/v1/public/home` — personalised when signed in.
  Future<Either<NetworkExceptions, MallHome>> getHome();

  /// `POST api/v1/customer/recently-viewed` — fire-and-forget.
  Future<Either<NetworkExceptions, Unit>> recordRecentlyViewed(
    String productId,
  );
}
