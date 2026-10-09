import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/repositories/vendor_emi_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/vendor_emi_messages.dart';

part 'vendor_emi_terms_notifier.freezed.dart';

@freezed
abstract class VendorEmiTermsState with _$VendorEmiTermsState {
  const VendorEmiTermsState._();

  const factory VendorEmiTermsState({
    @Default(true) bool loading,

    /// The terms as last read from or saved to the server.
    VendorEmiTerms? saved,
    EmiFailure? loadFailure,

    // The draft the vendor is editing.
    @Default(false) bool enabled,
    @Default(emiMinDownPaymentPercent) int minDownPaymentPercent,
    @Default(<int>[]) List<int> tenures,

    @Default(false) bool saving,

    /// A sentence for the last refused or failed save, if any.
    String? error,
    @Default(false) bool justSaved,
  }) = _VendorEmiTermsState;

  /// The endpoint answered 404 — the backend is not deployed yet, so the
  /// section hides itself.
  bool get isUnavailable => loadFailure?.isNotFound ?? false;

  /// The draft differs from what the server has.
  bool get isDirty {
    final terms = saved;
    if (terms == null) return false;
    // Compared with the draft the saved terms load into, so a listing that
    // was never configured is not "changed" just by opening it.
    return terms.enabled != enabled ||
        snapDownPaymentPercent(terms.minDownPaymentPercent) !=
            minDownPaymentPercent ||
        !_sameTenures(
          terms.tenures.isEmpty ? emiAllowedTenures : terms.tenures,
          tenures,
        );
  }

  /// What buyers would get with the draft — see
  /// [previewEffectiveMinDownPercent].
  int get previewEffectiveMin {
    final terms = saved;
    if (terms == null) return minDownPaymentPercent;
    return previewEffectiveMinDownPercent(
      selected: minDownPaymentPercent,
      savedMinDownPaymentPercent: terms.minDownPaymentPercent,
      savedEffectiveMinDownPaymentPercent: terms.effectiveMinDownPaymentPercent,
    );
  }

  /// The draft's problem before it is sent, or null.
  String? get validationError => validateVendorEmiTerms(
    enabled: enabled,
    minDownPaymentPercent: minDownPaymentPercent,
    tenures: tenures,
    eligibleVariantCount: saved?.eligibleVariantCount ?? 0,
    minimumPrice: saved?.minimumPrice,
  );

  static bool _sameTenures(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    final sortedA = [...a]..sort();
    final sortedB = [...b]..sort();
    for (var i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }
}

/// The "Offer EMI" section's state for one listing: the saved terms and the
/// draft being edited.
class VendorEmiTermsNotifier extends StateNotifier<VendorEmiTermsState> {
  VendorEmiTermsNotifier(this._repository, this.productId)
    : super(const VendorEmiTermsState());

  final VendorEmiRepository _repository;
  final String productId;

  Future<void> load() async {
    state = state.copyWith(loading: true, loadFailure: null);
    final result = await _repository.getTerms(productId);
    if (!mounted) return;
    state = result.fold(
      (failure) => state.copyWith(loading: false, loadFailure: failure),
      (terms) =>
          _withSaved(state.copyWith(loading: false, loadFailure: null), terms),
    );
  }

  /// A never-configured listing defaults to every tenure, so switching EMI
  /// on is one tap rather than a switch and four chips.
  static VendorEmiTermsState _withSaved(
    VendorEmiTermsState state,
    VendorEmiTerms terms,
  ) => state.copyWith(
    saved: terms,
    enabled: terms.enabled,
    minDownPaymentPercent: snapDownPaymentPercent(terms.minDownPaymentPercent),
    tenures: terms.tenures.isEmpty ? emiAllowedTenures : terms.tenures,
    error: null,
  );

  void setEnabled(bool value) =>
      state = state.copyWith(enabled: value, error: null, justSaved: false);

  void setMinDownPaymentPercent(int percent) => state = state.copyWith(
    minDownPaymentPercent: snapDownPaymentPercent(percent),
    error: null,
    justSaved: false,
  );

  void toggleTenure(int months) {
    if (!emiAllowedTenures.contains(months)) return;
    final next = state.tenures.contains(months)
        ? [...state.tenures.where((t) => t != months)]
        : ([...state.tenures, months]..sort());
    state = state.copyWith(tenures: next, error: null, justSaved: false);
  }

  /// Saves the draft. True when the server accepted it.
  Future<bool> save() async {
    if (state.saving) return false;
    final invalid = state.validationError;
    if (invalid != null) {
      state = state.copyWith(error: invalid, justSaved: false);
      return false;
    }
    state = state.copyWith(saving: true, error: null, justSaved: false);
    final result = await _repository.saveTerms(
      productId,
      enabled: state.enabled,
      minDownPaymentPercent: state.minDownPaymentPercent,
      tenures: state.tenures,
    );
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(
          saving: false,
          error: vendorEmiErrorMessage(
            failure,
            minimumPrice: state.saved?.minimumPrice,
          ),
        );
        return false;
      },
      (terms) {
        state = _withSaved(
          state.copyWith(saving: false),
          terms,
        ).copyWith(justSaved: true);
        return true;
      },
    );
  }
}
