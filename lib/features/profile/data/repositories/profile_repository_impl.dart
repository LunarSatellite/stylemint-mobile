import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/user_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
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
    String? website,
    String? avatarPath,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.updateProfile(
          displayName: displayName,
          bio: bio,
          website: website,
          avatarPath: avatarPath,
          gender: gender,
          dateOfBirth: dateOfBirth,
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
  Future<Either<NetworkExceptions, PagedResult<FollowingUser>>> getFollowing({
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getFollowing(
          search: search,
          limit: limit,
          cursor: cursor,
        );
        final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => FollowingUserDto.fromJson(e as Map<String, dynamic>).toDomain())
            .toList(growable: false);
        return right(PagedResult<FollowingUser>(
          items: items,
          totalCount: response['totalCount'] as int? ?? items.length,
          pageSize: response['pageSize'] as int? ?? limit,
          nextCursor: response['nextCursor'] as String?,
          previousCursor: response['previousCursor'] as String?,
          hasMore: response['hasMore'] as bool? ?? false,
        ));
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
}
