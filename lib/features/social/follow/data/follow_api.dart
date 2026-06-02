import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';

/// Thin client for the one-way follow graph
/// (backend `stylemint-social-graph`, `/v1/follows`).
///
/// Follow targets are ACCOUNT ids. Note the creators-you-may-like feed labels
/// its id `creatorProfileId`, but that field is populated with the creator's
/// account id server-side, so it can be passed here directly.
class FollowApi {
  FollowApi(this._api);

  final ApiClient _api;

  /// POST /v1/follows/{followeeId} — idempotent.
  Future<void> follow(String followeeAccountId) async {
    await _api.post('/v1/follows/$followeeAccountId');
  }

  /// DELETE /v1/follows/{followeeId} — idempotent.
  Future<void> unfollow(String followeeAccountId) async {
    await _api.authDelete('/v1/follows/$followeeAccountId');
  }

  /// GET /v1/follows/{accountId}/stats → followers / following / isFollowedByViewer.
  Future<FollowStats> stats(String accountId) async {
    final res = await _api.get('/v1/follows/$accountId/stats');
    final map = res as Map<String, dynamic>;
    return FollowStats(
      accountId: (map['accountId'] as String?) ?? accountId,
      followers: (map['followers'] as num?)?.toInt() ?? 0,
      following: (map['following'] as num?)?.toInt() ?? 0,
      isFollowedByViewer: (map['isFollowedByViewer'] as bool?) ?? false,
    );
  }
}

class FollowStats {
  const FollowStats({
    required this.accountId,
    required this.followers,
    required this.following,
    required this.isFollowedByViewer,
  });

  final String accountId;
  final int followers;
  final int following;
  final bool isFollowedByViewer;
}

final followApiProvider = Provider<FollowApi>((ref) {
  return FollowApi(ref.watch(apiClientProvider));
});
