import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class FriendsRepository {
  Future<Either<NetworkExceptions, PagedResult<Friend>>> getFriends({
    String? search,
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, List<FriendRequest>>> getFriendRequests();

  Future<Either<NetworkExceptions, Unit>> sendFriendRequest(String userId);

  Future<Either<NetworkExceptions, Unit>> acceptRequest(String requestId);

  Future<Either<NetworkExceptions, Unit>> declineRequest(String requestId);

  Future<Either<NetworkExceptions, Unit>> unfriend(String userId);

  Future<Either<NetworkExceptions, List<Friend>>> importContacts(
    List<String> contacts,
  );
}
