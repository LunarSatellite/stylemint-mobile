import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/data/models/reach_dto.dart';

class ReachRemoteDataSource {
  ReachRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PublishTargetDto>> getPublishTargets() async {
    final response = await apiClient.get('/v1/reach/platform-connections');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => PublishTargetDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<void> schedulePublish({
    required String draftId,
    required List<String> platformNames,
    required DateTime scheduledAt,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/reach/publish-jobs',
      data: {
        'draftId': draftId,
        'platforms': platformNames,
        'scheduledAt': scheduledAt.toIso8601String(),
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<List<BoostCampaignDto>> getBoostCampaigns() async {
    final response = await apiClient.get('/v1/reach/boost-decisions/me');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => BoostCampaignDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<BoostCampaignDto> createBoostCampaign({
    required String reelId,
    required String platform,
    required double budgetAmount,
    required String budgetCurrency,
    required int durationDays,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/reach/budgets/me',
      data: {
        'reelId': reelId,
        'platform': platform,
        'budget': {'amount': budgetAmount, 'currency': budgetCurrency},
        'durationDays': durationDays,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return BoostCampaignDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ReachAnalyticsDto> getAnalytics({
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    final response = await apiClient.get(
      '/v1/reach/dashboard',
      queryParameters: {
        if (periodStart != null) 'periodStart': periodStart.toIso8601String(),
        if (periodEnd != null) 'periodEnd': periodEnd.toIso8601String(),
      },
    );
    return ReachAnalyticsDto.fromJson(response as Map<String, dynamic>);
  }
}
