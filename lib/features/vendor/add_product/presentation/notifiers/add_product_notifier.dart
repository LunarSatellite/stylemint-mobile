import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/repositories/add_product_repository.dart';

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
  const factory AddProductState.publishSuccess(String productId) = _PublishSuccess;
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
    _formState = _formState.copyWith(step1: info);
    state = AddProductState.loadSuccess(_formState);
  }

  void updateImages(ImagesInfo info) {
    _formState = _formState.copyWith(step2: info);
    state = AddProductState.loadSuccess(_formState);
  }

  void updatePricing(PricingInfo info) {
    _formState = _formState.copyWith(step3: info);
    state = AddProductState.loadSuccess(_formState);
  }

  void updateShipping(ShippingInfo info) {
    _formState = _formState.copyWith(step4: info);
    state = AddProductState.loadSuccess(_formState);
  }

  Future<void> saveDraft({String? draftId}) async {
    if (!_formState.isValid) return;
    state = AddProductState.saveInProgress(_formState);

    final draft = ProductDraft(
      id: draftId ?? '',
      basicInfo: _formState.step1!,
      imagesInfo: _formState.step2!,
      pricingInfo: _formState.step3!,
      shippingInfo: _formState.step4!,
      status: 'draft',
    );

    final either =
        draftId != null && draftId.isNotEmpty
            ? await _repository.updateDraft(draftId, draft)
            : await _repository.saveDraft(draft);

    state = either.fold(
      (failure) => AddProductState.saveFailure(_formState, failure),
      (saved) => AddProductState.saveSuccess(_formState, saved),
    );
  }

  Future<void> uploadImage(String filePath) async {
    state = AddProductState.loadInProgress(_formState);
    final either = await _repository.uploadImage(filePath);
    state = either.fold(
      (failure) => AddProductState.loadFailure(_formState, failure),
      (url) {
        final current = _formState.step2;
        final images = current != null
            ? [...current.images, url]
            : [url];
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

    if (draftId != null && draftId.isNotEmpty) {
      final draft = ProductDraft(
        id: draftId,
        basicInfo: _formState.step1!,
        imagesInfo: _formState.step2!,
        pricingInfo: _formState.step3!,
        shippingInfo: _formState.step4!,
        status: 'draft',
      );
      final saveEither = await _repository.updateDraft(draftId, draft);
      final saved = saveEither.fold(
        (failure) {
          state = AddProductState.publishFailure(_formState, failure);
          return null;
        },
        (d) => d,
      );
      if (saved == null) return;

      final publishEither = await _repository.publishProduct(saved.id);
      state = publishEither.fold(
        (failure) => AddProductState.publishFailure(_formState, failure),
        AddProductState.publishSuccess,
      );
    } else {
      final publishEither = await _repository.publishProduct(draftId ?? '');
      state = publishEither.fold(
        (failure) => AddProductState.publishFailure(_formState, failure),
        AddProductState.publishSuccess,
      );
    }
  }
}
