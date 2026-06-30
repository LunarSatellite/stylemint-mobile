import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/models/shipping_address_dto.dart';

class ShippingRemoteDataSource {
  ShippingRemoteDataSource({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<String> _accountId() async {
    final id = await tokenStorage.accountId;
    if (id == null || id.isEmpty) throw const NetworkExceptions.auth();
    return id;
  }

  Future<List<ShippingAddressDto>> getAddresses() async {
    final accountId = await _accountId();
    final response = await apiClient.get('/v1/accounts/$accountId/addresses');
    final data = response as List<dynamic>;
    return data
        .map((e) => ShippingAddressDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ShippingAddressDto> addAddress(
    ShippingAddressDto address,
    String idempotencyKey,
  ) async {
    final accountId = await _accountId();
    final response = await apiClient.post(
      '/v1/accounts/$accountId/addresses',
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
    final accountId = await _accountId();
    final response = await apiClient.put(
      '/v1/accounts/$accountId/addresses/$id',
      data: address.toJson(),
      options: _idempotent(idempotencyKey),
    );
    return ShippingAddressDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String id) async {
    final accountId = await _accountId();
    await apiClient.authDelete('/v1/accounts/$accountId/addresses/$id');
  }

  Future<void> setDefault(String id, String idempotencyKey) async {
    final accountId = await _accountId();
    await apiClient.post(
      '/v1/accounts/$accountId/addresses/$id/set-default',
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
