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
        final vm = DraftBriefVm(
          vendorProfileId: brief.vendorProfileId,
          title: brief.title,
          primaryGoal: brief.primaryGoal,
          currencyCode: brief.boostBudget.currency,
        );
        final created = await remoteDataSource.createCampaign(
          data: vm.toJson(),
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
        final vm = UpdateBriefVm(
          title: brief.title,
          primaryGoal: brief.primaryGoal,
          commissionRange: CommissionRangeDto(
            minPercent: brief.commissionMinPercent,
            maxPercent: brief.commissionMaxPercent,
          ),
          boostBudgetAmount: brief.boostBudget.amount,
          boostBudgetCurrency: brief.boostBudget.currency,
        );
        final updated = await remoteDataSource.updateCampaign(
          id: id,
          data: vm.toJson(),
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
    String? niche,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.searchCreators(
          query: query,
          niche: niche,
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
  Future<Either<NetworkExceptions, void>> inviteCreator({
    required String creatorProfileId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? brandBriefId,
    String? message,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.inviteCreator(
          creatorProfileId: creatorProfileId,
          commissionMinPercent: commissionMinPercent,
          commissionMaxPercent: commissionMaxPercent,
          brandBriefId: brandBriefId,
          message: message,
          idempotencyKey: const Uuid().v4(),
        );
        return right(null);
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
