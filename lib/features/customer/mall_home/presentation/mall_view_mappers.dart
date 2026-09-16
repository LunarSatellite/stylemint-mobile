import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

/// Nepal keeps UTC+5:45 all year (no daylight saving).
const Duration nepalUtcOffset = Duration(hours: 5, minutes: 45);

/// "Good morning" / "Good afternoon" / "Good evening" for [now] in
/// Asia/Kathmandu.
String mallSalutation(DateTime now) {
  final hour = now.toUtc().add(nepalUtcOffset).hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Eyebrow shown on a collection of [kind].
String collectionEyebrow(CollectionKind kind) => switch (kind) {
  CollectionKind.editorial => 'Editorial',
  CollectionKind.creatorCollection => 'Creator edit',
  CollectionKind.brandCollection => 'Brand edit',
  CollectionKind.look => 'The look',
};

extension HomeProductToVm on HomeProduct {
  MallProductVm toVm() => MallProductVm(
    id: id,
    name: name,
    price: price,
    brandName: brandName,
    imageUrl: imageUrl,
    compareAtPrice: compareAtPrice,
    rating: rating,
    isNew: isNew,
    isLowStock: isLowStock,
    reviewCount: reviewCount,
    saleEndsUtc: saleEndsUtc,
  );
}

extension CatalogProductToVm on CatalogProduct {
  MallProductVm toVm() => MallProductVm(
    id: id,
    name: name,
    price: price,
    brandName: vendorDisplayName,
    imageUrl: imageUrl,
    compareAtPrice: compareAtPrice,
    rating: rating,
    isLowStock: isLowStock,
  );
}

extension HomeReelToVm on HomeReel {
  MallReelVm toVm() => MallReelVm(
    id: id,
    creatorName: creatorName.isEmpty ? 'StyleMint creator' : creatorName,
    posterUrl: posterUrl,
    creatorAvatarUrl: creatorAvatarUrl,
    caption: hook,
    taggedProductCount: taggedProductCount,
    isAiGenerated: isAiGenerated,
    likeCount: likeCount,
  );
}

extension HomeCreatorToVm on HomeCreator {
  MallCreatorVm toVm() => MallCreatorVm(
    id: accountId,
    name: displayName,
    handle: handle,
    avatarUrl: avatarUrl,
    coverUrl: coverImageUrl,
    isVerified: isVerified,
    styleTags: styleTags,
    followerCount: followerCount,
  );
}

extension HomeBrandToVm on HomeBrand {
  MallBrandVm toVm() => MallBrandVm(
    id: vendorAccountId,
    name: name,
    logoUrl: logoUrl,
    coverUrl: coverImageUrl,
    isVerified: isVerified,
    tagline: tagline,
  );
}

extension HomeCategoryToVm on HomeCategory {
  MallCategoryVm toVm() => MallCategoryVm(
    id: id.isEmpty ? slug : id,
    label: name,
    imageUrl: imageUrl,
  );
}

extension HomeCollectionToVm on HomeCollection {
  MallCollectionVm toVm() => MallCollectionVm(
    id: slug,
    title: title,
    eyebrow: collectionEyebrow(kind),
    coverUrl: coverImageUrl,
    itemCount: itemCount,
    previewImageUrls: previewImageUrls,
  );
}

extension HomeCampaignToVm on HomeCampaign {
  /// Action ids are the CTA's index in [ctas].
  MallCampaignVm toVm() => MallCampaignVm(
    id: id,
    title: title,
    eyebrow: eyebrow,
    subtitle: subtitle,
    imageUrl: heroImageUrl,
    actions: [
      for (final (index, cta) in ctas.indexed)
        MallCampaignAction(id: '$index', label: cta.label),
    ],
  );
}
