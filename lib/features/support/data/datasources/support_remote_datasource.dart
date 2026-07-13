import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/support/data/models/ticket_dto.dart';

class SupportRemoteDataSource {
  SupportRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/support/tickets` returns a skip/take `PagedList`, not a bare
  /// array.
  Future<List<TicketDto>> getTickets() async {
    final response = await apiClient.get('/v1/support/tickets');
    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => TicketDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<TicketDto> getTicketDetail(String ticketNumber) async {
    final response = await apiClient.get('/v1/support/tickets/$ticketNumber');
    return TicketDto.fromJson(response as Map<String, dynamic>);
  }

  Future<TicketDto> createTicket({
    required String subject,
    required String body,
    required int category,
    List<String> attachmentUrls = const [],
  }) async {
    final data = <String, dynamic>{
      'category': category,
      'subject': subject,
      'body': body,
      'attachmentUrls': attachmentUrls,
    };
    final response = await apiClient.post('/v1/support/tickets', data: data);
    return TicketDto.fromJson(response as Map<String, dynamic>);
  }

  /// `GET /v1/help/categories` — there is no `/v1/support/categories`.
  /// Response rows are `HelpCategoryDto` (`id`, `code`, `name`,
  /// `publishedArticleCount`), not the `SupportCategoryDto` shape, so this
  /// maps fields explicitly instead of calling `SupportCategoryDto.fromJson`.
  Future<List<SupportCategoryDto>> getSupportCategories() async {
    final response = await apiClient.get('/v1/help/categories');
    final items = (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) {
          final json = e as Map<String, dynamic>;
          return SupportCategoryDto(
            id: json['id'].toString(),
            title: json['name'] as String,
            iconName: json['code'] as String,
          );
        })
        .toList(growable: false);
    return items;
  }
}
