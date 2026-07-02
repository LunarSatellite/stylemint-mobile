import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/entities/vendor_product_analytics.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/repositories/vendor_product_analytics_repository.dart';

part 'vendor_product_analytics_notifier.freezed.dart';

@freezed
abstract class VendorProductAnalyticsState with _$VendorProductAnalyticsState {
  const factory VendorProductAnalyticsState.initial() = _Initial;
  const factory VendorProductAnalyticsState.loadInProgress() = _LoadInProgress;
  const factory VendorProductAnalyticsState.loadSuccess(
    VendorProductAnalytics analytics,
  ) = _LoadSuccess;
  const factory VendorProductAnalyticsState.loadFailure(
    NetworkExceptions failure,
  ) = _LoadFailure;
}

/// Unlike most vendor notifiers, this one does NOT auto-load on construction
/// — the product id is a navigation argument, not known until the screen
/// calls [load] explicitly (e.g. from `initState`).
class VendorProductAnalyticsNotifier
    extends StateNotifier<VendorProductAnalyticsState> {
  VendorProductAnalyticsNotifier(this._repository)
    : super(const VendorProductAnalyticsState.initial());

  final VendorProductAnalyticsRepository _repository;

  Future<void> load({
    required String productId,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    state = const VendorProductAnalyticsState.loadInProgress();
    final either = await _repository.getProductAnalytics(
      productId: productId,
      fromUtc: fromUtc,
      toUtc: toUtc,
    );
    state = either.fold(
      VendorProductAnalyticsState.loadFailure,
      VendorProductAnalyticsState.loadSuccess,
    );
  }
}
