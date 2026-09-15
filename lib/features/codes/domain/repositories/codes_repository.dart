import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/resolved_code.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';

abstract interface class CodesRepository {
  /// Resolves [code] and records one scan opened [via]. Works signed out.
  /// An unknown or revoked code is `NetworkExceptions.notFound()`.
  Future<Either<NetworkExceptions, ResolvedCode>> resolve(
    String code,
    CodeScanVia via,
  );

  /// The signed-in account's active Profile code, made on first use.
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> getMyProfileCode();

  /// Switches the current Profile code off and issues a new one.
  Future<Either<NetworkExceptions, StyleMintCodeInfo>> rotateMyProfileCode();
}
