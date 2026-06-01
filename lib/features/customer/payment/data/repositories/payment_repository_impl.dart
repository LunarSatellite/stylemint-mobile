import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/data/datasources/payment_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final PaymentRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<PaymentMethod>>> getPaymentMethods() async {
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
  Future<Either<NetworkExceptions, PaymentMethod>> addCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String cardholderName,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.addCard(
          cardNumber: cardNumber,
          expiry: expiry,
          cvv: cvv,
          cardholderName: cardholderName,
          idempotencyKey: _uuid.v4(),
        );
        return right(dto.toDomain());
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
  Future<Either<NetworkExceptions, Unit>> deletePaymentMethod(String id) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePaymentMethod(id);
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
}
