import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/profile_mock_data.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

/// In-memory repository stub used for the Following screen in development.
/// Only [getFollowing] and [unfollowUser] are implemented; other methods are
/// unused by this feature and return a no-op error.
///
/// To restore real network calls, swap [followingNotifierProvider] back to
/// [FollowingNotifier(ref.watch(profileRepositoryProvider))].
class MockProfileRepository implements ProfileRepository {
  final List<FollowingUser> _users = List.of(kMockFollowingUsers);

  @override
  Future<Either<NetworkExceptions, PagedResult<FollowingUser>>> getFollowing({
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    var results = _users;
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      results = _users
          .where((u) =>
              u.displayName.toLowerCase().contains(q) ||
              u.handle.toLowerCase().contains(q) ||
              (u.category?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    return right(PagedResult(
      items: results,
      totalCount: results.length,
      pageSize: limit,
      hasMore: false,
    ));
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unfollowUser(String userId) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      _users[idx] = _users[idx].copyWith(isFollowing: false);
    }
    return right(unit);
  }

  // ── Stubs (not used by FollowingNotifier) ─────────────────────────────────

  @override
  Future<Either<NetworkExceptions, ProfileSummary>> getProfileSummary() async =>
      left(const NetworkExceptions.noInternetConnection());

  @override
  Future<Either<NetworkExceptions, UserProfile>> getFullProfile() async =>
      left(const NetworkExceptions.noInternetConnection());

  @override
  Future<Either<NetworkExceptions, UserProfile>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    required String rowVersion,
  }) async =>
      left(const NetworkExceptions.noInternetConnection());

  @override
  Future<Either<NetworkExceptions, ProfileSummary>> getProfileStats(
    ProfileSummary base,
  ) async =>
      left(const NetworkExceptions.noInternetConnection());
}
