import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

abstract interface class SocialConnectRepository {
  Future<Either<NetworkExceptions, List<SocialAccount>>> getConnectedAccounts();

  /// Starts the OAuth dance: asks the backend for the provider authorize URL +
  /// state to open in a browser. The backend handles the provider callback
  /// server-side; the app refreshes [getConnectedAccounts] on return.
  Future<Either<NetworkExceptions, SocialAuthorization>> beginConnect(
    SocialPlatform platform,
  );

  Future<Either<NetworkExceptions, Unit>> disconnectPlatform(
    SocialPlatform platform,
  );
}
