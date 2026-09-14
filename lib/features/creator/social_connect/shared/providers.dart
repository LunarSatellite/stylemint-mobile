import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/datasources/social_connect_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/repositories/social_connect_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/audience_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/repositories/social_connect_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';

final socialConnectRemoteDataSourceProvider =
    Provider<SocialConnectRemoteDataSource>(
      (ref) => SocialConnectRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final socialConnectRepositoryProvider = Provider<SocialConnectRepository>(
  (ref) => SocialConnectRepositoryImpl(
    remoteDataSource: ref.watch(socialConnectRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final socialConnectNotifierProvider =
    StateNotifierProvider<SocialConnectNotifier, SocialConnectState>(
      (ref) => SocialConnectNotifier(
        ref.watch(socialConnectRepositoryProvider),
      ),
    );

/// Followers and engagement rate imported from the connected platforms.
/// Re-fetched whenever the connected-accounts list changes (connect,
/// disconnect, pull to refresh). Null when nothing is connected or the
/// summary couldn't be loaded; the screen then simply omits the card.
final audienceSummaryProvider = FutureProvider.autoDispose<AudienceSummary?>((
  ref,
) async {
  final accounts = ref
      .watch(socialConnectNotifierProvider)
      .maybeWhen(loadSuccess: (a) => a, orElse: () => null);
  if (accounts == null || !accounts.any((a) => a.isConnected)) return null;

  final either = await ref
      .watch(socialConnectRepositoryProvider)
      .getAudienceSummary();
  return either.fold((_) => null, (summary) => summary);
});
