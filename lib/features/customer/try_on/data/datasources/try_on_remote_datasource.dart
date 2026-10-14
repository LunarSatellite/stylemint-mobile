import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/data/models/try_on_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';

/// The buyer's `/v1/try-on/*` endpoints plus the public size chart.
/// Throws; the repository maps what it throws.
class TryOnRemoteDataSource {
  TryOnRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  static String _id(String id) => Uri.encodeComponent(id);

  Future<TryOnAccess> getAccess() async =>
      readTryOnAccess(readJsonObject(await apiClient.get('/v1/try-on/access')));

  Future<TryOnAccess> startTrial(String idempotencyKey) async =>
      readTryOnAccess(
        readJsonObject(
          await apiClient.post(
            '/v1/try-on/trial',
            options: _idempotent(idempotencyKey),
          ),
        ),
      );

  Future<TryOnPaymentStart> subscribe({
    required String planId,
    required int paymentMethod,
    required String idempotencyKey,
  }) async => readTryOnPaymentStart(
    readJsonObject(
      await apiClient.post(
        '/v1/try-on/subscriptions',
        data: <String, dynamic>{
          'planId': planId,
          'paymentMethod': paymentMethod,
        },
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<MyTryOnSubscription> confirm({
    required String subscriptionId,
    required String idempotencyKey,
  }) async => readMySubscription(
    readJsonObject(
      await apiClient.post(
        '/v1/try-on/subscriptions/${_id(subscriptionId)}/confirm',
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<List<MyTryOnSubscription>> mySubscriptions() async =>
      readMySubscriptions(await apiClient.get('/v1/try-on/subscriptions/me'));

  Future<BodyMeasurements> getMeasurements() async => readBodyMeasurements(
    readJsonObject(await apiClient.get('/v1/try-on/me/measurements')),
  );

  Future<BodyMeasurements> putMeasurements(
    BodyMeasurements m,
    String idempotencyKey,
  ) async => readBodyMeasurements(
    readJsonObject(
      await apiClient.put(
        '/v1/try-on/me/measurements',
        data: writeBodyMeasurements(m),
        options: _idempotent(idempotencyKey),
      ),
    ),
  );

  Future<TryOnProduct> getProduct(String productId) async => readTryOnProduct(
    readJsonObject(
      await apiClient.get('/v1/try-on/products/${_id(productId)}'),
    ),
  );

  Future<FitRecommendation> getFit(String productId) async =>
      readFitRecommendation(
        readJsonObject(
          await apiClient.get('/v1/try-on/products/${_id(productId)}/fit'),
        ),
      );

  Future<void> recordSession({
    required String productId,
    required int mode,
    required String idempotencyKey,
    String? chosenSize,
  }) async {
    await apiClient.post(
      '/v1/try-on/sessions',
      data: <String, dynamic>{
        'productId': productId,
        'mode': mode,
        'chosenSize': chosenSize,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  Future<SizeChart> getPublicSizeChart(String productId) async => readSizeChart(
    readJsonObject(
      await apiClient.authGet('/v1/products/${_id(productId)}/size-chart'),
    ),
  );
}
