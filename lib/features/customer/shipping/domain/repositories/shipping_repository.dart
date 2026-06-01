import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/entities/shipping_address.dart';

abstract interface class ShippingRepository {
  Future<Either<NetworkExceptions, List<ShippingAddress>>> getAddresses();

  Future<Either<NetworkExceptions, ShippingAddress>> addAddress(ShippingAddress address);

  Future<Either<NetworkExceptions, ShippingAddress>> updateAddress(
    String id,
    ShippingAddress address,
  );

  Future<Either<NetworkExceptions, Unit>> deleteAddress(String id);

  Future<Either<NetworkExceptions, Unit>> setDefault(String id);
}
