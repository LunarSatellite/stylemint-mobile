import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/datasources/vendor_partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/models/vendor_partnership_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class VendorPartnershipsRepositoryImpl implements VendorPartnershipsRepository {
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
          vendorProfileId: brief.vendorProfileId.isEmpty
              ? null
              : brief.vendorProfileId,
          title: brief.title,
          primaryGoal: brief.primaryGoal,
          currencyCode: brief.boostBudget.currency,
        );
        // json_serializable includes null fields by default, but the
        // backend's VendorProfileId is a non-nullable Guid â€” a literal
        // `null` fails deserialization, so the key must be absent, not null.
        final payload = vm.toJson()
          ..removeWhere((_, value) => value == null);
        final created = await remoteDataSource.createCampaign(
          data: payload,
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
  Future<Either<NetworkExceptions, CampaignBrief>> getCampaign(
    String id,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getCampaign(id);
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CampaignBrief>> lockCampaign(
    String id,
  ) => _briefAction(() => remoteDataSource.lockCampaign(id, const Uuid().v4()));

  @override
  Future<Either<NetworkExceptions, CampaignBrief>> forkCampaign(
    String id,
  ) => _briefAction(() => remoteDataSource.forkCampaign(id, const Uuid().v4()));

  @override
  Future<Either<NetworkExceptions, CampaignBrief>> retireCampaign(
    String id,
  ) =>
      _briefAction(() => remoteDataSource.retireCampaign(id, const Uuid().v4()));

  @override
  Future<Either<NetworkExceptions, RoiProjectionSummary>> recomputeRoi(
    String id,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.recomputeRoi(id, const Uuid().v4());
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  Future<Either<NetworkExceptions, CampaignBrief>> _briefAction(
    Future<CampaignBriefDto> Function() action,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await action();
        return right(dto.toDomain());
      } catch (e) {
        return left(_mapError(e));
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
    required String creatorAccountId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? brandBriefId,
    String? message,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // The picker returns Account.Id but the invite endpoint expects
        // CreatorProfile.Id on the partnership aggregate - sending the
        // account id stores it under CreatorProfileId and breaks the
        // chat-by-profile lookup. Resolve here so every caller stays
        // simple.
        final creatorProfileId = await remoteDataSource
            .getCreatorProfileIdByAccountId(creatorAccountId);
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
        return left(_mapError(e));
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, PagedResult<VendorPartnership>>>
  getPartnerships({List<PartnershipState>? states, String? cursor}) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getPartnerships(
          states: states
              ?.map((s) => PartnershipState.values.indexOf(s) + 1)
              .toList(growable: false),
          cursor: cursor,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (e) => VendorPartnershipDto.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(),
            )
            .toList(growable: false);
        return right(
          PagedResult(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? 20,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
          ),
        );
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, int>>
  getPendingCreatorRequestCount() async {
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getPendingCreatorRequestCount();
        return right(count);
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> acceptRequest(String id) =>
      _runAction(() => remoteDataSource.acceptRequest(id, const Uuid().v4()));

  @override
  Future<Either<NetworkExceptions, Unit>> declineRequest(String id) =>
      _runAction(() => remoteDataSource.declineRequest(id, const Uuid().v4()));

  @override
  Future<Either<NetworkExceptions, Unit>> resume(String id) =>
      _runAction(() => remoteDataSource.resume(id, const Uuid().v4()));

  @override
  Future<Either<NetworkExceptions, Unit>> pause(String id, {String? reason}) =>
      _runAction(
        () => remoteDataSource.pause(id, const Uuid().v4(), reason: reason),
      );

  @override
  Future<Either<NetworkExceptions, Unit>> end(String id, {String? reason}) =>
      _runAction(
        () => remoteDataSource.end(id, const Uuid().v4(), reason: reason),
      );

  @override
  Future<Either<NetworkExceptions, Unit>> adjustCommission(
    String id, {
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? reason,
  }) => _runAction(
    () => remoteDataSource.adjustCommission(
      id,
      const Uuid().v4(),
      commissionMinPercent: commissionMinPercent,
      commissionMaxPercent: commissionMaxPercent,
      reason: reason,
    ),
  );

  Future<Either<NetworkExceptions, Unit>> _runAction(
    Future<void> Function() action,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await action();
        return right(unit);
      } catch (e) {
        return left(_mapError(e));
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  NetworkExceptions _mapError(Object e) {
    if (e is DioException) return mapDioExceptionToNetworkException(e);
    if (e is NetworkExceptions) return e;
    return NetworkExceptions.unexpectedError();
  }
}
