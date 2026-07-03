import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';

abstract class CreatorReelsRepository {
  Future<NetworkEither<CreatorReelDetail>> getReelDetail(String reelId);

  Future<NetworkEither<List<CreatorReelSummary>>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  });
}
