import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';

/// `POST v1/customer/feed/interactions` (AI features contract v1.0 §2.1).
class EngagementRemoteDataSource {
  EngagementRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const String batchPath = '/v1/customer/feed/interactions';

  /// The contract's ceiling per call.
  static const int maxBatch = 50;

  Future<EngagementSendOutcome> send(List<EngagementEvent> events) async {
    try {
      await apiClient.post(
        batchPath,
        data: {
          'events': [for (final event in events.take(maxBatch)) event.toJson()],
        },
        options: Options(headers: {'requiresToken': true}),
      );
      return EngagementSendOutcome.accepted;
    } on DioException catch (e) {
      return outcomeFor(e.response?.statusCode);
    } on SocketException catch (_) {
      return EngagementSendOutcome.retry;
    } on TimeoutException catch (_) {
      return EngagementSendOutcome.retry;
    } on Object catch (_) {
      // Anything unexpected is treated as transient: a retry is idempotent.
      return EngagementSendOutcome.retry;
    }
  }

  /// What a failed call's status means for its events.
  static EngagementSendOutcome outcomeFor(int? status) {
    if (status == null) return EngagementSendOutcome.retry;
    if (status == 404) return EngagementSendOutcome.notDeployed;
    if (status == 408 || status == 429 || status >= 500) {
      return EngagementSendOutcome.retry;
    }
    if (status >= 400) return EngagementSendOutcome.rejected;
    return EngagementSendOutcome.accepted;
  }
}
