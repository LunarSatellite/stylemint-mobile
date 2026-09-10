import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/data/models/tip_dto.dart';

class TipsRemoteDataSource {
  TipsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<TipDto> sendTip({
    required String creatorProfileId,
    required double amount,
    required String currency,
    required String paymentIntentId,
    String? reelId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/tips',
      data: {
        'toCreatorProfileId': creatorProfileId,
        'amountValue': amount,
        'currency': currency,
        'paymentIntentId': paymentIntentId,
        if (reelId != null) 'reelId': reelId,
      },
      options: _idempotent(idempotencyKey),
    );
    return TipDto.fromTipJson(response as Map<String, dynamic>);
  }

  Future<List<TipDto>> getTipHistory({required String type}) async {
    final response = await apiClient.get(
      '/v1/tips/history',
      queryParameters: {'type': type, 'pageSize': 50},
    );
    final page = response as Map<String, dynamic>? ?? const {};
    final items = page['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => TipDto.fromHistoryJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<TipBalanceDto> getBalance() async {
    final response = await apiClient.get(
      '/v1/tips/balance',
      queryParameters: const {'currency': 'NPR'},
    );
    return TipBalanceDto.fromApiJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
