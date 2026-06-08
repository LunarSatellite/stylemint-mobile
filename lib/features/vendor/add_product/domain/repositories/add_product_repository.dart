import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';

abstract interface class AddProductRepository {
  /// Real catalog categories for the Step-1 picker.
  Future<Either<NetworkExceptions, List<CategoryOption>>> fetchCategories();

  /// Creates the draft and fills steps 2-4, returning the new product id.
  Future<Either<NetworkExceptions, String>> submitDraft(ProductDraft draft);

  Future<Either<NetworkExceptions, String>> uploadImage(String filePath);

  Future<Either<NetworkExceptions, String>> publishProduct(String productId);
}
