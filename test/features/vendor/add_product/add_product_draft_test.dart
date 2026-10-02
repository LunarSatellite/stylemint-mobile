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
  shippingFee: Money(amount: 500, currency: 'NPR'),
  deliveryEstimateMin: 2,
  deliveryEstimateMax: 7,
  shipsFromAddressId: 'dispatch-address-id',
  shipsFromLabel: 'Warehouse — Kathmandu',
  processingTimeDays: 2,
  shippingOptions: [
    ProductShippingOption(
      kind: 1,
      label: 'Standard (5-7 days) - FREE',
      fee: Money(amount: 0, currency: 'NPR'),
      estimatedDaysMin: 5,
      estimatedDaysMax: 7,
    ),
    ProductShippingOption(
      kind: 2,
      label: 'Express (2-3 days) - Rs 500',
      fee: Money(amount: 500, currency: 'NPR'),
      estimatedDaysMin: 2,
      estimatedDaysMax: 3,
    ),
  ],
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
      expect(shipping['shipsFromAddressId'], 'dispatch-address-id');
      expect(shipping['processingTimeDays'], 2);
      final options = shipping['shippingOptions'] as List<dynamic>;
      expect(options, hasLength(2));
      expect(options.map((option) => option['kind']), [1, 2]);

      clearInteractions(remote);
      await repository.submitDraft(
        _draft(id: 'product-1'),
        idempotencyKey: 'wizard-key',
      );
      verifyNever(() => remote.startDraft(any(), any()));
      verify(() => remote.patchStep1('product-1', any())).called(1);
    },
  );

  // ── Finishing a draft that was saved earlier ──────────────────────────
  //
  // A draft reopened from the products list used to have no route to Active:
  // Edit mode saved through the `details/*` endpoints, which neither publish
  // nor advance the server's WizardStepReached, so the listing stayed Draft
  // however complete it looked.

  group('resuming a saved draft', () {
    test('adopts the draft id so publish targets it, not a new product', () async {
      final repository = _MockAddProductRepository();
      final notifier = AddProductNotifier(repository);
      when(() => repository.fetchProductForEdit('draft-7')).thenAnswer(
        (_) async => right(
          ProductFormState(
            currentStep: 1,
            step1: _basic(),
            step2: _images,
            step3: _pricing,
            step4: _shipping,
            loadedProductState: ProductFormState.draftProductState,
          ),
        ),
      );
      when(
        () => repository.submitDraft(
          any(),
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).thenAnswer((_) async => right('draft-7'));
      when(
        () => repository.publishProduct(any()),
      ).thenAnswer((_) async => right('draft-7'));

      expect(await notifier.loadForEdit('draft-7'), isTrue);
      expect(notifier.isEditingDraft, isTrue);

      expect(await notifier.publish(), isTrue);

      // The existing draft is PATCHed, never re-created: submitDraft carries
      // the loaded id, so startDraft is skipped and WizardStepReached is
      // advanced to 4 by the step PATCHes before publish is attempted.
      final submitted =
          verify(
                () => repository.submitDraft(
                  captureAny(),
                  idempotencyKey: any(named: 'idempotencyKey'),
                ),
              ).captured.single
              as ProductDraft;
      expect(submitted.id, 'draft-7');
      verify(() => repository.publishProduct('draft-7')).called(1);
    });

    test('a live product is not adopted as a draft', () async {
      final repository = _MockAddProductRepository();
      final notifier = AddProductNotifier(repository);
      when(() => repository.fetchProductForEdit('live-1')).thenAnswer(
        (_) async => right(
          ProductFormState(
            currentStep: 1,
            step1: _basic(),
            step2: _images,
            step3: _pricing,
            step4: _shipping,
            loadedProductState: 2, // Active
          ),
        ),
      );

      expect(await notifier.loadForEdit('live-1'), isTrue);
      expect(notifier.isEditingDraft, isFalse);
    });

    test('reads the lifecycle state off the product payload', () async {
      final remote = _MockRemoteDataSource();
      final repository = AddProductRepositoryImpl(
        remoteDataSource: remote,
        networkInfo: _ConnectedNetwork(),
      );
      when(() => remote.fetchProduct('draft-7')).thenAnswer(
        (_) async => <String, dynamic>{
          'id': 'draft-7',
          'name': 'QA product',
          'shortDescription': 'Short description',
          'longDescriptionMarkdown': 'Full description',
          'categoryId': 'category-id',
          'state': 1,
          'processingTimeDays': 2,
          'variants': <dynamic>[],
          'images': <dynamic>[],
          'shippingOptions': <dynamic>[],
        },
      );

      final loaded = await repository.fetchProductForEdit('draft-7');
      final formState = loaded.getRight().toNullable();
      expect(formState, isNotNull);
      expect(formState!.isLoadedDraft, isTrue);
    });
  });

  // ── Why a publish is blocked ──────────────────────────────────────────

  group('incompleteReason', () {
    ProductFormState form({
      BasicInfo? step1,
      ImagesInfo? step2,
      PricingInfo? step3,
      ShippingInfo? step4,
    }) => ProductFormState(
      currentStep: 5,
      step1: step1 ?? _basic(),
      step2: step2 ?? _images,
      step3: step3 ?? _pricing,
      step4: step4 ?? _shipping,
    );

    test('a complete form has no reason and is valid', () {
      final state = form();
      expect(state.incompleteReason, isNull);
      expect(state.isValid, isTrue);
    });

    test('isValid always agrees with incompleteReason', () {
      // Built directly: the `form` helper substitutes defaults for nulls.
      final blocked = ProductFormState(
        currentStep: 5,
        step1: _basic(),
        step2: _images,
        step4: _shipping,
      );
      expect(blocked.incompleteReason, contains('Pricing'));
      expect(blocked.isValid, isFalse);
    });

    test('a product loaded for edit is valid without a category name', () {
      // fetchProductForEdit can only supply categoryId — the backend returns
      // no category name — so validating the display list made every loaded
      // product look incomplete until Step 1 was re-walked.
      final state = form(
        step1: BasicInfo(
          productName: 'QA product',
          sku: 'QA-SKU',
          shortDescription: 'Short description',
          description: 'Full description',
          categoryId: 'category-id',
          categories: const [],
          tags: const [],
        ),
      );
      expect(state.incompleteReason, isNull);
      expect(state.isValid, isTrue);
    });

    test('refuses a zero price rather than publishing a free listing', () {
      final state = form(
        step3: const PricingInfo(
          basePrice: Money(amount: 0, currency: 'NPR'),
          taxRate: 0,
          discountEnabled: false,
          sku: 'QA-SKU',
          quantityOnHand: 10,
        ),
      );
      expect(state.incompleteReason, contains('selling price'));
      expect(state.isValid, isFalse);
    });

    test('names the missing photos and counts how many', () {
      final state = form(
        step2: const ImagesInfo(
          images: ['https://cdn.test/1.png', 'https://cdn.test/2.png'],
          primaryImageIndex: 0,
        ),
      );
      expect(state.incompleteReason, contains('3 more photos'));
    });

    test('names the shipping field that is missing', () {
      final state = form(
        step4: _shipping.copyWith(processingTimeDays: 0),
      );
      expect(state.incompleteReason, contains('ready'));
      expect(state.isValid, isFalse);
    });

    test('names the dispatch address when it is unset', () {
      final state = form(step4: _shipping.copyWith(shipsFromAddressId: ''));
      expect(state.incompleteReason, contains('ships from'));
    });
  });
}
