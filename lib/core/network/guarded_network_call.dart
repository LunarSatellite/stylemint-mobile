import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';

/// Runs a repository [call]. Offline is `noInternetConnection` without
/// calling the API, a [DioException] goes through the shared mapper (404 is
/// `notFound`, 5xx `serverUnavailable`, 4xx keeps the backend's message), and
/// a malformed payload or anything unexpected is `unexpectedError`.
Future<Either<NetworkExceptions, T>> guardedNetworkCall<T>(
  NetworkInfoConnectivity networkInfo,
  Future<T> Function() call,
) async {
  try {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    return right(await call());
  } on DioException catch (e) {
    return left(mapDioExceptionToNetworkException(e));
  } on NetworkExceptions catch (e) {
    return left(e);
  } on Object catch (_) {
    return left(const NetworkExceptions.unexpectedError());
  }
}
