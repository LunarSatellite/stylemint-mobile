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
