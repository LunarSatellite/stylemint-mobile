import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/repositories/brand_studio_repository.dart';

part 'brand_studio_notifier.freezed.dart';

@freezed
abstract class TemplatesState with _$TemplatesState {
  const TemplatesState._();

  const factory TemplatesState.initial() = _TemplatesInitial;
  const factory TemplatesState.loadInProgress() = _TemplatesLoadInProgress;
  const factory TemplatesState.loadSuccess({
    required List<CampaignTemplate> templates,
  }) = _TemplatesLoadSuccess;
  const factory TemplatesState.loadFailure(NetworkExceptions failure) =
      _TemplatesLoadFailure;
}

@freezed
abstract class AnalyticsState with _$AnalyticsState {
  const AnalyticsState._();

  const factory AnalyticsState.initial() = _AnalyticsInitial;
  const factory AnalyticsState.loadInProgress() = _AnalyticsLoadInProgress;
  const factory AnalyticsState.loadSuccess({
    required CampaignAnalytics analytics,
  }) = _AnalyticsLoadSuccess;
  const factory AnalyticsState.loadFailure(NetworkExceptions failure) =
      _AnalyticsLoadFailure;
}

@freezed
abstract class InsightsState with _$InsightsState {
  const InsightsState._();

  const factory InsightsState.initial() = _InsightsInitial;
  const factory InsightsState.loadInProgress() = _InsightsLoadInProgress;
  const factory InsightsState.loadSuccess({
    required List<MarketInsight> insights,
  }) = _InsightsLoadSuccess;
  const factory InsightsState.loadFailure(NetworkExceptions failure) =
      _InsightsLoadFailure;
}

class BrandStudioNotifier extends StateNotifier<BrandStudioState> {
  BrandStudioNotifier(this._repository) : super(const BrandStudioState.initial()) {
    unawaited(loadAll());
  }

  final BrandStudioRepository _repository;

  Future<void> loadAll() async {
    state = const BrandStudioState.loadInProgress();
    final templates = await _repository.getTemplates();
    final insights = await _repository.getMarketInsights();

    state = templates.fold(
      (f) => BrandStudioState.loadFailure(f),
      (t) => insights.fold(
        (f) => BrandStudioState.loadFailure(f),
        (i) => BrandStudioState.loadSuccess(templates: t, insights: i),
      ),
    );
  }

  Future<void> loadTemplates({String? industry}) async {
    final result = await _repository.getTemplates(industry: industry);
    result.fold(
      (_) {},
      (templates) {
        state = state.maybeWhen(
          loadSuccess: (t, i, _) =>
              BrandStudioState.loadSuccess(templates: t, insights: i),
          loadInProgress: () => BrandStudioState.loadSuccess(
              templates: templates, insights: const <MarketInsight>[]),
          orElse: () => BrandStudioState.loadSuccess(
              templates: templates, insights: const <MarketInsight>[]),
        );
      },
    );
  }

  Future<void> loadAnalytics(String campaignId) async {
    final result = await _repository.getCampaignAnalytics(campaignId);
    result.fold(
      (f) => state = BrandStudioState.analyticsFailure(f),
      (analytics) {
        state = state.maybeWhen(
          loadSuccess: (t, i, _) => BrandStudioState.loadSuccess(
              templates: t, insights: i, analytics: analytics),
          loadInProgress: () => const BrandStudioState.initial(),
          orElse: () => const BrandStudioState.initial(),
        );
        _analyticsState = AnalyticsState.loadSuccess(analytics: analytics);
      },
    );
  }

  AnalyticsState _analyticsState = const AnalyticsState.initial();
  AnalyticsState get analyticsState => _analyticsState;
}

@freezed
abstract class BrandStudioState with _$BrandStudioState {
  const BrandStudioState._();

  const factory BrandStudioState.initial() = _BrandStudioInitial;
  const factory BrandStudioState.loadInProgress() = _BrandStudioLoadInProgress;
  const factory BrandStudioState.loadSuccess({
    required List<CampaignTemplate> templates,
    required List<MarketInsight> insights,
    CampaignAnalytics? analytics,
  }) = _BrandStudioLoadSuccess;
  const factory BrandStudioState.loadFailure(NetworkExceptions failure) =
      _BrandStudioLoadFailure;
  const factory BrandStudioState.analyticsFailure(NetworkExceptions failure) =
      _BrandStudioAnalyticsFailure;
}
