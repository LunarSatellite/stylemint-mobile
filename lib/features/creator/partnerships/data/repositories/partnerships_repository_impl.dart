import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';
import 'package:uuid/uuid.dart';

class PartnershipsRepositoryImpl implements PartnershipsRepository {
  PartnershipsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final PartnershipsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<PartnershipInvite>>>
      getInvites() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getInvites();
        return right(
          dtos.map((d) => d.toInviteDomain()).toList(growable: false),
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
  Future<Either<NetworkExceptions, PartnershipInvite>> acceptInvite(
    String inviteId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.acceptInvite(
          inviteId,
          const Uuid().v4(),
        );
        return right(dto.toInviteDomain());
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
  Future<Either<NetworkExceptions, Unit>> declineInvite(
    String inviteId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.declineInvite(inviteId, const Uuid().v4());
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
  Future<Either<NetworkExceptions, List<ActivePartnership>>>
      getActivePartnerships() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getActivePartnerships();
        return right(
          dtos.map((d) => d.toActiveDomain()).toList(growable: false),
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
  Future<Either<NetworkExceptions, List<EndedPartnership>>>
      getEndedPartnerships() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getEndedPartnerships();
        return right(
          dtos.map((d) => d.toEndedDomain()).toList(growable: false),
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
  Future<Either<NetworkExceptions, PartnershipTerms>> getPartnershipTerms(
    String partnershipId,
  ) =>
      _guard(() async {
        final dto = await remoteDataSource.getPartnershipTerms(partnershipId);
        return dto.toDomain();
      });

  @override
  Future<Either<NetworkExceptions, List<PartnershipTerms>>> getTermsVersions(
    String partnershipId,
  ) =>
      _guard(() async {
        final dtos = await remoteDataSource.getTermsVersions(partnershipId);
        return dtos.map((d) => d.toDomain()).toList(growable: false);
      });

  @override
  Future<Either<NetworkExceptions, PotentialEarnings>> getPotentialEarnings(
    String partnershipId, {
    String? variantId,
  }) =>
      _guard(() async {
        final dto = await remoteDataSource.getPotentialEarnings(
          partnershipId,
          variantId: variantId,
        );
        return dto.toDomain();
      });

  @override
  Future<Either<NetworkExceptions, List<RecipeAttachmentInfo>>>
      getPartnershipRecipes(String partnershipId) => _guard(() async {
            final dtos =
                await remoteDataSource.getPartnershipRecipes(partnershipId);
            return dtos.map((d) => d.toDomain()).toList(growable: false);
          });

  /// Connectivity check + exception mapping shared by the brief/terms reads.
  Future<Either<NetworkExceptions, T>> _guard<T>(
    Future<T> Function() call,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await call());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
