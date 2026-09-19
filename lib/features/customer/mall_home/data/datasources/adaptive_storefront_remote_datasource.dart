import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/storefront_layout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';

/// Discovery's adaptive storefront endpoints, both of which require a token.
class AdaptiveStorefrontRemoteDataSource {
  AdaptiveStorefrontRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/customer/feed';

  static Options _authed() => Options(headers: {'requiresToken': true});

  /// `GET v1/customer/feed/storefront-layout`.
  Future<StorefrontLayout> getLayout() async {
    final response = await apiClient.get(
      '$_base/storefront-layout',
      options: _authed(),
    );
    return storefrontLayoutFromJson(readJsonObject(response));
  }

  /// `POST v1/customer/feed/interaction` — fire-and-forget, `204`.
  Future<void> trackInteraction(FeedSignal signal) async {
    await apiClient.post(
      '$_base/interaction',
      data: signal.toJson(),
      options: _authed(),
    );
  }
}
