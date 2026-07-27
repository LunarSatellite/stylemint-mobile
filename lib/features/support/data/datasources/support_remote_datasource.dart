import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/support/data/models/ticket_dto.dart';

class SupportRemoteDataSource {
  SupportRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<TicketDto>> getTickets() async {
    final response = await apiClient.get('/v1/support/tickets');
    final items = (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => _ticketFromApi(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<TicketDto> getTicketDetail(String ticketId) async {
    final response = await apiClient.get('/v1/support/tickets/$ticketId');
    return _ticketFromApi(response as Map<String, dynamic>);
  }

  // Backend returns `state` (1=Submitted, 2=InProgress, 3=Resolved) and
  // `openedUtc`/`lastAgentReplyUtc` — not the flat `status`/`createdAt`/
  // `lastUpdated` shape this DTO models, so map it explicitly.
  TicketDto _ticketFromApi(Map<String, dynamic> json) {
    const stateNames = {1: 'open', 2: 'in_progress', 3: 'resolved'};
    final openedUtc = DateTime.parse(json['openedUtc'] as String);
    final lastAgentReplyUtc = json['lastAgentReplyUtc'] != null
        ? DateTime.parse(json['lastAgentReplyUtc'] as String)
        : null;
    return TicketDto(
      id: json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      subject: json['subject'] as String,
      status: stateNames[json['state'] as int] ?? 'open',
      createdAt: openedUtc,
      lastUpdated: lastAgentReplyUtc ?? openedUtc,
    );
  }

  /// `OpenTicketVm` requires `category` (int enum id) and `body` (not
  /// `message`) — `categoryId` here is the string form of that same int,
  /// sourced from [getSupportCategories]'s real `HelpCategoryDto.id`.
  Future<TicketDto> createTicket({
    required String subject,
    required String message,
    String? categoryId,
  }) async {
    final data = <String, dynamic>{
      'subject': subject,
      'body': message,
      if (categoryId != null) 'category': int.parse(categoryId),
    };
    final response = await apiClient.post('/v1/support/tickets', data: data);
    return _ticketFromApi(response as Map<String, dynamic>);
  }

  Future<List<SupportCategoryDto>> getSupportCategories() async {
    final response = await apiClient.get('/v1/help/categories');
    final items = (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => _categoryFromApi(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  SupportCategoryDto _categoryFromApi(Map<String, dynamic> json) =>
      SupportCategoryDto(
        id: (json['id'] as num).toString(),
        title: json['name'] as String? ?? '',
        iconName: '',
      );
}
