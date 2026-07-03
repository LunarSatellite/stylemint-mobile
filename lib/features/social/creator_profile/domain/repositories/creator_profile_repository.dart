import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';

abstract class CreatorProfileRepository {
  Future<NetworkEither<CreatorProfile>> getCreatorProfile(String accountId);

  Future<NetworkEither<CreatorProfile>> updateCreatorProfile({
    required String accountId,
    required String rowVersion,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? tags,
    List<String>? niches,
  });
}
