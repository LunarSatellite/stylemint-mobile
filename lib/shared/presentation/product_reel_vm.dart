import 'package:stylemint_mobile_frontend/shared/domain/entities/product_reel_ref.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';

/// Maps the domain reel reference to the Mall kit's view model.
///
/// Lives outside the kit so the kit keeps knowing nothing about domain
/// entities, and outside any one feature so Mall home, the listing, the brand
/// storefront and the creator storefront all map it the same way.
extension ProductReelRefToVm on ProductReelRef {
  MallReelRef toVm() => MallReelRef(
    reelId: reelId,
    posterUrl: posterUrl,
    hook: hook,
    isAiGenerated: isAiGenerated,
    durationSeconds: durationSeconds,
  );
}
