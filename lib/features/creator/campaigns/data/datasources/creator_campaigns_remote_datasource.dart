import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/models/campaign_application_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/models/campaign_proposal_dto.dart';

/// One cursor page of proposals.
class CampaignProposalPage {
  const CampaignProposalPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<CampaignProposalDto> items;

  /// Null when the server did not offer one. Paging stops on [hasMore], not on
  /// this being null, because the two are the server's to decide separately.
  final String? nextCursor;

  final bool hasMore;
}

/// One cursor page of the creator's own applications.
class CampaignApplicationPage {
  const CampaignApplicationPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<CampaignApplicationDto> items;
  final String? nextCursor;
  final bool hasMore;
}

/// The creator's side of the campaign lifecycle.
///
/// Reads land on BrandStudio's `CreatorCampaignsController`; the writes land on
/// Partnerships' sibling controller under the same URL prefix. That split is
/// the server's business — from here it is one surface.
///
/// No request carries an idempotency key: `dio_client` attaches one to every
/// non-safe mutation already, and a second key generated here would defeat it.
class CreatorCampaignsRemoteDataSource {
  CreatorCampaignsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/creator/campaigns — every proposal open to creators right now.
  ///
  /// Which briefs qualify is judged server-side against the server clock. The
  /// client sends no instant and must not filter the result further: a brief
  /// in this list is one the creator may apply to, by definition.
  Future<CampaignProposalPage> listProposals({
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/campaigns',
      queryParameters: {'pageSize': pageSize, 'cursor': ?cursor},
    );
    final data = response as Map<String, dynamic>;
    return CampaignProposalPage(
      items: (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CampaignProposalDto.fromJson)
          .toList(growable: false),
      nextCursor: data['nextCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// GET /v1/creator/campaigns/{briefId} — the full proposal.
  ///
  /// 404 covers every way a brief can fail to be readable — draft, unpublished,
  /// retired, out of window, or absent — deliberately, so a caller cannot
  /// enumerate campaigns that were never published. Callers must therefore not
  /// tell the user which of those it was.
  Future<CampaignProposalDto> getProposal(String briefId) async {
    final response = await apiClient.get('/v1/creator/campaigns/$briefId');
    return CampaignProposalDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/creator/campaigns/{briefId}/applications
  ///
  /// [message] is the creator's pitch and is optional. Null and empty are the
  /// same thing to the server here, so an empty box sends no field at all
  /// rather than an empty string.
  Future<CampaignApplicationDto> apply({
    required String briefId,
    String? message,
  }) async {
    final trimmed = message?.trim();
    final response = await apiClient.post(
      '/v1/creator/campaigns/$briefId/applications',
      data: <String, dynamic>{
        if (trimmed != null && trimmed.isNotEmpty) 'message': trimmed,
      },
    );
    return CampaignApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET /v1/creator/campaigns/applications — the creator's own applications.
  ///
  /// [states] filters by wire value; omitted means every state.
  Future<CampaignApplicationPage> listApplications({
    List<int>? states,
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/campaigns/applications',
      queryParameters: {
        'pageSize': pageSize,
        'cursor': ?cursor,
        if (states != null && states.isNotEmpty) 'states': states,
      },
    );
    final data = response as Map<String, dynamic>;
    return CampaignApplicationPage(
      items: (data['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CampaignApplicationDto.fromJson)
          .toList(growable: false),
      nextCursor: data['nextCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// POST /v1/creator/campaigns/applications/{applicationId}/withdraw
  ///
  /// Answers 409 when the application is no longer pending — the vendor may
  /// have decided between the screen rendering and the tap.
  Future<CampaignApplicationDto> withdraw(String applicationId) async {
    final response = await apiClient.post(
      '/v1/creator/campaigns/applications/$applicationId/withdraw',
    );
    return CampaignApplicationDto.fromJson(response as Map<String, dynamic>);
  }
}
