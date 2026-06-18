import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/usecase/usecase.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/models/creator_dto.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/usecases/fetch_creators.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/usecases/follow_creators_usecase.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/usecases/save_interests.dart';

// ── Dependency providers ──────────────────────────────────────────────────────

final _onboardingApiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiClient(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:5020',
    ),
    dio: dio,
  );
});

final _onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final client = ref.watch(_onboardingApiClientProvider);
  return OnboardingRepositoryImpl(OnboardingRemoteDatasource(apiClient: client));
});

final saveInterestsUsecaseProvider = Provider<SaveInterests>((ref) {
  return SaveInterests(ref.watch(_onboardingRepositoryProvider));
});

final fetchCreatorsUsecaseProvider = Provider<FetchCreators>((ref) {
  return FetchCreators(ref.watch(_onboardingRepositoryProvider));
});

final followCreatorsUsecaseProvider = Provider<FollowCreatorsUsecase>((ref) {
  return FollowCreatorsUsecase(ref.watch(_onboardingRepositoryProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class SaveInterestsState {
  const SaveInterestsState({
    this.isLoading = false,
    this.error,
    this.saved = false,
  });

  final bool isLoading;
  final Failure? error;
  final bool saved;

  SaveInterestsState copyWith({
    bool? isLoading,
    Failure? error,
    bool? saved,
  }) =>
      SaveInterestsState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        saved: saved ?? this.saved,
      );

  bool get hasError => error != null;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SaveInterestsNotifier extends StateNotifier<SaveInterestsState> {
  SaveInterestsNotifier({required this.saveInterestsUsecase})
      : super(const SaveInterestsState());

  final SaveInterests saveInterestsUsecase;

  Future<void> save(List<String> categoryIds) async {
    state = state.copyWith(isLoading: true, error: null, saved: false);

    final result = await saveInterestsUsecase(
      SaveInterestsParams(categoryIds: categoryIds),
    );

    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure),
      (_) => state.copyWith(isLoading: false, saved: true),
    );
  }

  void reset() => state = const SaveInterestsState();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final saveInterestsProvider =
    StateNotifierProvider<SaveInterestsNotifier, SaveInterestsState>((ref) {
  return SaveInterestsNotifier(
    saveInterestsUsecase: ref.watch(saveInterestsUsecaseProvider),
  );
});

// ── Fetch Creators ────────────────────────────────────────────────────────────

class FetchCreatorsState {
  const FetchCreatorsState({
    this.isLoading = false,
    this.creators = const [],
    this.error,
  });

  final bool isLoading;
  final List<CreatorDto> creators;
  final Failure? error;

  bool get hasError => error != null;

  FetchCreatorsState copyWith({
    bool? isLoading,
    List<CreatorDto>? creators,
    Failure? error,
  }) =>
      FetchCreatorsState(
        isLoading: isLoading ?? this.isLoading,
        creators: creators ?? this.creators,
        error: error,
      );
}

class FetchCreatorsNotifier extends StateNotifier<FetchCreatorsState> {
  FetchCreatorsNotifier({required this.fetchCreatorsUsecase})
      : super(const FetchCreatorsState());

  final FetchCreators fetchCreatorsUsecase;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true);
    final result = await fetchCreatorsUsecase(const NoParams());
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure),
      (creators) => state.copyWith(isLoading: false, creators: creators),
    );
  }
}

final fetchCreatorsProvider =
    StateNotifierProvider<FetchCreatorsNotifier, FetchCreatorsState>((ref) {
  return FetchCreatorsNotifier(
    fetchCreatorsUsecase: ref.watch(fetchCreatorsUsecaseProvider),
  );
});

// ── Follow Creators ───────────────────────────────────────────────────────────

class FollowCreatorsState {
  const FollowCreatorsState({
    this.isLoading = false,
    this.error,
    this.saved = false,
  });

  final bool isLoading;
  final Failure? error;
  final bool saved;

  bool get hasError => error != null;

  FollowCreatorsState copyWith({
    bool? isLoading,
    Failure? error,
    bool? saved,
  }) =>
      FollowCreatorsState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        saved: saved ?? this.saved,
      );
}

class FollowCreatorsNotifier extends StateNotifier<FollowCreatorsState> {
  FollowCreatorsNotifier({required this.followCreatorsUsecase})
      : super(const FollowCreatorsState());

  final FollowCreatorsUsecase followCreatorsUsecase;

  Future<void> follow(List<String> creatorIds) async {
    state = state.copyWith(isLoading: true, saved: false);
    final result = await followCreatorsUsecase(
      FollowCreatorsParams(creatorIds: creatorIds),
    );
    state = result.fold(
      (failure) => state.copyWith(isLoading: false, error: failure),
      (_) => state.copyWith(isLoading: false, saved: true),
    );
  }

  void reset() => state = const FollowCreatorsState();
}

final followCreatorsProvider =
    StateNotifierProvider<FollowCreatorsNotifier, FollowCreatorsState>((ref) {
  return FollowCreatorsNotifier(
    followCreatorsUsecase: ref.watch(followCreatorsUsecaseProvider),
  );
});
