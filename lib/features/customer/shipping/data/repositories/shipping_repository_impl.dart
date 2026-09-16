import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/datasources/shipping_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/models/shipping_address_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/repositories/shipping_repository.dart';
import 'package:uuid/uuid.dart';

class ShippingRepositoryImpl implements ShippingRepository {
  ShippingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ShippingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  /// Runs [body] behind a connectivity check, mapping anything thrown to a
  /// [NetworkExceptions]. Uses the shared RFC 7807 mapper so a 400 keeps its
  /// `field`/`errors[]` — the resolve-link screen needs the server's own
  /// `mapsLink` message, not a flattened `DioException.message`.
  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() body,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await body());
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object catch (e) {
      return left(mapDioExceptionToNetworkException(e));
    }
  }

  @override
  Future<Either<NetworkExceptions, List<ShippingAddress>>>
  getAddresses() async => _guard(() async {
    final dtos = await remoteDataSource.getAddresses();
    return dtos.map((d) => d.toDomain()).toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, ShippingAddress>> addAddress(
    ShippingAddress address,
  ) async => _guard(() async {
    final result = await remoteDataSource.addAddress(
      ShippingAddressDto.writeBody(address),
      _uuid.v4(),
    );
    return result.toDomain();
  });

  @override
  Future<Either<NetworkExceptions, ShippingAddress>> updateAddress(
    String id,
    ShippingAddress address,
  ) async => _guard(() async {
    final result = await remoteDataSource.updateAddress(
      id,
      ShippingAddressDto.writeBody(address, includeMakeDefault: false),
      _uuid.v4(),
    );
    return result.toDomain();
  });

  @override
  Future<Either<NetworkExceptions, ResolvedMapsLink>> resolveMapsLink(
    String url,
  ) async => _guard(() async {
    final result = await remoteDataSource.resolveLink(url);
    return result.toDomain();
  });

  @override
  Future<Either<NetworkExceptions, Unit>> deleteAddress(String id) async =>
      _guard(() async {
        await remoteDataSource.deleteAddress(id);
        return unit;
      });

  @override
  Future<Either<NetworkExceptions, Unit>> setDefault(String id) async =>
      _guard(() async {
        await remoteDataSource.setDefault(id, _uuid.v4());
        return unit;
      });
}
