import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/repositories/try_on_repository.dart';
import 'package:uuid/uuid.dart';

part 'fit_notifier.freezed.dart';

@freezed
abstract class FitState with _$FitState {
  const FitState._();

  const factory FitState.initial() = _Initial;
  const factory FitState.loadInProgress() = _LoadInProgress;

  /// No measurements saved yet: the panel shows the short form.
  const factory FitState.needsMeasurements() = _NeedsMeasurements;
  const factory FitState.loadSuccess(
    FitRecommendation fit,
    BodyMeasurements measurements,
  ) = _LoadSuccess;

  /// The vendor has not published a size chart for this product.
  const factory FitState.noSizeChart(BodyMeasurements? measurements) =
      _NoSizeChart;
  const factory FitState.saving() = _Saving;
  const factory FitState.loadFailure(TryOnFailure failure) = _LoadFailure;
}

/// The fit panel: measurements → recommendation.
class FitNotifier extends StateNotifier<FitState> {
  FitNotifier(this._repository, this.productId)
    : super(const FitState.initial());

  final TryOnRepository _repository;
  final String productId;
  static const _uuid = Uuid();

  BodyMeasurements? _measurements;

  /// The last measurements read or saved; pre-fills the edit form.
  BodyMeasurements? get measurements => _measurements;

  Future<void> load() async {
    state = const FitState.loadInProgress();
    final m = await _repository.getMeasurements();
    if (!mounted) return;
    final failure = m.fold((f) => f, (_) => null);
    if (failure != null) {
      state = FitState.loadFailure(failure);
      return;
    }
    _measurements = m.getOrElse((_) => null);
    if (_measurements == null) {
      state = const FitState.needsMeasurements();
      return;
    }
    await _loadFit();
  }

  Future<void> _loadFit() async {
    final result = await _repository.getFit(productId);
    if (!mounted) return;
    state = result.fold(
      (f) => f.isNotFound
          ? FitState.noSizeChart(_measurements)
          : FitState.loadFailure(f),
      (fit) => FitState.loadSuccess(fit, _measurements!),
    );
  }

  /// Saves (one Idempotency-Key per tap) and re-reads the recommendation.
  /// Returns the failure, if any, so the form can show it inline.
  Future<TryOnFailure?> save(BodyMeasurements next) async {
    state = const FitState.saving();
    final result = await _repository.saveMeasurements(
      next,
      idempotencyKey: _uuid.v4(),
    );
    if (!mounted) return null;
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      // Back to the form so the buyer can correct what was refused.
      state = const FitState.needsMeasurements();
      return failure;
    }
    _measurements = result.getOrElse((_) => next);
    await _loadFit();
    return null;
  }

  /// Back to the form, e.g. "Edit my measurements".
  void edit() => state = const FitState.needsMeasurements();
}
