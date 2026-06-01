import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/data/models/tip_dto.dart';

class TipsRemoteDataSource {
  TipsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<TipDto> sendTip({
    required String creatorId,
    required double amount,
    String? message,
    String? reelId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/tips',
      data: {
        'creatorId': creatorId,
        'amount': amount,
        if (message != null && message.isNotEmpty) 'message': message,
        if (reelId != null) 'reelId': reelId,
      },
      options: _idempotent(idempotencyKey),
    );
    return TipDto.fromJson(response as Map<String, dynamic>);
  }

  /// TODO(swagger): No tip history endpoint — only GET /v1/tips/{id} (single tip).
  Future<List<TipDto>> getTipHistory({required String type}) async {
    final response = await apiClient.get(
      '/v1/tips/history',
      queryParameters: {'type': type},
    );
    final items = (response as List<dynamic>?)
        ?.map((e) => TipDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items ?? const [];
  }

  /// TODO(swagger): No tip balance endpoint. Check /v1/earnings/balance for creator earnings.
  Future<TipBalanceDto> getBalance() async {
    final response = await apiClient.get('/v1/tips/balance');
    return TipBalanceDto.fromJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
