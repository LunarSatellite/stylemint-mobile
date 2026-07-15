import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/data/models/reach_dto.dart';

class ReachRemoteDataSource {
  ReachRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PublishTargetDto>> getPublishTargets() async {
    final response = await apiClient.get('/v1/reach/publish-jobs');
    final jobs = response['items'] as List<dynamic>? ?? const <dynamic>[];
    final result = <PublishTargetDto>[];
    for (final item in jobs) {
      final job = item as Map<String, dynamic>;
      final jobId = job['id'] as String? ?? '';
      final scheduledUtc =
          DateTime.tryParse(job['scheduledUtc'] as String? ?? '') ??
              DateTime.now();
      final targets =
          job['targets'] as List<dynamic>? ?? const <dynamic>[];
      for (final t in targets) {
        final target = t as Map<String, dynamic>;
        final platformInt = target['platform'] as int? ?? -1;
        final stateInt = target['state'] as int? ?? 1;
        final platformName = switch (platformInt) {
          1 => 'instagram',
          2 => 'tiktok',
          3 => 'youtube',
          4 => 'facebook',
          _ => null,
        };
        if (platformName == null) continue; // skip StyleMint (0) or unknown
        final status = switch (stateInt) {
          3 => 'published',
          4 || 5 => 'failed',
          _ => 'scheduled',
        };
        result.add(PublishTargetDto(
          id: '${jobId}_$platformInt',
          platform: platformName,
          scheduledAt: scheduledUtc,
          status: status,
        ));
      }
    }
    return result;
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
