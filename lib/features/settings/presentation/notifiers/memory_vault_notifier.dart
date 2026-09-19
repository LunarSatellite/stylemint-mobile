import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';

sealed class MemoryVaultState {
  const MemoryVaultState();
}

final class MemoryVaultLoading extends MemoryVaultState {
  const MemoryVaultLoading();
}

final class MemoryVaultLoaded extends MemoryVaultState {
  const MemoryVaultLoaded(this.vault, {this.busy = false, this.message});

  final MemoryVault vault;

  /// A change is being saved; controls are disabled meanwhile.
  final bool busy;

  /// A one-off message for the customer, e.g. why a change failed.
  final String? message;
}

final class MemoryVaultFailed extends MemoryVaultState {
  const MemoryVaultFailed(this.message);

  final String message;
}

/// Memory Vault: loads what the companion remembers and applies the
/// customer's pause, correct, forget and download requests.
class MemoryVaultNotifier extends StateNotifier<MemoryVaultState> {
  MemoryVaultNotifier(this._repository) : super(const MemoryVaultLoading()) {
    unawaited(load());
  }

  final MemoryVaultRepository _repository;

  MemoryVault? get _vault => switch (state) {
    MemoryVaultLoaded(:final vault) => vault,
    _ => null,
  };

  Future<void> load() async {
    state = const MemoryVaultLoading();
    final result = await _repository.load();
    if (!mounted) return;
    state = result.fold(
      (failure) => MemoryVaultFailed(NetworkExceptions.getMessage(failure)),
      MemoryVaultLoaded.new,
    );
  }

  Future<void> setPaused({required bool paused}) async {
    final vault = _vault;
    if (vault == null) return;
    state = MemoryVaultLoaded(vault.copyWith(paused: paused), busy: true);
    final result = await _repository.setPaused(paused: paused);
    if (!mounted) return;
    state = result.fold(
      (_) => MemoryVaultLoaded(
        vault,
        message: "Couldn't update your memory setting. Please try again.",
      ),
      (_) => MemoryVaultLoaded(vault.copyWith(paused: paused)),
    );
    // While paused the backend reports `consent.paused` for every purpose,
    // so it can tell us nothing about the underlying answers. Resuming is
    // the moment to go and read the real ones back.
    if (!paused && result.isRight()) await refreshConsents();
  }

  /// Re-reads the per-purpose decisions without blanking the screen. A
  /// failure leaves the decisions already on screen alone: replacing them
  /// with "undecided" would claim nobody had ever answered.
  Future<void> refreshConsents() async {
    final vault = _vault;
    if (vault == null) return;
    final result = await _repository.loadConsents();
    if (!mounted) return;
    final fresh = result.toNullable();
    if (fresh == null) return;
    final current = _vault;
    if (current == null) return;
    state = MemoryVaultLoaded(current.copyWith(consents: fresh));
  }

  /// The customer agrees to one purpose, against [explanation] — the exact
  /// text the screen showed them. It is passed straight through so the
  /// record the backend stores is the words they actually read.
  Future<void> grantPurpose(
    MemoryPurpose purpose,
    String explanation,
  ) async {
    await _decide(
      purposeCode: purpose.wireValue,
      optimistic: MemoryConsent.grantedFor(purpose),
      save: () => _repository.grantConsent(
        purpose: purpose,
        explanation: explanation,
      ),
      failure: "Couldn't save your answer. It is unchanged.",
    );
  }

  /// The customer withdraws, or refuses, one purpose. One step, and the
  /// backend records a refusal even where nothing was ever granted.
  Future<void> revokePurpose(int purposeCode) async {
    await _decide(
      purposeCode: purposeCode,
      optimistic: MemoryConsent.refusedFor(purposeCode),
      save: () => _repository.revokeConsent(purposeCode),
      failure: "Couldn't withdraw that. It is unchanged.",
    );
  }

  /// Shows [optimistic] at once, then puts the previous decision back if the
  /// save fails — the screen must never sit on a choice the server refused.
  Future<void> _decide({
    required int purposeCode,
    required MemoryConsent optimistic,
    required Future<Either<NetworkExceptions, Unit>> Function() save,
    required String failure,
  }) async {
    final before = _vault;
    if (before == null) return;
    state = MemoryVaultLoaded(
      before.copyWith(consents: before.withConsent(purposeCode, optimistic)),
      busy: true,
    );
    final result = await save();
    if (!mounted) return;
    state = result.fold(
      (_) => MemoryVaultLoaded(before, message: failure),
      (_) => MemoryVaultLoaded(
        before.copyWith(consents: before.withConsent(purposeCode, optimistic)),
      ),
    );
  }

  Future<void> correct(String memoryId, String content) async {
    final vault = _vault;
    if (vault == null || content.trim().isEmpty) return;
    state = MemoryVaultLoaded(vault, busy: true);
    final result = await _repository.correct(memoryId, content.trim());
    if (!mounted) return;
    state = result.fold(
      (_) => MemoryVaultLoaded(
        vault,
        message: "Couldn't save your correction. Please try again.",
      ),
      (updated) => MemoryVaultLoaded(
        vault.copyWith(
          memories: [
            for (final memory in vault.memories)
              memory.id == memoryId ? updated : memory,
          ],
        ),
        message: 'Memory updated.',
      ),
    );
  }

  Future<void> forget(String memoryId) async {
    final vault = _vault;
    if (vault == null) return;
    state = MemoryVaultLoaded(vault, busy: true);
    final result = await _repository.forget(memoryId);
    if (!mounted) return;
    state = result.fold(
      (_) => MemoryVaultLoaded(
        vault,
        message: "Couldn't forget that memory. Please try again.",
      ),
      (_) => MemoryVaultLoaded(
        vault.copyWith(
          memories: [
            for (final memory in vault.memories)
              if (memory.id != memoryId) memory,
          ],
        ),
        message: 'Forgotten.',
      ),
    );
  }

  Future<void> forgetAll() async {
    final vault = _vault;
    if (vault == null) return;
    state = MemoryVaultLoaded(vault, busy: true);
    final result = await _repository.forgetAll();
    if (!mounted) return;
    state = result.fold(
      (_) => MemoryVaultLoaded(
        vault,
        message: "Couldn't forget your memories. Please try again.",
      ),
      (_) => MemoryVaultLoaded(
        vault.copyWith(memories: const []),
        message: 'Everything has been forgotten.',
      ),
    );
  }

  /// The export document to share, or null if it could not be fetched.
  Future<String?> export() async {
    final result = await _repository.export();
    if (!mounted) return null;
    return result.fold((_) {
      final vault = _vault;
      if (vault != null) {
        state = MemoryVaultLoaded(
          vault,
          message: "Couldn't prepare your download. Please try again.",
        );
      }
      return null;
    }, (json) => json);
  }

  Future<bool> importPortableTwin(String bundleJson) async {
    final vault = _vault;
    if (vault == null) return false;
    state = MemoryVaultLoaded(vault, busy: true);
    final result = await _repository.importPortableTwin(bundleJson);
    if (!mounted) return false;
    return result.fold(
      (_) {
        state = MemoryVaultLoaded(
          vault,
          message:
              "Couldn't restore that private twin. Check the file and try again.",
        );
        return false;
      },
      (imported) {
        state = MemoryVaultLoaded(
          vault,
          message: imported == 0
              ? 'Backup checked. Everything was already in your vault.'
              : 'Restored $imported memories into your private twin.',
        );
        unawaited(load());
        return true;
      },
    );
  }

  void clearMessage() {
    final vault = _vault;
    if (vault != null && state is MemoryVaultLoaded) {
      final busy = (state as MemoryVaultLoaded).busy;
      state = MemoryVaultLoaded(vault, busy: busy);
    }
  }
}
