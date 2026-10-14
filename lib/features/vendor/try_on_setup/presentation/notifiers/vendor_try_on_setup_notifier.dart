import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/repositories/vendor_try_on_repository.dart';
import 'package:uuid/uuid.dart';

part 'vendor_try_on_setup_notifier.freezed.dart';

class VendorTryOnData {
  const VendorTryOnData({required this.readiness, this.chart});

  final TryOnReadiness readiness;

  /// Null when the vendor has not saved one.
  final SizeChart? chart;
}

@freezed
abstract class VendorTryOnSetupState with _$VendorTryOnSetupState {
  const VendorTryOnSetupState._();

  const factory VendorTryOnSetupState.initial() = _Initial;
  const factory VendorTryOnSetupState.loadInProgress() = _LoadInProgress;
  const factory VendorTryOnSetupState.loadSuccess(VendorTryOnData data) =
      _LoadSuccess;
  const factory VendorTryOnSetupState.loadFailure(TryOnFailure failure) =
      _LoadFailure;

  VendorTryOnData? get dataOrNull =>
      maybeWhen(loadSuccess: (d) => d, orElse: () => null);
}

/// "Try-on & sizes" for one product. Mutations return their failure (or
/// null) so the screen can show the server's own message next to the part
/// that was refused; on success the readiness badge is re-read.
class VendorTryOnSetupNotifier extends StateNotifier<VendorTryOnSetupState> {
  VendorTryOnSetupNotifier(this._repository, this.productId)
    : super(const VendorTryOnSetupState.initial());

  final VendorTryOnRepository _repository;
  final String productId;
  static const _uuid = Uuid();

  Future<void> load() async {
    if (state.dataOrNull == null) {
      state = const VendorTryOnSetupState.loadInProgress();
    }
    final readiness = await _repository.getReadiness(productId);
    final chart = await _repository.getSizeChart(productId);
    if (!mounted) return;
    final failure =
        readiness.fold((f) => f, (_) => null) ??
        chart.fold((f) => f, (_) => null);
    if (failure != null) {
      state = VendorTryOnSetupState.loadFailure(failure);
      return;
    }
    state = VendorTryOnSetupState.loadSuccess(
      VendorTryOnData(
        readiness: readiness.getOrElse((_) => throw StateError('unreachable')),
        chart: chart.getOrElse((_) => null),
      ),
    );
  }

  Future<TryOnFailure?> saveChart(SizeChart chart) async {
    final issues = SizeChartRules.validate(chart);
    if (issues.isNotEmpty) {
      return TryOnFailure(
        TryOnFailureKind.rejected,
        code: 'validation.local',
        message: issues.join('\n'),
      );
    }
    final result = await _repository.saveSizeChart(
      productId,
      chart,
      idempotencyKey: _uuid.v4(),
    );
    return _afterMutation(result.fold((f) => f, (_) => null));
  }

  Future<TryOnFailure?> deleteChart() async {
    final result = await _repository.deleteSizeChart(
      productId,
      idempotencyKey: _uuid.v4(),
    );
    return _afterMutation(result.fold((f) => f, (_) => null));
  }

  Future<TryOnFailure?> uploadImage(
    String path, {
    void Function(double)? onProgress,
  }) async {
    final result = await _repository.uploadTryOnImage(
      productId,
      path,
      idempotencyKey: _uuid.v4(),
      onProgress: onProgress,
    );
    return _afterMutation(result.fold((f) => f, (_) => null));
  }

  Future<TryOnFailure?> deleteImage() async {
    final result = await _repository.deleteTryOnImage(
      productId,
      idempotencyKey: _uuid.v4(),
    );
    return _afterMutation(result.fold((f) => f, (_) => null));
  }

  Future<TryOnFailure?> _afterMutation(TryOnFailure? failure) async {
    if (failure == null && mounted) await load();
    return failure;
  }
}
