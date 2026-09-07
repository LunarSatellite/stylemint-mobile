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

  /// Existing image CDN URLs for an already-created product, for the Edit
  /// Product Images flow.
  Future<Either<NetworkExceptions, List<String>>> fetchProductImages(
    String productId,
  );

  /// Replaces images on a product regardless of state — works on already
  /// -published products, unlike the wizard's step-2 patch.
  Future<Either<NetworkExceptions, void>> updateImages(
    String productId,
    ImagesInfo images,
  );

  /// Full existing product detail (all 4 wizard-step fields), pre-filling
  /// the Edit Product Details flow.
  Future<Either<NetworkExceptions, ProductFormState>> fetchProductForEdit(
    String productId,
  );

  /// Persists edited basic/pricing/shipping/images fields back to an
  /// already-published product via the `details/*` + `images` endpoints
  /// (not the Draft-only wizard steps).
  Future<Either<NetworkExceptions, void>> updateProductDetails(
    String productId,
    ProductFormState formState,
  );
}
