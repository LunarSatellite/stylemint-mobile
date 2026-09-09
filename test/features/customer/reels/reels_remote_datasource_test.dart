import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';

class _CapturingApiClient extends ApiClient {
  _CapturingApiClient() : super(dio: Dio());

  String? postUri;
  String? deleteUri;
  Object? postData;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    deleteUri = uri;
    return null;
  }
}

void main() {
  test('uses the one-way follow API for reel creators', () async {
    final api = _CapturingApiClient();
    final datasource = ReelsRemoteDataSource(apiClient: api);

    await datasource.followCreator('creator-account', 'key-1');
    await datasource.unfollowCreator('creator-account', 'key-2');

    expect(api.postUri, '/v1/follows/creator-account');
    expect(api.postData, isNull);
    expect(api.deleteUri, '/v1/follows/creator-account');
  });
}
