import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';

/// Reads `GET v1/customer/feed/storefront-layout`.
///
/// Hand-written and deliberately tolerant. The server record is
/// `StorefrontLayout(RankedCategories, IsPersonalized)`; whether it reaches
/// the wire camelCased or PascalCased depends on the serializer, and a
/// personalised home page is not worth losing to that. A ranking entry with
/// no category id is dropped rather than silently reordering nothing.
StorefrontLayout storefrontLayoutFromJson(Map<String, dynamic> json) {
  final rawList = json['rankedCategories'] ?? json['RankedCategories'];
  final ranked = <StorefrontCategoryRank>[];
  if (rawList is List) {
    for (final raw in rawList) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final id = readString(item['categoryId'] ?? item['CategoryId']);
      if (id.isEmpty) continue;
      ranked.add(
        StorefrontCategoryRank(
          categoryId: id,
          label: readString(item['label'] ?? item['Label']),
          recentPurchaseCount: readInt(
            item['recentPurchaseCount'] ?? item['RecentPurchaseCount'],
          ),
        ),
      );
    }
  }
  final personalized = readBool(
    json['isPersonalized'] ?? json['IsPersonalized'],
  );
  if (!personalized || ranked.isEmpty) return StorefrontLayout.none;
  return StorefrontLayout(rankedCategories: ranked, isPersonalized: true);
}
