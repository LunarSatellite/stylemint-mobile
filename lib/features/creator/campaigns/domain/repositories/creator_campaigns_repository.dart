import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';

/// One page of results plus the cursor that continues it.
class CampaignPage<T> {
  const CampaignPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}

/// The creator's side of the campaign lifecycle: read the proposals a vendor
/// published, apply to one, and track what came of it.
abstract interface class CreatorCampaignsRepository {
  Future<Either<NetworkExceptions, CampaignPage<CampaignProposal>>>
  listProposals({String? cursor, int pageSize});

  /// `.notFound()` here means only "you may not read this brief" — the server
  /// answers 404 for draft, unpublished, retired, out-of-window and absent
  /// alike, so callers must not name a cause.
  Future<Either<NetworkExceptions, CampaignProposal>> getProposal(
    String briefId,
  );

  /// `.conflict()` means the creator already holds a live application on this
  /// brief's lineage — one slot per lineage, pending or accepted.
  Future<Either<NetworkExceptions, CampaignApplication>> apply({
    required String briefId,
    String? message,
  });

  Future<Either<NetworkExceptions, CampaignPage<CampaignApplication>>>
  listApplications({
    List<CampaignApplicationState>? states,
    String? cursor,
    int pageSize,
  });

  /// `.conflict()` means it was no longer pending — the vendor decided first.
  Future<Either<NetworkExceptions, CampaignApplication>> withdraw(
    String applicationId,
  );
}
