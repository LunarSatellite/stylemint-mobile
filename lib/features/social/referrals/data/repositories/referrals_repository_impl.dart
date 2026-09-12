import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/data/datasources/referrals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/data/models/invite_link_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/domain/entities/invite_link.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/domain/repositories/referrals_repository.dart';

class ReferralsRepositoryImpl implements ReferralsRepository {
  ReferralsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReferralsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, InviteLink>> getOrCreateMyLink() => _call(() async {
    final page = await remoteDataSource.listMyLinks(pageSize: 1);
    final items = page['items'] as List<dynamic>? ?? const <dynamic>[];
    if (items.isNotEmpty) {
      return InviteLinkDto.fromJson(items.first as Map<String, dynamic>).toDomain();
    }
    final created = await remoteDataSource.createLink();
    return InviteLinkDto.fromJson(created).toDomain();
  });

  @override
  Future<Either<NetworkExceptions, List<InviteRedemption>>> getRedemptions(
    String linkId,
  ) => _call(() async {
    final page = await remoteDataSource.listRedemptions(linkId, pageSize: 50);
    final items = page['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .map((e) => InviteRedemptionDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList(growable: false);
  });

  @override
  Future<Either<NetworkExceptions, Unit>> redeem(String code) => _call(() async {
    await remoteDataSource.redeem(code);
    return unit;
  });

  Future<Either<NetworkExceptions, T>> _call<T>(Future<T> Function() body) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await body());
    } catch (e) {
      if (e is DioException) {
        return left(NetworkExceptions.server(e.message.toString()));
      } else if (e is NetworkExceptions) {
        return left(e);
      } else {
        return left(NetworkExceptions.unexpectedError());
      }
    }
  }
}
