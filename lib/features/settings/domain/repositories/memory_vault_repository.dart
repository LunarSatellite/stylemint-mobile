import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';

/// The customer's controls over what the StyleMint companion remembers.
abstract interface class MemoryVaultRepository {
  Future<Either<NetworkExceptions, MemoryVault>> load();

  /// Whether the customer has paused being remembered. Read by anything that
  /// personalises what they see, so one switch governs all of it.
  Future<Either<NetworkExceptions, bool>> isPaused();

  Future<Either<NetworkExceptions, CompanionMemory>> correct(
    String memoryId,
    String content,
  );

  Future<Either<NetworkExceptions, Unit>> forget(String memoryId);

  Future<Either<NetworkExceptions, Unit>> forgetAll();

  Future<Either<NetworkExceptions, Unit>> setPaused({required bool paused});

  /// The current decision for every vault purpose.
  Future<Either<NetworkExceptions, List<MemoryConsent>>> loadConsents();

  /// Agrees to one purpose against the exact [explanation] displayed. The
  /// backend records that text as what the customer was shown, so it is
  /// passed through unchanged rather than rebuilt here.
  Future<Either<NetworkExceptions, Unit>> grantConsent({
    required MemoryPurpose purpose,
    required String explanation,
  });

  /// Withdraws one purpose, by wire code so an unknown one is still
  /// refusable.
  Future<Either<NetworkExceptions, Unit>> revokeConsent(int purposeCode);

  /// Everything remembered, as the JSON document the backend exports.
  Future<Either<NetworkExceptions, String>> export();

  Future<Either<NetworkExceptions, int>> importPortableTwin(String bundleJson);
}
