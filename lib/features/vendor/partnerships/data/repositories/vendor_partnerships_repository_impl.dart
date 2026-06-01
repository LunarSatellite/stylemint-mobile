import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/datasources/vendor_partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/models/vendor_partnership_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';
import 'package:uuid/uuid.dart';

class VendorPartnershipsRepositoryImpl
    implements VendorPartnershipsRepository {
  VendorPartnershipsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorPartnershipsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<CampaignBrief>>> getCampaigns() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getCampaigns();
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, CampaignBrief>> createCampaign(
    CampaignBrief brief,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = CampaignBriefDto(
          id: '',
          title: brief.title,
          description: brief.description,
          commissionRate: brief.commissionRate,
          budgetAmount: brief.budget.amount,
          budgetCurrency: brief.budget.currency,
          startDate: brief.startDate,
          endDate: brief.endDate,
          targetCreators: brief.targetCreators,
          requiredCategories: brief.requiredCategories,
          status: brief.status.name,
          createdAt: brief.createdAt,
        );
        final created = await remoteDataSource.createCampaign(
          data: dto.toRequest(),
          idempotencyKey: const Uuid().v4(),
        );
        return right(created.toDomain());
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
  Future<Either<NetworkExceptions, CampaignBrief>> updateCampaign(
    String id,
    CampaignBrief brief,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = CampaignBriefDto(
          id: id,
          title: brief.title,
          description: brief.description,
          commissionRate: brief.commissionRate,
          budgetAmount: brief.budget.amount,
          budgetCurrency: brief.budget.currency,
          startDate: brief.startDate,
          endDate: brief.endDate,
          targetCreators: brief.targetCreators,
          requiredCategories: brief.requiredCategories,
          status: brief.status.name,
          createdAt: brief.createdAt,
        );
        final updated = await remoteDataSource.updateCampaign(
          id: id,
          data: dto.toRequest(),
          idempotencyKey: const Uuid().v4(),
        );
        return right(updated.toDomain());
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
  Future<Either<NetworkExceptions, List<CreatorInvite>>> searchCreators({
    String? query,
    List<String>? categories,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.searchCreators(
          query: query,
          categories: categories,
        );
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, CreatorInvite>> inviteCreator(
    String campaignId,
    String creatorId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.inviteCreator(
          campaignId: campaignId,
          creatorId: creatorId,
          idempotencyKey: const Uuid().v4(),
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
  Future<Either<NetworkExceptions, List<CreatorInvite>>> getInvites(
    String campaignId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getInvites(campaignId);
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
