import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/datasources/add_product_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/repositories/add_product_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/repositories/add_product_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockAddProductRepository extends Mock implements AddProductRepository {}

class _MockRemoteDataSource extends Mock
    implements AddProductRemoteDataSource {}

class _ConnectedNetwork implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

BasicInfo _basic({String name = 'QA product'}) => BasicInfo(
  productName: name,
  sku: 'QA-SKU',
  shortDescription: 'Short description',
  description: 'Full description',
  categoryId: 'category-id',
  categories: const ['Electronics'],
  tags: const [],
);

const _images = ImagesInfo(
  images: [
    'https://cdn.test/1.png',
    'https://cdn.test/2.png',
    'https://cdn.test/3.png',
    'https://cdn.test/4.png',
    'https://cdn.test/5.png',
  ],
  primaryImageIndex: 0,
);

const _pricing = PricingInfo(
  basePrice: Money(amount: 999, currency: 'NPR'),
  costPerItem: Money(amount: 500, currency: 'NPR'),
  taxRate: 0,
  discountEnabled: true,
  discountPercent: 20,
  sku: 'QA-SKU',
  quantityOnHand: 10,
);

const _shipping = ShippingInfo(
  weight: 2.5,
  weightUnit: 'lbs',
  dimensionsLength: 12,
  dimensionsWidth: 8,
  dimensionsHeight: 4,
  requiresShipping: true,
  shippingFee: Money(amount: 0, currency: 'NPR'),
  deliveryEstimateMin: 5,
  deliveryEstimateMax: 7,
);

ProductDraft _draft({String id = ''}) => ProductDraft(
  id: id,
  basicInfo: _basic(),
  imagesInfo: _images,
  pricingInfo: _pricing,
  shippingInfo: _shipping,
  status: 'draft',
);

void _completeForm(AddProductNotifier notifier) {
  notifier
    ..updateBasicInfo(_basic())
    ..updateImages(_images)
    ..updatePricing(_pricing)
    ..updateShipping(_shipping);
}

void main() {
  setUpAll(() {
    registerFallbackValue(_draft());
    registerFallbackValue(const ProductFormState(currentStep: 1));
    registerFallbackValue(<String, dynamic>{});
  });

  test('successful saves reuse the draft id and idempotency key', () async {
    final repository = _MockAddProductRepository();
    final notifier = AddProductNotifier(repository);
    when(
      () => repository.saveDraftProgress(
        any(),
        draftId: any(named: 'draftId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => right('product-1'));

    _completeForm(notifier);
    expect(await notifier.saveDraft(), isTrue);
    final firstKey =
        verify(
              () => repository.saveDraftProgress(
                any(),
                draftId: null,
                idempotencyKey: captureAny(named: 'idempotencyKey'),
              ),
            ).captured.single
            as String;
    expect(firstKey, isNotEmpty);
    expect(notifier.isDirty, isFalse);

    notifier.updateBasicInfo(_basic(name: 'Updated QA product'));
    expect(await notifier.saveDraft(), isTrue);
    verify(
      () => repository.saveDraftProgress(
        any(),
        draftId: 'product-1',
        idempotencyKey: firstKey,
      ),
    ).called(1);
    expect(notifier.isDirty, isFalse);
  });

  test('failed saves retry with the same idempotency key', () async {
    final repository = _MockAddProductRepository();
    final notifier = AddProductNotifier(repository);
    var attempt = 0;
    when(
      () => repository.saveDraftProgress(
        any(),
        draftId: any(named: 'draftId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async {
      attempt++;
      return attempt == 1
          ? left(const NetworkExceptions.unexpectedError())
          : right('product-after-retry');
    });

    _completeForm(notifier);
    expect(await notifier.saveDraft(), isFalse);
    final firstKey =
        verify(
              () => repository.saveDraftProgress(
                any(),
                draftId: null,
                idempotencyKey: captureAny(named: 'idempotencyKey'),
              ),
            ).captured.single
            as String;

    expect(await notifier.saveDraft(), isTrue);
    verify(
      () => repository.saveDraftProgress(
        any(),
        draftId: null,
        idempotencyKey: firstKey,
      ),
    ).called(1);
  });

  test(
    'partial draft persists only the wizard steps completed so far',
    () async {
      final remote = _MockRemoteDataSource();
      final repository = AddProductRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: _ConnectedNetwork(),
      );
      when(
        () => remote.startDraft(any(), any()),
      ).thenAnswer((_) async => 'partial-product');
      when(() => remote.patchStep2(any(), any())).thenAnswer((_) async {});

      final result = await repository.saveDraftProgress(
        ProductFormState(currentStep: 2, step1: _basic(), step2: _images),
        idempotencyKey: 'partial-key',
      );

      expect(result.getRight().toNullable(), 'partial-product');
      verify(() => remote.startDraft(any(), 'partial-key')).called(1);
      verify(() => remote.patchStep2('partial-product', any())).called(1);
      verifyNever(() => remote.patchStep3(any(), any()));
      verifyNever(() => remote.patchStep4(any(), any()));
    },
  );

  test(
    'repository converts imperial UI values and updates saved drafts',
    () async {
      final remote = _MockRemoteDataSource();
      final repository = AddProductRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: _ConnectedNetwork(),
      );
      when(
        () => remote.startDraft(any(), any()),
      ).thenAnswer((_) async => 'product-1');
      when(() => remote.patchStep1(any(), any())).thenAnswer((_) async {});
      when(() => remote.patchStep2(any(), any())).thenAnswer((_) async {});
      when(() => remote.patchStep3(any(), any())).thenAnswer((_) async {});
      when(() => remote.patchStep4(any(), any())).thenAnswer((_) async {});

      final created = await repository.submitDraft(
        _draft(),
        idempotencyKey: 'wizard-key',
      );
      expect(created.isRight(), isTrue);
      expect(created.getRight().toNullable(), 'product-1');
      final shipping =
          verify(
                () => remote.patchStep4('product-1', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(shipping['weightGrams'], 1134);
      expect(shipping['lengthCm'], 30);
      expect(shipping['widthCm'], 20);
      expect(shipping['heightCm'], 10);

      clearInteractions(remote);
      await repository.submitDraft(
        _draft(id: 'product-1'),
        idempotencyKey: 'wizard-key',
      );
      verifyNever(() => remote.startDraft(any(), any()));
      verify(() => remote.patchStep1('product-1', any())).called(1);
    },
  );
}
