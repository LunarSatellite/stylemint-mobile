import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/models/product_inquiry_dto.dart';

/// Vendor product inquiries — `/v1/product-inquiries`.
class InquiriesRemoteDataSource {
  InquiriesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET vendor's inquiry queue (first page). PagedResult — items under `items`.
  Future<List<ProductInquiryDto>> listVendor({int pageSize = 50}) async {
    final response = await apiClient.get(
      '/v1/product-inquiries/vendor',
      queryParameters: {'pageSize': pageSize},
    );
    final map = response as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ProductInquiryDto.fromJson)
        .toList(growable: false);
  }

  /// POST a reply to an inquiry; returns the updated inquiry.
  Future<ProductInquiryDto> reply(String inquiryId, String reply) async {
    final response = await apiClient.post(
      '/v1/product-inquiries/$inquiryId/reply',
      data: {'reply': reply},
    );
    return ProductInquiryDto.fromJson(response as Map<String, dynamic>);
  }
}
