import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

abstract interface class SocialConnectRepository {
  Future<Either<NetworkExceptions, List<SocialAccount>>> getConnectedAccounts();

  Future<Either<NetworkExceptions, SocialAccount>> connectPlatform(
    SocialPlatform platform,
    String authCode,
    String redirectUri,
  );

  Future<Either<NetworkExceptions, Unit>> disconnectPlatform(String accountId);
}
