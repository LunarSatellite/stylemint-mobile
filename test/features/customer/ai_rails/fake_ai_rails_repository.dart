import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/repositories/ai_rails_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

/// AI rails with canned answers; by default a server without any of them
/// (every rail not deployed), which is what screens that predate the rails
/// should see in their own tests.
class FakeAiRailsRepository implements AiRailsRepository {
  FakeAiRailsRepository({
    this.alsoWatchedReels,
    this.similar,
    this.forProduct,
  });

  final List<Reel>? alsoWatchedReels;
  final ReelMatches? similar;
  final ReelMatches? forProduct;
  final List<String> calls = [];

  @override
  Future<ReelRail> alsoWatched(String reelId, {int limit = 10}) async {
    calls.add('alsoWatched:$reelId');
    final reels = alsoWatchedReels;
    return reels == null
        ? const AiRail.empty(AiRailStatus.notDeployed)
        : AiRail(items: reels, status: AiRailStatus.ok);
  }

  @override
  Future<ProductRail> boughtTogether(String productId, {int limit = 10}) async =>
      const AiRail.empty(AiRailStatus.notDeployed);

  @override
  Future<ProductRail> alsoViewed(String productId, {int limit = 10}) async =>
      const AiRail.empty(AiRailStatus.notDeployed);

  @override
  Future<ReelMatches> reelsForProduct(String productId, {int limit = 10}) async =>
      forProduct ?? const ReelMatches.notDeployed();

  @override
  Future<ReelMatches> similarReels(String reelId, {int limit = 10}) async {
    calls.add('similar:$reelId');
    return similar ?? const ReelMatches.notDeployed();
  }
}
