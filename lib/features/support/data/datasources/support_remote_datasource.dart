import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/support/data/models/ticket_dto.dart';

class SupportRemoteDataSource {
  SupportRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<TicketDto>> getTickets() async {
    final response = await apiClient.get('/v1/support/tickets');
    final items = (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => TicketDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<TicketDto> getTicketDetail(String ticketId) async {
    final response = await apiClient.get('/v1/support/tickets/$ticketId');
    return TicketDto.fromJson(response as Map<String, dynamic>);
  }

  Future<TicketDto> createTicket({
    required String subject,
    required String message,
    String? categoryId,
  }) async {
    final data = <String, dynamic>{
      'subject': subject,
      'message': message,
      if (categoryId != null) 'categoryId': categoryId,
    };
    final response = await apiClient.post('/v1/support/tickets', data: data);
    return TicketDto.fromJson(response as Map<String, dynamic>);
  }

  /// TODO(swagger): No /v1/support/categories — use /v1/help/categories or keep as-is.
  Future<List<SupportCategoryDto>> getSupportCategories() async {
    final response = await apiClient.get('/v1/support/categories');
    final items = (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => SupportCategoryDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }
}
