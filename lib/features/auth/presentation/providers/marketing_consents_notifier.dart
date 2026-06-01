import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/marketing_consent_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'marketing_consents_notifier.freezed.dart';

@freezed
abstract class MarketingConsentsState with _$MarketingConsentsState {
  const MarketingConsentsState._();

  const factory MarketingConsentsState.initial() = _MarketingConsentsInitial;
  const factory MarketingConsentsState.loadInProgress() =
      _MarketingConsentsInProgress;
  const factory MarketingConsentsState.loadSuccess(
    List<MarketingConsentDto> consents,
  ) = _MarketingConsentsSuccess;
  const factory MarketingConsentsState.loadFailure(NetworkExceptions failure) =
      _MarketingConsentsNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class MarketingConsentsNotifier extends StateNotifier<MarketingConsentsState> {
  MarketingConsentsNotifier({required this.authRepository})
      : super(const MarketingConsentsState.initial());

  final AuthRepository authRepository;

  Future<void> load(String accountId) async {
    state = const MarketingConsentsState.loadInProgress();
    final result = await authRepository.getCurrentMarketingConsents(accountId);
    state = result.fold(
      MarketingConsentsState.loadFailure,
      MarketingConsentsState.loadSuccess,
    );
  }

  Future<void> toggle({
    required String accountId,
    required String category,
    required bool consented,
  }) async {
    await authRepository.toggleMarketingConsent(
      accountId: accountId,
      category: category,
      consented: consented,
    );
    await load(accountId);
  }

  void reset() => state = const MarketingConsentsState.initial();
}

final marketingConsentsProvider =
    StateNotifierProvider<MarketingConsentsNotifier, MarketingConsentsState>(
  (ref) => MarketingConsentsNotifier(
    authRepository: ref.watch(authRepositoryProvider),
  ),
);
