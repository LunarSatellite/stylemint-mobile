import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/entities/group.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class GroupsRepository {
  Future<Either<NetworkExceptions, List<StyleGroup>>> getGroups({
    String? privacy,
    String? search,
    bool professionalOnly = false,
  });

  Future<Either<NetworkExceptions, StyleGroup>> getGroupDetail(String groupId);

  Future<Either<NetworkExceptions, Unit>> joinGroup(
    String groupId, {
    bool requestApproval = false,
  });

  Future<Either<NetworkExceptions, Unit>> leaveGroup(String groupId);

  Future<Either<NetworkExceptions, PagedResult<GroupPost>>> getGroupFeed(
    String groupId, {
    int limit = 20,
    String? cursor,
  });

  Future<Either<NetworkExceptions, GroupPost>> createGroupPost({
    required String groupId,
    required String content,
    List<String>? images,
  });
}
