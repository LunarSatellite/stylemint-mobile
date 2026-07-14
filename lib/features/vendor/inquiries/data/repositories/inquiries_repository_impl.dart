import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/datasources/inquiries_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/entities/product_inquiry.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/repositories/inquiries_repository.dart';

class InquiriesRepositoryImpl implements InquiriesRepository {
  InquiriesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final InquiriesRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<ProductInquiry>>> listVendor({
    int pageSize = 50,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.listVendor(pageSize: pageSize);
        return right(dtos.map((d) => d.toDomain()).toList());
      } on DioException catch (e) {
        return left(NetworkExceptions.server(e.message.toString()));
      } on NetworkExceptions catch (e) {
        return left(e);
      } on Object catch (_) {
        return left(const NetworkExceptions.unexpectedError());
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, int>> getVendorInquiryCount() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getVendorInquiryCount();
        return right(count);
      } on DioException catch (e) {
        return left(NetworkExceptions.server(e.message.toString()));
      } on NetworkExceptions catch (e) {
        return left(e);
      } on Object catch (_) {
        return left(const NetworkExceptions.unexpectedError());
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, ProductInquiry>> reply(
    String inquiryId,
    String text,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.reply(inquiryId, text);
        return right(dto.toDomain());
      } on DioException catch (e) {
        return left(NetworkExceptions.server(e.message.toString()));
      } on NetworkExceptions catch (e) {
        return left(e);
      } on Object catch (_) {
        return left(const NetworkExceptions.unexpectedError());
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }
}
