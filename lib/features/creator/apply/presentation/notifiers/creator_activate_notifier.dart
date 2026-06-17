import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/auth/jwt_roles.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';

part 'creator_activate_notifier.freezed.dart';

@freezed
abstract class CreatorActivateState with _$CreatorActivateState {
  const factory CreatorActivateState.initial() = _CreatorActivateInitial;
  const factory CreatorActivateState.submitting() = _CreatorActivateSubmitting;
  const factory CreatorActivateState.success() = _CreatorActivateSuccess;
  const factory CreatorActivateState.failure(NetworkExceptions failure) =
      _CreatorActivateFailure;
}

/// Drives the single-step creator activation (`POST /v1/creator/activate`).
class CreatorActivateNotifier extends StateNotifier<CreatorActivateState> {
  CreatorActivateNotifier(this._repository, this._ref)
    : super(const CreatorActivateState.initial());

  final CreatorRepository _repository;
  final Ref _ref;

  Future<void> activate({String? bio, String? expression}) async {
    state = const CreatorActivateState.submitting();
    final either = await _repository.activate(bio: bio, expression: expression);
    await either.fold(
      (failure) async => state = CreatorActivateState.failure(failure),
      (_) async {
        await _reauth();
        state = const CreatorActivateState.success();
      },
    );
  }

  /// CRITICAL: JWT roles are baked at issue time, so the current token is still
  /// `["Customer"]` right after activation. Refresh to mint a token that
  /// carries `Creator`, then re-check the session + invalidate the cached roles
  /// so role-gated screens unlock. Best-effort — activation already succeeded
  /// server-side, so a refresh hiccup just defers the role to the next launch.
  Future<void> _reauth() async {
    try {
      final rt = await _ref.read(tokenStorageProvider).refreshToken;
      if (rt != null && rt.isNotEmpty) {
        await _ref.read(authRepositoryProvider).refresh(refreshToken: rt);
      }
      await _ref.read(sessionControllerProvider.notifier).recheck();
      _ref.invalidate(currentRolesProvider);
    } catch (_) {
      // swallow — see doc comment above
    }
  }
}
