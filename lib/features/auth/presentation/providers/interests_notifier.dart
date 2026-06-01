import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/interest_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'interests_notifier.freezed.dart';

@freezed
abstract class InterestsState with _$InterestsState {
  const InterestsState._();

  const factory InterestsState.initial() = _InterestsInitial;
  const factory InterestsState.loadInProgress() = _InterestsInProgress;
  const factory InterestsState.loadSuccess({
    required List<InterestDto> available,
    required Set<String> selectedIds,
  }) = _InterestsSuccess;
  const factory InterestsState.loadFailure(NetworkExceptions failure) = _InterestsNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class InterestsNotifier extends StateNotifier<InterestsState> {
  InterestsNotifier({required this.authRepository})
      : super(const InterestsState.initial());

  final AuthRepository authRepository;

  Future<void> load({required String accountId}) async {
    state = const InterestsState.loadInProgress();
    final results = await Future.wait([
      authRepository.listPublicInterests(),
      authRepository.listInterests(accountId),
    ]);

    final availableResult = results[0] as Either<NetworkExceptions, List<InterestDto>>;
    final selectedResult = results[1] as Either<NetworkExceptions, List<InterestDto>>;

    state = availableResult.fold(
      InterestsState.loadFailure,
      (available) => selectedResult.fold(
        InterestsState.loadFailure,
        (selected) => InterestsState.loadSuccess(
          available: available,
          selectedIds: selected.map((i) => i.categoryId).toSet(),
        ),
      ),
    );
  }

  Future<void> toggleInterest({
    required String accountId,
    required String categoryId,
    required bool isSelected,
  }) async {
    state.maybeWhen(
      loadSuccess: (available, selectedIds) {
        if (isSelected) {
          state = InterestsState.loadSuccess(
            available: available,
            selectedIds: selectedIds.difference({categoryId}),
          );
        } else {
          state = InterestsState.loadSuccess(
            available: available,
            selectedIds: selectedIds.union({categoryId}),
          );
        }
      },
      orElse: () {},
    );

    if (isSelected) {
      await authRepository.removeInterest(
        accountId: accountId,
        categoryId: categoryId,
      );
    } else {
      await authRepository.addInterest(
        accountId: accountId,
        categoryId: categoryId,
      );
    }
  }

  void reset() => state = const InterestsState.initial();
}

final interestsProvider =
    StateNotifierProvider<InterestsNotifier, InterestsState>(
  (ref) => InterestsNotifier(authRepository: ref.watch(authRepositoryProvider)),
);
