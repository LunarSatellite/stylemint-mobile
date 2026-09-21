import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/data/datasources/reel_approvals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/data/repositories/reel_approvals_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/repositories/reel_approvals_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/presentation/notifiers/approval_rounds_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/presentation/notifiers/reel_approvals_notifier.dart';

final reelApprovalsRemoteDataSourceProvider =
    Provider<ReelApprovalsRemoteDataSource>(
      (ref) => ReelApprovalsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final reelApprovalsRepositoryProvider = Provider<ReelApprovalsRepository>(
  (ref) => ReelApprovalsRepositoryImpl(
    remoteDataSource: ref.watch(reelApprovalsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// The vendor's inbox. Auto-disposed so a vendor who leaves and comes back
/// re-reads it rather than acting on a list that may be minutes stale — the
/// expiry sweep can settle a round without anyone touching the screen.
final StateNotifierProvider<ReelApprovalsNotifier, ReelApprovalsState>
reelApprovalsNotifierProvider =
    StateNotifierProvider.autoDispose<
      ReelApprovalsNotifier,
      ReelApprovalsState
    >(
      (ref) =>
          ReelApprovalsNotifier(ref.watch(reelApprovalsRepositoryProvider)),
    );

/// One reel's approval history. Keyed by reel id and auto-disposed: a creator
/// who closes the sheet and opens another reel's must not see the first one's
/// rounds.
final StateNotifierProviderFamily<
  ApprovalRoundsNotifier,
  ApprovalRoundsState,
  String
>
approvalRoundsProvider = StateNotifierProvider.autoDispose
    .family<ApprovalRoundsNotifier, ApprovalRoundsState, String>(
      (ref, reelId) => ApprovalRoundsNotifier(
        ref.watch(reelApprovalsRepositoryProvider),
        reelId,
      ),
    );
