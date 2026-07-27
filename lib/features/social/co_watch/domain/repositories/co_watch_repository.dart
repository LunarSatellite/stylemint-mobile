import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/entities/co_watch.dart';

abstract interface class CoWatchRepository {
  Future<Either<NetworkExceptions, List<CoWatchSession>>> getActiveSessions();

  Future<Either<NetworkExceptions, CoWatchSession>> getSession(
    String sessionId,
  );

  Future<Either<NetworkExceptions, CoWatchSession>> createSession(
    String reelId,
  );

  Future<Either<NetworkExceptions, CoWatchSession>> joinSession(String sessionId);

  Future<Either<NetworkExceptions, Unit>> leaveSession(String sessionId);

  Future<Either<NetworkExceptions, CoWatchReaction>> sendReaction(
    String sessionId,
    String reaction,
  );

  Future<Either<NetworkExceptions, List<CoWatchReaction>>> getReactions(
    String sessionId,
  );
}