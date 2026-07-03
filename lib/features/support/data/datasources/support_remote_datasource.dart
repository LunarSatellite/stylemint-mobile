import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/support/data/models/ticket_dto.dart';

class SupportRemoteDataSource {
  SupportRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/api/v1/support/tickets`
  Future<List<TicketDto>> getTickets({int skip = 0, int take = 20}) async {
    final response = await apiClient.get(
      '/api/v1/support/tickets',
      queryParameters: {'skip': skip, 'take': take},
      
    );
    final map = response as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => TicketDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  /// GET `/api/v1/support/tickets/{ticketNumber}`
  Future<TicketDto> getTicketDetail(String ticketNumber) async {
    final response =
        await apiClient.get('/api/v1/support/tickets/$ticketNumber');
    return TicketDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/api/v1/support/tickets`
  Future<void> createTicket({
    required int category,
    String? subject,
    String? body,
    List<String> attachmentUrls = const [],
    String? orderId,
    String? subOrderId,
    String? returnRequestId,
  }) async {
    await apiClient.post(
      '/api/v1/support/tickets',
      data: {
        'category': category,
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
        if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
        if (orderId != null) 'orderId': orderId,
        if (subOrderId != null) 'subOrderId': subOrderId,
        if (returnRequestId != null) 'returnRequestId': returnRequestId,
      },
    );
  }

  /// POST `/api/v1/support/tickets/{ticketNumber}/replies`
  Future<void> replyToTicket({
    required String ticketNumber,
    required String body,
    List<String> attachmentUrls = const [],
  }) async {
    await apiClient.post(
      '/api/v1/support/tickets/$ticketNumber/replies',
      data: {
        'body': body,
        if (attachmentUrls.isNotEmpty) 'attachmentUrls': attachmentUrls,
      },
    );
  }
}
