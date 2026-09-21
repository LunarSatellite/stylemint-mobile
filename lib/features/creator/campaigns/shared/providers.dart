import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/datasources/creator_campaigns_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/repositories/creator_campaigns_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/repositories/creator_campaigns_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_applications_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_proposal_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_proposals_notifier.dart';

final creatorCampaignsRemoteDataSourceProvider =
    Provider<CreatorCampaignsRemoteDataSource>(
      (ref) => CreatorCampaignsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final creatorCampaignsRepositoryProvider = Provider<CreatorCampaignsRepository>(
  (ref) => CreatorCampaignsRepositoryImpl(
    remoteDataSource: ref.watch(creatorCampaignsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final campaignProposalsNotifierProvider =
    StateNotifierProvider<CampaignProposalsNotifier, CampaignProposalsState>(
      (ref) => CampaignProposalsNotifier(
        ref.watch(creatorCampaignsRepositoryProvider),
      ),
    );

final campaignApplicationsNotifierProvider =
    StateNotifierProvider<
      CampaignApplicationsNotifier,
      CampaignApplicationsState
    >(
      (ref) => CampaignApplicationsNotifier(
        ref.watch(creatorCampaignsRepositoryProvider),
      ),
    );

/// Keyed by brief id so two proposals never share a result, and autoDispose so
/// leaving the screen drops it — a creator who applies, backs out and opens a
/// different campaign must not see the first one's state.
final StateNotifierProviderFamily<
  CampaignProposalDetailNotifier,
  CampaignProposalDetailState,
  String
>
campaignProposalDetailProvider = StateNotifierProvider.autoDispose
    .family<
      CampaignProposalDetailNotifier,
      CampaignProposalDetailState,
      String
    >(
      (ref, briefId) => CampaignProposalDetailNotifier(
        ref.watch(creatorCampaignsRepositoryProvider),
        briefId,
      ),
    );
