import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/domain/entities/creator_activity_entry.dart';

abstract interface class CreatorActivityRepository {
  Future<Either<NetworkExceptions, List<CreatorActivityEntry>>> getActivity({
    int pageSize,
    String? cursor,
  });
}
