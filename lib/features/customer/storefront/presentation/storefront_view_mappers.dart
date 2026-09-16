import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

extension StorefrontReelToVm on StorefrontReel {
  /// [fallbackCreatorName] stands in when the reel carries no creator name.
  MallReelVm toVm({required String fallbackCreatorName}) => MallReelVm(
    id: id,
    creatorName: (creatorName?.trim().isNotEmpty ?? false)
        ? creatorName!.trim()
        : fallbackCreatorName,
    posterUrl: posterUrl,
    creatorAvatarUrl: creatorAvatarUrl,
    caption: hook,
    taggedProductCount: taggedProductCount,
    isAiGenerated: isAiGenerated,
    likeCount: likeCount,
  );
}

/// What a storefront reel rail hands `openMallReelWindow`: the id the window
/// resolves playback by, plus the poster, hook and AI-generated flag its
/// chrome shows. Same shape a product tile's reel already carries.
extension StorefrontReelToRef on StorefrontReel {
  MallReelRef toRef() => MallReelRef(
    reelId: id,
    posterUrl: posterUrl,
    hook: hook,
    isAiGenerated: isAiGenerated,
  );
}
