import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/datasources/shipping_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/models/shipping_address_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/repositories/shipping_repository.dart';

class ShippingRepositoryImpl implements ShippingRepository {
  ShippingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ShippingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<ShippingAddress>>> getAddresses() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getAddresses();
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, ShippingAddress>> addAddress(
    ShippingAddress address,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = _toDto(address);
        final result = await remoteDataSource.addAddress(dto, _uuid.v4());
        return right(result.toDomain());
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
  Future<Either<NetworkExceptions, ShippingAddress>> updateAddress(
    String id,
    ShippingAddress address,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = _toDto(address);
        final result = await remoteDataSource.updateAddress(id, dto, _uuid.v4());
        return right(result.toDomain());
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
  Future<Either<NetworkExceptions, Unit>> deleteAddress(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteAddress(id);
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
  Future<Either<NetworkExceptions, Unit>> setDefault(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.setDefault(id, _uuid.v4());
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

  ShippingAddressDto _toDto(ShippingAddress address) => ShippingAddressDto(
    id: address.id,
    label: address.label,
    fullName: address.fullName,
    phone: address.phone,
    addressLine1: address.addressLine1,
    addressLine2: address.addressLine2,
    city: address.city,
    state: address.state,
    zipCode: address.zipCode,
    isDefault: address.isDefault,
  );
}
