import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/datasources/add_product_remote_datasource.dart';
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
  Future<Either<NetworkExceptions, List<CategoryOption>>>
      fetchCategories() async {
    return _guard(() async {
      final dtos = await remoteDataSource.fetchCategories();
      return dtos
          .map((d) => CategoryOption(id: d.id, name: d.name))
          .toList(growable: false);
    });
  }

  @override
  Future<Either<NetworkExceptions, String>> submitDraft(
      ProductDraft draft) async {
    return _guard(() async {
      // POST start creates the draft with basic info; steps 2-4 fill the rest.
      final productId =
          await remoteDataSource.startDraft(_basicBody(draft), _uuid.v4());
      await remoteDataSource.patchStep2(productId, _mediaBody(draft));
      await remoteDataSource.patchStep3(productId, _pricingBody(draft));
      await remoteDataSource.patchStep4(productId, _shippingBody(draft));
      return productId;
    });
  }

  @override
  Future<Either<NetworkExceptions, String>> uploadImage(String filePath) {
    return _guard(() => remoteDataSource.uploadImage(filePath));
  }

  @override
  Future<Either<NetworkExceptions, String>> publishProduct(String productId) {
    return _guard(
        () => remoteDataSource.publishProduct(productId, _uuid.v4()));
  }

  // --- payload builders (domain -> backend wizard contract) ---

  Map<String, dynamic> _basicBody(ProductDraft d) => {
        'categoryId': d.basicInfo.categoryId,
        'name': d.basicInfo.productName,
        'shortDescription': d.basicInfo.shortDescription,
        'longDescriptionMarkdown': d.basicInfo.description,
      };

  Map<String, dynamic> _mediaBody(ProductDraft d) {
    final imgs = d.imagesInfo.images;
    return {
      'images': [
        for (var i = 0; i < imgs.length; i++)
          {
            'cdnUrl': imgs[i],
            'sortOrder': i,
            'isPrimary': i == d.imagesInfo.primaryImageIndex,
          },
      ],
      'video': null,
    };
  }

  Map<String, dynamic> _pricingBody(ProductDraft d) {
    final p = d.pricingInfo;
    return {
      'sku': p.sku,
      'priceAmount': p.basePrice.amount,
      'priceCurrency': p.basePrice.currency,
      'costPriceAmount': p.costPerItem?.amount ?? 0,
      'costPriceCurrency': p.costPerItem?.currency ?? p.basePrice.currency,
      'trackInventory': p.trackInventory,
      'allowOverselling': p.allowOverselling,
      'quantityOnHand': p.quantityOnHand,
      'productKind': p.productKind,
      'billingCadence': p.billingCadence,
    };
  }

  Map<String, dynamic> _shippingBody(ProductDraft d) {
    final s = d.shippingInfo;
    final grams =
        (s.weightUnit.toLowerCase() == 'kg' ? s.weight * 1000 : s.weight)
            .round();
    return {
      'processingTimeDays': s.deliveryEstimateMin,
      'shipsFromAddressId': null,
      'weightGrams': grams,
      'lengthCm': s.dimensionsLength.round(),
      'widthCm': s.dimensionsWidth.round(),
      'heightCm': s.dimensionsHeight.round(),
      'shippingOptions': [
        if (s.requiresShipping)
          {
            'kind': 1, // ShippingOptionKind.Standard
            'feeAmount': s.shippingFee?.amount ?? 0,
            'feeCurrency': s.shippingFee?.currency ?? 'NPR',
            'estimatedDaysMin': s.deliveryEstimateMin,
            'estimatedDaysMax': s.deliveryEstimateMax,
          },
      ],
    };
  }

  Future<Either<NetworkExceptions, T>> _guard<T>(
      Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await action());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      }
      return left(NetworkExceptions.unexpectedError());
    }
  }
}
