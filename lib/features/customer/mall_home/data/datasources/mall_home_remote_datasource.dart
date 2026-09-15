import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/home_dto.dart';

/// Discovery's Mall home endpoints. Throws on failure; the repository maps
/// errors.
class MallHomeRemoteDataSource {
  MallHomeRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `api/v1/public/home`. Anonymous; the auth interceptor attaches the
  /// token when signed in, which personalises the response.
  Future<HomeResponseDto> getHome() async {
    final response = await apiClient.get('/api/v1/public/home');
    return HomeResponseDto.fromJson(readJsonObject(response));
  }

  /// POST `api/v1/customer/recently-viewed` — `204`, naturally idempotent.
  Future<void> recordRecentlyViewed(
    String productId, {
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/api/v1/customer/recently-viewed',
      data: {'productId': productId},
      options: Options(
        headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
      ),
    );
  }
}
