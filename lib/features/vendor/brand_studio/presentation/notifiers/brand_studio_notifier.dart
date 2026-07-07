import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/repositories/brand_studio_repository.dart';

part 'brand_studio_notifier.freezed.dart';

@freezed
abstract class BrandStudioState with _$BrandStudioState {
  const BrandStudioState._();

  const factory BrandStudioState.initial() = _BrandStudioInitial;
  const factory BrandStudioState.loadInProgress() = _BrandStudioLoadInProgress;
  const factory BrandStudioState.loadSuccess({
    required BrandStudioInsights insights,
    required int windowDays,
  }) = _BrandStudioLoadSuccess;
  const factory BrandStudioState.loadFailure(NetworkExceptions failure) =
      _BrandStudioLoadFailure;
}

class BrandStudioNotifier extends StateNotifier<BrandStudioState> {
  BrandStudioNotifier(this._repository)
    : super(const BrandStudioState.initial()) {
    unawaited(load());
  }

  final BrandStudioRepository _repository;

  Future<void> load({int windowDays = 30}) async {
    state = const BrandStudioState.loadInProgress();
    final result = await _repository.getInsights(windowDays: windowDays);
    state = result.fold(
      BrandStudioState.loadFailure,
      (insights) => BrandStudioState.loadSuccess(
        insights: insights,
        windowDays: windowDays,
      ),
    );
  }
}
