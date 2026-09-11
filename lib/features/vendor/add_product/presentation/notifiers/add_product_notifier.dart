import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/repositories/add_product_repository.dart';
import 'package:uuid/uuid.dart';

part 'add_product_notifier.freezed.dart';

@freezed
abstract class AddProductState with _$AddProductState {
  const AddProductState._();

  const factory AddProductState.initial() = _Initial;
  const factory AddProductState.loadInProgress(ProductFormState formState) =
      _LoadInProgress;
  const factory AddProductState.loadSuccess(ProductFormState formState) =
      _LoadSuccess;
  const factory AddProductState.loadFailure(
    ProductFormState formState,
    NetworkExceptions failure,
  ) = _LoadFailure;
  const factory AddProductState.saveInProgress(ProductFormState formState) =
      _SaveInProgress;
  const factory AddProductState.saveSuccess(
    ProductFormState formState,
    ProductDraft draft,
  ) = _SaveSuccess;
  const factory AddProductState.saveFailure(
    ProductFormState formState,
    NetworkExceptions failure,
  ) = _SaveFailure;
  const factory AddProductState.publishing(ProductFormState formState) =
      _Publishing;
  const factory AddProductState.publishSuccess(String productId) =
      _PublishSuccess;
  const factory AddProductState.publishFailure(
    ProductFormState formState,
    NetworkExceptions failure,
  ) = _PublishFailure;
}

class AddProductNotifier extends StateNotifier<AddProductState> {
  AddProductNotifier(this._repository)
    : super(const AddProductState.initial()) {
    _formState = const ProductFormState(currentStep: 1);
  }

  final AddProductRepository _repository;
  late ProductFormState _formState;
  static const _uuid = Uuid();
  String _draftIdempotencyKey = _uuid.v4();
  String? _draftId;

  // Tracks whether the form has been modified since the last load/save.
  // Used by the unified ProductFormScreen's unsaved-changes guard so the
  // vendor gets a confirmation dialog before leaving the page after
  // touching any field. Reset on loadForEdit (fresh data) and after a
  // successful saveEditedDetails (changes persisted).
  bool _isDirty = false;
  bool get isDirty => _isDirty;

  void _markDirty() {
    if (!_isDirty) _isDirty = true;
  }

  /// Clears any leftover wizard state (images, pricing, shipping, etc.)
  /// from a previous Create-mode session. The provider is a singleton that
  /// outlives one Add Product run, so without this a fresh "Add Product"
  /// silently reused the last product's Step 2-4 data — including its SKU,
  /// which then collided with the just-published product on submit.
  void reset() {
    _formState = const ProductFormState(currentStep: 1);
    _draftIdempotencyKey = _uuid.v4();
    _draftId = null;
    _isDirty = false;
    state = const AddProductState.initial();
  }

  void nextStep() {
    if (_formState.currentStep < 5) {
      _formState = _formState.copyWith(
        currentStep: _formState.currentStep + 1,
        step5: _formState.reviewInfo ?? _formState.step5,
      );
      state = AddProductState.loadSuccess(_formState);
    }
  }

  void prevStep() {
    if (_formState.currentStep > 1) {
      _formState = _formState.copyWith(
        currentStep: _formState.currentStep - 1,
        step5: _formState.reviewInfo ?? _formState.step5,
      );
      state = AddProductState.loadSuccess(_formState);
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 5) {
      _formState = _formState.copyWith(
        currentStep: step,
        step5: _formState.reviewInfo ?? _formState.step5,
      );
      state = AddProductState.loadSuccess(_formState);
    }
  }

  void updateBasicInfo(BasicInfo info) {
    _markDirty();
    _formState = _formState.copyWith(step1: info);
    state = AddProductState.loadSuccess(_formState);
  }

  void updateImages(ImagesInfo info) {
    _markDirty();
    _formState = _formState.copyWith(step2: info);
    state = AddProductState.loadSuccess(_formState);
  }

  void updatePricing(PricingInfo info) {
    _markDirty();
    _formState = _formState.copyWith(step3: info);
    state = AddProductState.loadSuccess(_formState);
  }

  void updateShipping(ShippingInfo info) {
    _markDirty();
    _formState = _formState.copyWith(step4: info);
    state = AddProductState.loadSuccess(_formState);
  }

  ProductDraft _draftFrom({String id = ''}) => ProductDraft(
    id: id,
    basicInfo: _formState.step1!,
    imagesInfo: _formState.step2!,
    pricingInfo: _formState.step3!,
    shippingInfo: _formState.step4!,
    status: 'draft',
  );

  /// Saves every wizard step completed so far. Returns null when Step 1 has
  /// not been completed, false on a network/backend failure, and true when
  /// the draft was persisted.
  Future<bool?> saveDraft({String? draftId}) async {
    if (_formState.step1 == null) return null;
    state = AddProductState.saveInProgress(_formState);

    final either = await _repository.saveDraftProgress(
      _formState,
      draftId: draftId ?? _draftId,
      idempotencyKey: _draftIdempotencyKey,
    );

    return either.fold(
      (failure) {
        state = AddProductState.saveFailure(_formState, failure);
        return false;
      },
      (productId) {
        _draftId = productId;
        _isDirty = false;
        state = _formState.isValid
            ? AddProductState.saveSuccess(
                _formState,
                _draftFrom(id: productId),
              )
            : AddProductState.loadSuccess(_formState);
        return true;
      },
    );
  }

  Future<void> uploadImage(String filePath) async {
    state = AddProductState.loadInProgress(_formState);
    final either = await _repository.uploadImage(filePath);
    state = either.fold(
      (failure) => AddProductState.loadFailure(_formState, failure),
      (url) {
        final current = _formState.step2;
        final images = current != null ? [...current.images, url] : [url];
        final updated = ImagesInfo(
          images: images,
          primaryImageIndex: current?.primaryImageIndex ?? 0,
        );
        _formState = _formState.copyWith(step2: updated);
        return AddProductState.loadSuccess(_formState);
      },
    );
  }

  Future<void> publish({String? draftId}) async {
    if (!_formState.isValid) return;
    state = AddProductState.publishing(_formState);

    // Create + fill the draft (start -> step 2-4), then publish the new id.
    final submitEither = await _repository.submitDraft(
      _draftFrom(id: draftId ?? _draftId ?? ''),
      idempotencyKey: _draftIdempotencyKey,
    );
    final productId = submitEither.fold(
      (failure) {
        state = AddProductState.publishFailure(_formState, failure);
        return null;
      },
      (id) {
        _draftId = id;
        return id;
      },
    );
    if (productId == null) return;

    final publishEither = await _repository.publishProduct(productId);
    state = publishEither.fold(
      (failure) => AddProductState.publishFailure(_formState, failure),
      AddProductState.publishSuccess,
    );
  }

  /// Fetches an existing product's images for the Edit Product Images flow
  /// (separate from the wizard — works on already-published products).
  /// Resets the rest of [_formState] since this is a standalone edit, not a
  /// continuation of any in-progress Add Product draft.
  Future<bool> loadExistingImages(String productId) async {
    state = const AddProductState.loadInProgress(
      ProductFormState(currentStep: 2),
    );
    final either = await _repository.fetchProductImages(productId);
    return either.fold(
      (failure) {
        state = AddProductState.loadFailure(_formState, failure);
        return false;
      },
      (images) {
        _formState = ProductFormState(
          currentStep: 2,
          step2: ImagesInfo(images: images, primaryImageIndex: 0),
        );
        state = AddProductState.loadSuccess(_formState);
        return true;
      },
    );
  }

  /// Persists [loadExistingImages]'s (possibly edited) result back to an
  /// already-published product via `PATCH .../images`, not the Draft-only
  /// wizard step-2 endpoint.
  Future<bool> saveImagesOnly(String productId) async {
    final images = _formState.step2;
    if (images == null) return false;
    final either = await _repository.updateImages(productId, images);
    return either.isRight();
  }

  /// Full Edit Product Details flow — fetches all 4 wizard-step fields for
  /// an already-published product, pre-filling the same step screens the
  /// Add Product wizard uses (they read/write via this same notifier).
  Future<bool> loadForEdit(String productId) async {
    state = const AddProductState.loadInProgress(
      ProductFormState(currentStep: 1),
    );
    final either = await _repository.fetchProductForEdit(productId);
    return either.fold(
      (failure) {
        state = AddProductState.loadFailure(_formState, failure);
        return false;
      },
      (formState) {
        _formState = formState;
        // Fresh data from the backend -- nothing user-touched yet.
        _isDirty = false;
        state = AddProductState.loadSuccess(_formState);
        return true;
      },
    );
  }

  /// Persists [loadForEdit]'s (possibly edited) result back to an
  /// already-published product via the `details/*` + `images` endpoints —
  /// not `submitDraft`/`publish`, which are for brand-new products only.
  Future<bool> saveEditedDetails(String productId) async {
    if (!_formState.isValid) return false;
    final either = await _repository.updateProductDetails(
      productId,
      _formState,
    );
    final ok = either.isRight();
    if (ok) {
      // Persisted -- clear the dirty flag so the unsaved-changes guard
      // doesn't fire when the host screen pops on success.
      _isDirty = false;
    }
    return ok;
  }
}
