import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/datasources/creator_profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/repositories/creator_profile_repository.dart';

class CreatorProfileRepositoryImpl implements CreatorProfileRepository {
  CreatorProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorProfileRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<NetworkEither<List<BadgeAward>>> listMyBadges() async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos = await remoteDataSource.listMyBadges();
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<NetworkEither<List<BadgeAward>>> updateBadgeShowcase(
      List<String> awardIdsInOrder) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos =
          await remoteDataSource.updateBadgeShowcase(awardIdsInOrder);
      return right(dtos.map((d) => d.toDomain()).toList(growable: false));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<NetworkEither<CreatorProfile>> getCreatorProfile(
    String accountId,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getCreatorProfile(accountId);
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<NetworkEither<CreatorProfile>> updateCreatorProfile({
    required String accountId,
    required String rowVersion,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? tags,
    List<String>? niches,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.updateCreatorProfile(
        accountId: accountId,
        rowVersion: rowVersion,
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
        tags: tags,
        niches: niches,
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<NetworkEither<List<String>>> listSpecializationCategoryIds(
      String accountId) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final ids =
          await remoteDataSource.listSpecializationCategoryIds(accountId);
      return right(ids);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<NetworkEither<void>> addSpecialization(
      String accountId, String categoryId) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.addSpecialization(accountId, categoryId);
      return right(null);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<NetworkEither<void>> removeSpecialization(
      String accountId, String categoryId) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.removeSpecialization(accountId, categoryId);
      return right(null);
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
