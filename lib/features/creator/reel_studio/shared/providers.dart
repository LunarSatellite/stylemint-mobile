import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/datasources/reel_studio_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_extras_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/repositories/reel_studio_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/repositories/reel_studio_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/notifiers/reel_studio_notifier.dart';

final reelStudioRemoteDataSourceProvider =
    Provider<ReelStudioRemoteDataSource>(
      (ref) => ReelStudioRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final reelStudioRepositoryProvider = Provider<ReelStudioRepository>(
  (ref) => ReelStudioRepositoryImpl(
    remoteDataSource: ref.watch(reelStudioRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final reelStudioNotifierProvider =
    StateNotifierProvider<ReelStudioNotifier, ReelStudioState>(
      (ref) => ReelStudioNotifier(ref.watch(reelStudioRepositoryProvider)),
    );

final createDraftNotifierProvider =
    StateNotifierProvider<CreateDraftNotifier, CreateDraftState>(
      (ref) => CreateDraftNotifier(ref.watch(reelStudioRepositoryProvider)),
    );

// ── Studio insight providers (bypass repository — read-only AI data) ───────────

// ignore: specify_nonobvious_property_types
final coachingTipsProvider =
    FutureProvider.autoDispose.family<List<CoachingTipDto>, String>(
  (ref, draftId) =>
      ref.watch(reelStudioRemoteDataSourceProvider).getCoachingTips(draftId),
);

// ignore: specify_nonobvious_property_types
final collabSuggestionsProvider =
    FutureProvider.autoDispose<List<CollabSuggestionDto>>(
  (ref) =>
      ref.watch(reelStudioRemoteDataSourceProvider).getCollabSuggestions(),
);

// ignore: specify_nonobvious_property_types
final dropPartyPromptProvider =
    FutureProvider.autoDispose<DropPartyPromptDto>(
  (ref) =>
      ref.watch(reelStudioRemoteDataSourceProvider).getDropPartyPrompt(),
);

// ignore: specify_nonobvious_property_types
final tagNudgesProvider =
    FutureProvider.autoDispose<List<TagNudgeDto>>(
  (ref) => ref.watch(reelStudioRemoteDataSourceProvider).getTagNudges(),
);

// ignore: specify_nonobvious_property_types
final launchpadProvider = FutureProvider.autoDispose<LaunchpadDto>(
  (ref) => ref.watch(reelStudioRemoteDataSourceProvider).getLaunchpad(),
);
