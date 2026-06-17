import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/datasources/onboarding_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/domain/repositories/onboarding_repository.dart';
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
