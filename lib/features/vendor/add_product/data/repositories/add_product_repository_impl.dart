import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/datasources/add_product_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/repositories/add_product_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:uuid/uuid.dart';

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
    ProductDraft draft, {
    required String idempotencyKey,
  }) async {
    return _guard(() async {
      // POST start creates the draft with basic info; subsequent saves update
      // that same draft. The stable key also makes a retry safe when the first
      // attempt created the row but failed during a later PATCH.
      final productId = draft.id.isEmpty
          ? await remoteDataSource.startDraft(
              _basicBody(draft),
              idempotencyKey,
            )
          : draft.id;
      if (draft.id.isNotEmpty) {
        await remoteDataSource.patchStep1(productId, _basicBody(draft));
      }
      await remoteDataSource.patchStep2(productId, _mediaBodyFromDraft(draft));
      await remoteDataSource.patchStep3(
        productId,
        _pricingBodyFromDraft(draft),
      );
      await remoteDataSource.patchStep4(
        productId,
        _shippingBodyFromDraft(draft),
      );
      return productId;
    });
  }

  @override
  Future<Either<NetworkExceptions, String>> saveDraftProgress(
    ProductFormState formState, {
    required String idempotencyKey,
    String? draftId,
  }) {
    return _guard(() async {
      final basicInfo = formState.step1;
      if (basicInfo == null) {
        throw StateError('Basic product information is required');
      }

      var productId = draftId;
      productId ??= await remoteDataSource.startDraft(
        _basicInfoBody(basicInfo),
        idempotencyKey,
      );
      if (draftId != null) {
        await remoteDataSource.patchStep1(
          productId,
          _basicInfoBody(basicInfo),
        );
      }
      if (formState.step2 case final images?) {
        await remoteDataSource.patchStep2(productId, _mediaBody(images));
      }
      if (formState.step3 case final pricing?) {
        await remoteDataSource.patchStep3(productId, _pricingBody(pricing));
      }
      if (formState.step4 case final shipping?) {
        await remoteDataSource.patchStep4(productId, _shippingBody(shipping));
      }
      return productId;
    });
  }

  @override
  Future<Either<NetworkExceptions, String>> uploadImage(String filePath) {
    return _guard(() => remoteDataSource.uploadImage(filePath));
  }

  @override
  Future<Either<NetworkExceptions, List<String>>> fetchProductImages(
    String productId,
  ) {
    return _guard(() => remoteDataSource.fetchProductImages(productId));
  }

  @override
  Future<Either<NetworkExceptions, void>> updateImages(
    String productId,
    ImagesInfo images,
  ) {
    return _guard(
      () => remoteDataSource.updateImages(productId, _mediaBody(images)),
    );
  }

  @override
  Future<Either<NetworkExceptions, String>> publishProduct(String productId) {
    return _guard(() => remoteDataSource.publishProduct(productId, _uuid.v4()));
  }

  // --- payload builders (domain -> backend wizard contract) ---

  Map<String, dynamic> _basicBody(ProductDraft d) =>
      _basicInfoBody(d.basicInfo);

  Map<String, dynamic> _basicInfoBody(BasicInfo info) => {
    'categoryId': info.categoryId,
    'name': info.productName,
    'shortDescription': info.shortDescription,
    'longDescriptionMarkdown': info.description,
  };

  Map<String, dynamic> _mediaBodyFromDraft(ProductDraft d) =>
      _mediaBody(d.imagesInfo);

  Map<String, dynamic> _mediaBody(ImagesInfo info) {
    final imgs = info.images;
    return {
      'images': [
        for (var i = 0; i < imgs.length; i++)
          {
            'cdnUrl': imgs[i],
            'sortOrder': i,
            'isPrimary': i == info.primaryImageIndex,
          },
      ],
      'video': info.video == null
          ? null
          : {
              'cdnUrl': info.video!.cdnUrl,
              'durationSeconds': info.video!.durationSeconds,
            },
    };
  }

  Map<String, dynamic> _pricingBodyFromDraft(ProductDraft d) =>
      _pricingBody(d.pricingInfo);

  Map<String, dynamic> _pricingBody(PricingInfo p) {
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

  Map<String, dynamic> _shippingBodyFromDraft(ProductDraft d) =>
      _shippingBody(d.shippingInfo);

  Map<String, dynamic> _shippingBody(ShippingInfo s) {
    const poundsToGrams = 453.59237;
    const inchesToCentimeters = 2.54;
    final grams = switch (s.weightUnit.toLowerCase()) {
      'kg' => (s.weight * 1000).round(),
      'lbs' || 'lb' => (s.weight * poundsToGrams).round(),
      _ => s.weight.round(),
    };
    return {
      'processingTimeDays': s.deliveryEstimateMin,
      'shipsFromAddressId': null,
      'weightGrams': grams,
      'lengthCm': (s.dimensionsLength * inchesToCentimeters).round(),
      'widthCm': (s.dimensionsWidth * inchesToCentimeters).round(),
      'heightCm': (s.dimensionsHeight * inchesToCentimeters).round(),
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

  @override
  Future<Either<NetworkExceptions, ProductFormState>> fetchProductForEdit(
    String productId,
  ) {
    return _guard(() async {
      final data = await remoteDataSource.fetchProduct(productId);

      final variants = (data['variants'] as List<dynamic>? ?? const [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final variant = variants.isEmpty
          ? const <String, dynamic>{}
          : (variants.firstWhere(
              (v) => v['isDefault'] == true,
              orElse: () => variants.first,
            ));

      final images =
          (data['images'] as List<dynamic>? ?? const [])
              .map((e) => e as Map<String, dynamic>)
              .toList()
            ..sort(
              (a, b) => (a['sortOrder'] as int? ?? 0).compareTo(
                b['sortOrder'] as int? ?? 0,
              ),
            );

      final shippingOptions =
          (data['shippingOptions'] as List<dynamic>? ?? const [])
              .map((e) => e as Map<String, dynamic>)
              .toList();
      final firstShipping = shippingOptions.isEmpty
          ? null
          : shippingOptions.first;
      final video = data['video'] as Map<String, dynamic>?;

      final priceCurrency = variant['priceCurrency'] as String? ?? 'NPR';
      final weightGrams = variant['weightGrams'] as int? ?? 0;
      const poundsToGrams = 453.59237;
      const inchesToCentimeters = 2.54;

      return ProductFormState(
        currentStep: 1,
        step1: BasicInfo(
          productName: data['name'] as String? ?? '',
          // The Step 1 SKU field displays this, but the backend's real SKU
          // lives on the variant (PatchStep3) — read it from there so Edit
          // doesn't show the field blank when the product already has one.
          sku: variant['sku'] as String? ?? '',
          shortDescription: data['shortDescription'] as String? ?? '',
          description: data['longDescriptionMarkdown'] as String? ?? '',
          categoryId: data['categoryId'] as String? ?? '',
          categories: const [],
          tags: const [],
        ),
        step2: ImagesInfo(
          images: images
              .map((e) => e['cdnUrl'] as String)
              .toList(growable: false),
          primaryImageIndex: images.isEmpty
              ? 0
              : images
                    .indexWhere((e) => e['isPrimary'] == true)
                    .clamp(
                      0,
                      images.length - 1,
                    ),
          video: video == null
              ? null
              : ProductVideoInfo(
                  cdnUrl: video['cdnUrl'] as String? ?? '',
                  durationSeconds: (video['durationSeconds'] as num? ?? 0)
                      .toInt(),
                ),
        ),
        step3: PricingInfo(
          basePrice: Money(
            amount: (variant['priceAmount'] as num? ?? 0).toDouble(),
            currency: priceCurrency,
          ),
          costPerItem: variant['costPriceAmount'] == null
              ? null
              : Money(
                  amount: (variant['costPriceAmount'] as num).toDouble(),
                  currency:
                      variant['costPriceCurrency'] as String? ?? priceCurrency,
                ),
          taxRate: 0,
          discountEnabled: false,
          sku: variant['sku'] as String? ?? '',
          quantityOnHand: variant['quantityOnHand'] as int? ?? 0,
          trackInventory: variant['trackInventory'] as bool? ?? true,
          allowOverselling: variant['allowOverselling'] as bool? ?? false,
          productKind: variant['productKind'] as int? ?? 1,
          billingCadence: variant['billingCadence'] as int? ?? 1,
        ),
        step4: ShippingInfo(
          weight: weightGrams / poundsToGrams,
          weightUnit: 'lbs',
          dimensionsLength:
              (variant['lengthCm'] as num? ?? 0).toDouble() /
              inchesToCentimeters,
          dimensionsWidth:
              (variant['widthCm'] as num? ?? 0).toDouble() /
              inchesToCentimeters,
          dimensionsHeight:
              (variant['heightCm'] as num? ?? 0).toDouble() /
              inchesToCentimeters,
          requiresShipping: firstShipping != null,
          shippingFee: firstShipping == null
              ? null
              : Money(
                  amount: (firstShipping['feeAmount'] as num).toDouble(),
                  currency: firstShipping['feeCurrency'] as String? ?? 'NPR',
                ),
          deliveryEstimateMin: firstShipping?['estimatedDaysMin'] as int? ?? 1,
          deliveryEstimateMax: firstShipping?['estimatedDaysMax'] as int? ?? 3,
        ),
      );
    });
  }

  @override
  Future<Either<NetworkExceptions, void>> updateProductDetails(
    String productId,
    ProductFormState formState,
  ) {
    return _guard(() async {
      if (formState.step1 != null) {
        await remoteDataSource.updateBasicInfo(
          productId,
          {
            'categoryId': formState.step1!.categoryId,
            'name': formState.step1!.productName,
            'shortDescription': formState.step1!.shortDescription,
            'longDescriptionMarkdown': formState.step1!.description,
          },
        );
      }
      if (formState.step3 != null) {
        await remoteDataSource.updatePricing(
          productId,
          _pricingBody(formState.step3!),
        );
      }
      if (formState.step4 != null) {
        await remoteDataSource.updateShipping(
          productId,
          _shippingBody(formState.step4!),
        );
      }
      if (formState.step2 != null) {
        await remoteDataSource.updateImages(
          productId,
          _mediaBody(formState.step2!),
        );
      }
    });
  }

  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() action,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await action());
    } catch (e) {
      if (e is DioException) {
        return left(mapDioExceptionToNetworkException(e));
      } else if (e is NetworkExceptions) {
        return left(e);
      }
      return left(NetworkExceptions.unexpectedError());
    }
  }
}
