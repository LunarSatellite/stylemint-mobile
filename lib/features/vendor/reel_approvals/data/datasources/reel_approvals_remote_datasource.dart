import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/data/models/reel_approval_request_dto.dart';

/// The reel approval gate, both sides of it.
///
/// The vendor inbox and the creator's submit/history routes live on the same
/// module and are kept together here because they are one conversation: a
/// creator submits, a vendor answers, and the rounds accumulate.
///
/// No idempotency key is passed: `dio_client` already attaches one to every
/// non-safe mutation.
class ReelApprovalsRemoteDataSource {
  ReelApprovalsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/vendor/reel-approvals — everything waiting on this vendor.
  ///
  /// Returns a bare array, not a paged envelope.
  Future<List<ReelApprovalRequestDto>> listPending() async {
    final response = await apiClient.get('/v1/vendor/reel-approvals');
    return (response as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ReelApprovalRequestDto.fromJson)
        .toList(growable: false);
  }

  /// POST /v1/vendor/reel-approvals/{requestId}/approve
  ///
  /// Approving publishes the reel, so the server answers with the reel rather
  /// than the request. The body is not parsed here: the caller reloads the
  /// inbox, and the published reel belongs to the reels feature, not this one.
  ///
  /// 409 means the round was already settled — by the other decision, or by
  /// the expiry sweep returning the reel to draft while the inbox was open.
  Future<void> approve(String requestId) async {
    await apiClient.post('/v1/vendor/reel-approvals/$requestId/approve');
  }

  /// POST /v1/vendor/reel-approvals/{requestId}/reject
  ///
  /// [reason] is optional. A vendor may reject without saying why, so an empty
  /// box sends no field rather than an empty string — the creator's history
  /// then shows a rejection with no reason, which is what happened.
  Future<ReelApprovalRequestDto> reject({
    required String requestId,
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    final response = await apiClient.post(
      '/v1/vendor/reel-approvals/$requestId/reject',
      data: <String, dynamic>{
        if (trimmed != null && trimmed.isNotEmpty) 'reason': trimmed,
      },
    );
    return ReelApprovalRequestDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/creator/reels/{reelId}/submit-for-approval
  ///
  /// Opens a new round. 409 when one is already pending for this reel — only
  /// one round is live at a time.
  Future<ReelApprovalRequestDto> submitForApproval({
    required String reelId,
    String? note,
  }) async {
    final trimmed = note?.trim();
    final response = await apiClient.post(
      '/v1/creator/reels/$reelId/submit-for-approval',
      data: <String, dynamic>{
        if (trimmed != null && trimmed.isNotEmpty) 'note': trimmed,
      },
    );
    return ReelApprovalRequestDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET /v1/creator/reels/{reelId}/approval-rounds — every round, settled
  /// ones included, so the creator can see what was said last time.
  Future<List<ReelApprovalRequestDto>> approvalRounds(String reelId) async {
    final response = await apiClient.get(
      '/v1/creator/reels/$reelId/approval-rounds',
    );
    return (response as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ReelApprovalRequestDto.fromJson)
        .toList(growable: false);
  }
}
