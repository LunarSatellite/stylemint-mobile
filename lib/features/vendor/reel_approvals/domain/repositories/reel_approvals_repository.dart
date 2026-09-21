import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';

/// The reel approval gate. Vendors answer; creators submit and read back the
/// rounds.
abstract interface class ReelApprovalsRepository {
  /// Everything waiting on this vendor.
  Future<Either<NetworkExceptions, List<ReelApprovalRequest>>> listPending();

  /// `.conflict()` means the round was already settled — the expiry sweep may
  /// have returned the reel to draft while the inbox was open.
  Future<Either<NetworkExceptions, Unit>> approve(String requestId);

  /// See [approve] for `.conflict()`. [reason] is optional: a vendor may
  /// reject without giving one.
  Future<Either<NetworkExceptions, ReelApprovalRequest>> reject({
    required String requestId,
    String? reason,
  });

  /// `.conflict()` means a round is already pending for this reel.
  Future<Either<NetworkExceptions, ReelApprovalRequest>> submitForApproval({
    required String reelId,
    String? note,
  });

  /// Every round for a reel, settled ones included.
  Future<Either<NetworkExceptions, List<ReelApprovalRequest>>> approvalRounds(
    String reelId,
  );
}
