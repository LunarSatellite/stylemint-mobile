import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/datasources/add_product_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/models/product_form_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/repositories/add_product_repository.dart';

class AddProductRepositoryImpl implements AddProductRepository {
  AddProductRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final AddProductRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, ProductDraft>> saveDraft(ProductDraft draft) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = ProductDraftDto.fromDomain(draft);
        final result = await remoteDataSource.saveDraft(dto, _uuid.v4());
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
  Future<Either<NetworkExceptions, ProductDraft>> updateDraft(
    String id,
    ProductDraft draft,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = ProductDraftDto.fromDomain(draft);
        final result = await remoteDataSource.updateDraft(id, dto, _uuid.v4());
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
  Future<Either<NetworkExceptions, String>> uploadImage(String filePath) async {
    if (await networkInfo.isConnected) {
      try {
        final url = await remoteDataSource.uploadImage(filePath);
        return right(url);
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
  Future<Either<NetworkExceptions, String>> publishProduct(String draftId) async {
    if (await networkInfo.isConnected) {
      try {
        final productId = await remoteDataSource.publishProduct(draftId, _uuid.v4());
        return right(productId);
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
