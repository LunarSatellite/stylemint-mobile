import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/post_publish_report.dart';

abstract class CreatorReelsRepository {
  Future<NetworkEither<CreatorReelDetail>> getReelDetail(String reelId);

  Future<NetworkEither<List<CreatorReelSummary>>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  });

  Future<NetworkEither<PostPublishReport>> getPostPublishReport(String reelId);

  Future<NetworkEither<void>> deleteReel(String reelId);
}
