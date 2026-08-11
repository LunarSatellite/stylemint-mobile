import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/datasources/reel_studio_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/repositories/reel_studio_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio_extras.dart';
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

// ── Studio insight providers ──────────────────────────────────────────────────
// Read-only AI-derived surfaces. Routed through the repository so an offline
// device surfaces "No internet connection." here like everywhere else; these
// signal failure by throwing so `AsyncValue.error` carries the message.

T _orThrow<T>(NetworkEither<T> result) => result.fold(
      (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
      (value) => value,
    );

// ignore: specify_nonobvious_property_types
final coachingTipsProvider =
    FutureProvider.autoDispose.family<List<CoachingTip>, String>(
  (ref, draftId) async => _orThrow(
    await ref.watch(reelStudioRepositoryProvider).getCoachingTips(draftId),
  ),
);

// ignore: specify_nonobvious_property_types
final collabSuggestionsProvider =
    FutureProvider.autoDispose<List<CollabSuggestion>>(
  (ref) async => _orThrow(
    await ref.watch(reelStudioRepositoryProvider).getCollabSuggestions(),
  ),
);

// ignore: specify_nonobvious_property_types
final dropPartyPromptProvider = FutureProvider.autoDispose<DropPartyPrompt>(
  (ref) async => _orThrow(
    await ref.watch(reelStudioRepositoryProvider).getDropPartyPrompt(),
  ),
);

// ignore: specify_nonobvious_property_types
final tagNudgesProvider = FutureProvider.autoDispose<List<TagNudge>>(
  (ref) async =>
      _orThrow(await ref.watch(reelStudioRepositoryProvider).getTagNudges()),
);
