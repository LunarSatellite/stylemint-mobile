import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class ProfileRepository {
  Future<Either<NetworkExceptions, ProfileSummary>> getProfileSummary();

  Future<Either<NetworkExceptions, UserProfile>> getFullProfile();

  Future<Either<NetworkExceptions, UserProfile>> updateProfile({
    String? displayName,
    String? bio,
    String? website,
    String? avatarPath,
    String? gender,
    DateTime? dateOfBirth,
  });

  Future<Either<NetworkExceptions, PagedResult<FollowingUser>>> getFollowing({
    String? search,
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, Unit>> unfollowUser(String userId);
}
