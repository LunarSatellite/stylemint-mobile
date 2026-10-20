import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/service_cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/service_failure_mapper.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/service_cart_repository.dart';

class ServiceCartRepositoryImpl implements ServiceCartRepository {
  ServiceCartRepositoryImpl({required this.remote, required this.networkInfo});

  final ServiceCartRemoteDataSource remote;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<ServiceFailure, Cart>> addToCart({
    required String productId,
    required ServiceOptions options,
    required String idempotencyKey,
    String? variantId,
    String? reelTagContextId,
  }) => guardedServiceCall(networkInfo, () async {
    final dto = await remote.addService(
      productId: productId,
      options: options,
      idempotencyKey: idempotencyKey,
      variantId: variantId,
      reelTagContextId: reelTagContextId,
    );
    return dto.toDomain();
  });

  @override
  Future<Either<ServiceFailure, List<ServiceLine>>> setGuests({
    required String sessionId,
    required List<ServiceGuests> lines,
    required String idempotencyKey,
  }) => guardedServiceCall(
    networkInfo,
    () => remote.setGuests(
      sessionId: sessionId,
      lines: lines,
      idempotencyKey: idempotencyKey,
    ),
  );
}
