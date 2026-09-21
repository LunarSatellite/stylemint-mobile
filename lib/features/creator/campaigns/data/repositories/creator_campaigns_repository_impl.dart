import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/datasources/creator_campaigns_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/models/campaign_application_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/models/campaign_proposal_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/repositories/creator_campaigns_repository.dart';

class CreatorCampaignsRepositoryImpl implements CreatorCampaignsRepository {
  CreatorCampaignsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorCampaignsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, CampaignPage<CampaignProposal>>>
  listProposals({String? cursor, int pageSize = 25}) =>
      guardedNetworkCall(networkInfo, () async {
        final page = await remoteDataSource.listProposals(
          cursor: cursor,
          pageSize: pageSize,
        );
        return CampaignPage<CampaignProposal>(
          items: page.items.map((d) => d.toDomain()).toList(growable: false),
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        );
      });

  @override
  Future<Either<NetworkExceptions, CampaignProposal>> getProposal(
    String briefId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getProposal(briefId)).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, CampaignApplication>> apply({
    required String briefId,
    String? message,
  }) => guardedNetworkCall(
    networkInfo,
    () async =>
        (await remoteDataSource.apply(briefId: briefId, message: message))
            .toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, CampaignPage<CampaignApplication>>>
  listApplications({
    List<CampaignApplicationState>? states,
    String? cursor,
    int pageSize = 25,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.listApplications(
      states: states?.map((s) => s.wire).toList(growable: false),
      cursor: cursor,
      pageSize: pageSize,
    );
    return CampaignPage<CampaignApplication>(
      items: page.items.map((d) => d.toDomain()).toList(growable: false),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  });

  @override
  Future<Either<NetworkExceptions, CampaignApplication>> withdraw(
    String applicationId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.withdraw(applicationId)).toDomain(),
  );
}
