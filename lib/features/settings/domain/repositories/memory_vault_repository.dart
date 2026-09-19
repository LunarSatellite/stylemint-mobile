import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';

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

  /// Everything remembered, as the JSON document the backend exports.
  Future<Either<NetworkExceptions, String>> export();

  Future<Either<NetworkExceptions, int>> importPortableTwin(String bundleJson);
}
