import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/data/models/live_session_dto.dart';

class LiveCommerceRemoteDataSource {
  LiveCommerceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<LiveSessionDto>> getLive() async {
    final response = await apiClient.get('/v1/live-commerce/live');
    return (response as List<dynamic>)
        .map((e) => LiveSessionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<LiveSessionDto>> getUpcoming() async {
    final response = await apiClient.get('/v1/live-commerce/upcoming');
    return (response as List<dynamic>)
        .map((e) => LiveSessionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<LiveSessionDto> getById(String id) async {
    final response = await apiClient.get('/v1/live-commerce/$id');
    return LiveSessionDto.fromJson(response as Map<String, dynamic>);
  }
}
