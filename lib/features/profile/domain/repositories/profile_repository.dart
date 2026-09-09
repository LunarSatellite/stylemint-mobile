import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/creator_social_links.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class ProfileRepository {
  Future<Either<NetworkExceptions, ProfileSummary>> getProfileSummary();

  Future<Either<NetworkExceptions, UserProfile>> getFullProfile();

  Future<Either<NetworkExceptions, UserProfile>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    required String rowVersion,
  });

  Future<Either<NetworkExceptions, UserProfile>> uploadAvatar({
    required String filePath,
    required String rowVersion,
  });

  Future<Either<NetworkExceptions, CreatorSocialLinks>> getCreatorSocialLinks();

  Future<Either<NetworkExceptions, Unit>> updateCreatorSocialLinks({
    required String instagramHandle,
    required String tiktokHandle,
  });

  Future<Either<NetworkExceptions, PagedResult<FollowingUser>>> getFollowing({
    String? search,
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, Unit>> unfollowUser(String userId);

  /// Requests the account's GDPR Article 20 data export archive.
  Future<Either<NetworkExceptions, Unit>> requestDataExport();

  Future<Either<NetworkExceptions, ProfileSummary>> getProfileStats(
    ProfileSummary base,
  );
}
