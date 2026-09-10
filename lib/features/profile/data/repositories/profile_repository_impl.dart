import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/user_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/creator_social_links.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, ProfileSummary>> getProfileSummary() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getProfileSummary();
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, UserProfile>> getFullProfile() async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getFullProfile();
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, UserProfile>> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    required String rowVersion,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.updateProfile(
          displayName: displayName,
          bio: bio,
          avatarUrl: avatarUrl,
          gender: gender,
          dateOfBirth: dateOfBirth,
          rowVersion: rowVersion,
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, UserProfile>> uploadAvatar({
    required String filePath,
    required String rowVersion,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.uploadAvatar(
        filePath: filePath,
        rowVersion: rowVersion,
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, CreatorSocialLinks>>
  getCreatorSocialLinks() async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await remoteDataSource.getCreatorSocialLinks());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> updateCreatorSocialLinks({
    required String instagramHandle,
    required String tiktokHandle,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.updateCreatorSocialLinks(
        instagramHandle: instagramHandle,
        tiktokHandle: tiktokHandle,
      );
      return right(unit);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, PagedResult<FollowingUser>>> getFollowing({
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getFollowing(
          limit: limit,
          cursor: cursor,
        );
        // Backend has no server-side search on this endpoint — filter the
        // returned page client-side instead.
        final query = search?.trim().toLowerCase();
        final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => FollowingUserDto.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .where(
              (u) => query == null ||
                  query.isEmpty ||
                  u.displayName.toLowerCase().contains(query),
            )
            .toList(growable: false);
        return right(
          PagedResult<FollowingUser>(
            items: items,
            totalCount: response['totalCount'] as int? ?? items.length,
            pageSize: response['pageSize'] as int? ?? limit,
            nextCursor: response['nextCursor'] as String?,
            previousCursor: response['previousCursor'] as String?,
            hasMore: response['hasMore'] as bool? ?? false,
          ),
        );
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, ProfileSummary>> getProfileStats(
    ProfileSummary base,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final counts = await remoteDataSource.getStatsCounts();
        return right(
          base.copyWith(
            savedItemsCount: counts.savedItemsCount,
            followingCount: counts.followingCount,
            ordersCount: counts.ordersCount,
          ),
        );
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unfollowUser(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unfollowUser(userId);
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> requestDataExport() async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.requestDataExport();
      return right(unit);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(NetworkExceptions.unexpectedError());
    }
  }
}
