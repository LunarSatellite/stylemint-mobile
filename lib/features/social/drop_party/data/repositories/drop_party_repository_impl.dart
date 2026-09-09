import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/data/datasources/drop_party_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/repositories/drop_party_repository.dart';

class DropPartyRepositoryImpl implements DropPartyRepository {
  DropPartyRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final DropPartyRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<DropParty>>>
  getActiveDropParties() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getActiveDropParties();
        return right(dtos.map((dto) => dto.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, DropParty>> getDropParty(
    String partyId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getDropParty(partyId);
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
  Future<Either<NetworkExceptions, void>> rsvp(String partyId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.rsvp(partyId, _uuid.v4());
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

  @override
  Future<Either<NetworkExceptions, void>> joinLive(String partyId) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      await remoteDataSource.joinLive(partyId, _uuid.v4());
      return right(null);
    } on DioException catch (error) {
      return left(NetworkExceptions.server(error.message.toString()));
    } on NetworkExceptions catch (error) {
      return left(error);
    } catch (_) {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, DropParty>> scanInviteQr(
    String qrCode,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.scanInviteQr(qrCode, _uuid.v4());
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
}
