import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/data/datasources/reel_approvals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/data/models/reel_approval_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/repositories/reel_approvals_repository.dart';

class ReelApprovalsRepositoryImpl implements ReelApprovalsRepository {
  ReelApprovalsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReelApprovalsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<ReelApprovalRequest>>> listPending() =>
      guardedNetworkCall(
        networkInfo,
        () async => (await remoteDataSource.listPending())
            .map((d) => d.toDomain())
            .toList(growable: false),
      );

  @override
  Future<Either<NetworkExceptions, Unit>> approve(String requestId) =>
      guardedNetworkCall(networkInfo, () async {
        await remoteDataSource.approve(requestId);
        return unit;
      });

  @override
  Future<Either<NetworkExceptions, ReelApprovalRequest>> reject({
    required String requestId,
    String? reason,
  }) => guardedNetworkCall(
    networkInfo,
    () async =>
        (await remoteDataSource.reject(requestId: requestId, reason: reason))
            .toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, ReelApprovalRequest>> submitForApproval({
    required String reelId,
    String? note,
  }) => guardedNetworkCall(
    networkInfo,
    () async =>
        (await remoteDataSource.submitForApproval(reelId: reelId, note: note))
            .toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, List<ReelApprovalRequest>>> approvalRounds(
    String reelId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.approvalRounds(reelId))
        .map((d) => d.toDomain())
        .toList(growable: false),
  );
}
