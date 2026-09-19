import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  CheckoutRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.cartRepository,
  });

  final CheckoutRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  final CartRepository cartRepository;

  static const _zeroCart = Cart(
    id: '',
    items: [],
    subtotal: Money(amount: 0, currency: 'NPR'),
    shippingTotal: Money(amount: 0, currency: 'NPR'),
    taxTotal: Money(amount: 0, currency: 'NPR'),
    total: Money(amount: 0, currency: 'NPR'),
  );

  @override
  Future<Either<NetworkExceptions, CheckoutSummary>>
  getCheckoutSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getCheckoutSummary();
        // The session's own totals are null until Place (Draft state) — fall
        // back to the cart's totals for initial display.
        final cartEither = await cartRepository.getCart();
        final cart = cartEither.fold((_) => _zeroCart, (c) => c);
        return right(dto.toDomain(fallback: cart));
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 400) {
            final data = e.response?.data;
            final code = data is Map ? data['errorCode'] as String? : null;
            if (code != null)
              return left(NetworkExceptions.validation(code: code));
          }
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
  Future<Either<NetworkExceptions, DeliveryChoices>>
  getDeliveryChoices() async {
    if (!await networkInfo.isConnected)
      return left(NetworkExceptions.noInternetConnection());
    try {
      return right(await remoteDataSource.getDeliveryChoices());
    } catch (e) {
      if (e is DioException) return left(mapDioExceptionToNetworkException(e));
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> selectDeliveryChoice(
    DeliveryChoice choice,
  ) async {
    if (!await networkInfo.isConnected)
      return left(NetworkExceptions.noInternetConnection());
    try {
      await remoteDataSource.selectDeliveryChoice(choice);
      return right(unit);
    } catch (e) {
      if (e is DioException) return left(mapDioExceptionToNetworkException(e));
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, DeliveryPreference>>
  updateDeliveryPreference(DeliveryPreference preference) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await remoteDataSource.updateDeliveryPreference(preference));
    } catch (e) {
      if (e is DioException) return left(mapDioExceptionToNetworkException(e));
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<ShippingAddress>>>
  getShippingAddresses() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getShippingAddresses();
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
  Future<Either<NetworkExceptions, List<PaymentMethod>>>
  getPaymentMethods() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getPaymentMethods();
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
  Future<Either<NetworkExceptions, PlaceOrderResult>> placeOrder({
    required String? addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.placeOrder(
          addressId: addressId,
          paymentMethod: paymentMethod,
          idempotencyKey: idempotencyKey,
        );
        return right(result);
      } catch (e) {
        if (e is DioException) {
          return left(mapDioExceptionToNetworkException(e));
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
