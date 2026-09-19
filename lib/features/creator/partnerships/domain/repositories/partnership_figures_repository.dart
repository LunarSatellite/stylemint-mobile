import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership_figures.dart';

/// Reads for the two per-partnership figures the backend records.
///
/// Deliberately its own port rather than four more methods on
/// `PartnershipsRepository`: these are per-card reads issued one partnership
/// at a time, they can each fail on their own without the list failing, and
/// keeping them separate means a screen that has no figures to draw does not
/// depend on the ability to fetch them.
abstract interface class PartnershipFiguresRepository {
  /// `GET /v1/creator/partnerships/{partnershipId}/affiliate-earnings`.
  ///
  /// A successful read can still carry [AffiliateAttribution.unknown] — that
  /// is an answer, not a failure, and the one the caller must render as "not
  /// tracked for this brand" rather than as a zero.
  Future<Either<NetworkExceptions, PartnershipAffiliateEarnings>>
  getAffiliateEarnings(String partnershipId);

  /// `GET /v1/creator/reels/tagged-products/by-partnership/{id}/count`.
  Future<Either<NetworkExceptions, PartnershipTagCounts>> getTagCounts(
    String partnershipId,
  );
}
