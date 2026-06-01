import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';

abstract interface class AddProductRepository {
  Future<Either<NetworkExceptions, ProductDraft>> saveDraft(ProductDraft draft);
  Future<Either<NetworkExceptions, ProductDraft>> updateDraft(String id, ProductDraft draft);
  Future<Either<NetworkExceptions, String>> uploadImage(String filePath);
  Future<Either<NetworkExceptions, String>> publishProduct(String draftId);
}
