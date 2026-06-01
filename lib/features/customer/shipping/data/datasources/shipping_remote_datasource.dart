import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/models/shipping_address_dto.dart';

class ShippingRemoteDataSource {
  ShippingRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ShippingAddressDto>> getAddresses() async {
    final response = await apiClient.get('/v1/addresses');
    final data = response as List<dynamic>;
    return data
        .map((e) => ShippingAddressDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ShippingAddressDto> addAddress(
    ShippingAddressDto address,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/addresses',
      data: address.toJson(),
      options: _idempotent(idempotencyKey),
    );
    return ShippingAddressDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ShippingAddressDto> updateAddress(
    String id,
    ShippingAddressDto address,
    String idempotencyKey,
  ) async {
    final response = await apiClient.patch(
      '/v1/addresses/$id',
      data: address.toJson(),
      options: _idempotent(idempotencyKey),
    );
    return ShippingAddressDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    await apiClient.authDelete('/v1/addresses/$id');
  }

  Future<void> setDefault(String id, String idempotencyKey) async {
    await apiClient.post(
      '/v1/addresses/$id/default',
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
