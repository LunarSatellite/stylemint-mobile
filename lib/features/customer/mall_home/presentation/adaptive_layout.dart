import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';

/// Rearranges the Mall home page around what this customer actually buys.
///
/// What the contract can and cannot do: `storefront-layout` returns a ranked
/// list of *category ids*, nothing else. There are no server-sent sections,
/// tiles, copy or slots, so a truly server-driven layout is not on offer and
/// is not faked here. What it does support — and what this does — is
/// **order**:
///
/// * every category tile the page already carries is sorted by the ranking,
///   so the customer's own categories lead the mosaic;
/// * any section the page ties to a ranked category (its "see all" points at
///   that category) is promoted to the front, best-ranked first, while the
///   hero keeps the top of the page and the trust strip keeps the bottom;
/// * a promoted section gets an honest reason line if it had none.
///
/// Everything else keeps the server's merchandised order exactly. Sections
/// are moved, never dropped, rewritten or invented, so the personalised page
/// and the fixed page are made of the same blocks and the same data — which
/// is what makes falling back to [StorefrontLayout.none] invisible.
MallHome applyStorefrontLayout(MallHome home, StorefrontLayout layout) {
  if (!layout.hasRanking || home.sections.isEmpty) return home;

  final rankByCategory = <String, int>{};
  final labelByCategory = <String, String>{};
  for (var i = 0; i < layout.rankedCategories.length; i++) {
    final ranked = layout.rankedCategories[i];
    final key = _key(ranked.categoryId);
    if (key.isEmpty || rankByCategory.containsKey(key)) continue;
    rankByCategory[key] = i;
    labelByCategory[key] = ranked.label;
  }
  if (rankByCategory.isEmpty) return home;

  final reordered = <HomeSection>[];
  for (final section in home.sections) {
    reordered.add(
      section is HomeCategoriesSection
          ? _sortCategoryTiles(section, rankByCategory)
          : section,
    );
  }

  final promoted = _promote(reordered, rankByCategory, labelByCategory);
  return MallHome(
    sections: promoted,
    // The page is personalised if the server's own home said so, or if this
    // ranking changed the order.
    personalized: home.personalized || !identical(promoted, reordered),
    generatedUtc: home.generatedUtc,
    greetingFirstName: home.greetingFirstName,
  );
}

/// Ids are compared case-insensitively and without brace/dash noise: the same
/// catalog GUID reaches the app from two different services here.
String _key(String? id) {
  if (id == null) return '';
  return id.trim().toLowerCase().replaceAll(RegExp(r'[{}\-]'), '');
}

/// The category a section is "about", if the page says so. A section
/// qualifies only through its own "see all" destination — never by guessing
/// from its title.
String _categoryOf(HomeSection section) {
  final seeAll = section.seeAll;
  if (seeAll == null) return '';
  final params = seeAll.params;
  final direct = _key(params['categoryId'] ?? params['categoryid']);
  if (direct.isNotEmpty) return direct;
  if (seeAll.target == HomeSeeAllTarget.category) {
    return _key(params['id'] ?? params['category']);
  }
  return '';
}

/// Orders a category mosaic's own tiles by the ranking, keeping the server's
/// order among the unranked ones behind them.
HomeCategoriesSection _sortCategoryTiles(
  HomeCategoriesSection section,
  Map<String, int> rankByCategory,
) {
  final items = section.items;
  if (items.length < 2) return section;
  final ranked = <(int, int, HomeCategory)>[];
  var anyRanked = false;
  for (var i = 0; i < items.length; i++) {
    final rank = rankByCategory[_key(items[i].id)];
    if (rank != null) anyRanked = true;
    ranked.add((rank ?? _unranked, i, items[i]));
  }
  if (!anyRanked) return section;
  ranked.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.compareTo(b.$2);
  });
  return HomeCategoriesSection(
    id: section.id,
    items: [for (final entry in ranked) entry.$3],
    eyebrow: section.eyebrow,
    title: section.title,
    subtitle: section.subtitle,
    reason: section.reason,
    seeAll: section.seeAll,
  );
}

const int _unranked = 1 << 20;

/// Moves ranked sections to the front of the movable band — after a leading
/// hero, before a trailing trust strip. Returns [sections] itself when
/// nothing moves, which is how the caller knows the page is unchanged.
List<HomeSection> _promote(
  List<HomeSection> sections,
  Map<String, int> rankByCategory,
  Map<String, String> labelByCategory,
) {
  var start = 0;
  while (start < sections.length && sections[start] is HomeCampaignsSection) {
    start++;
  }
  var end = sections.length;
  while (end > start && sections[end - 1] is HomeTrustSection) {
    end--;
  }
  if (end - start < 2) return sections;

  final band = <(int, int, HomeSection)>[];
  var moved = false;
  for (var i = start; i < end; i++) {
    final section = sections[i];
    final rank = rankByCategory[_categoryOf(section)];
    if (rank == null) {
      band.add((_unranked, i, section));
      continue;
    }
    moved = true;
    band.add((rank, i, _withReason(section, labelByCategory)));
  }
  if (!moved) return sections;

  band.sort((a, b) {
    final byRank = a.$1.compareTo(b.$1);
    return byRank != 0 ? byRank : a.$2.compareTo(b.$2);
  });
  return [
    ...sections.take(start),
    for (final entry in band) entry.$3,
    ...sections.skip(end),
  ];
}

/// Says why a section moved, but only when the server left the reason line
/// empty and gave the category a real label — "Because you've been buying
/// Category" is worse than no line at all.
HomeSection _withReason(
  HomeSection section,
  Map<String, String> labelByCategory,
) {
  final existing = section.reason;
  if (existing != null && existing.trim().isNotEmpty) return section;
  final label = labelByCategory[_categoryOf(section)]?.trim() ?? '';
  if (label.isEmpty || label.toLowerCase() == 'category') return section;
  final reason = "Because you've been buying $label";
  return switch (section) {
    HomeProductsSection() => HomeProductsSection(
      id: section.id,
      items: section.items,
      eyebrow: section.eyebrow,
      title: section.title,
      subtitle: section.subtitle,
      reason: reason,
      seeAll: section.seeAll,
    ),
    HomeReelsSection() => HomeReelsSection(
      id: section.id,
      items: section.items,
      eyebrow: section.eyebrow,
      title: section.title,
      subtitle: section.subtitle,
      reason: reason,
      seeAll: section.seeAll,
    ),
    HomeCollectionsSection() => HomeCollectionsSection(
      id: section.id,
      items: section.items,
      eyebrow: section.eyebrow,
      title: section.title,
      subtitle: section.subtitle,
      reason: reason,
      seeAll: section.seeAll,
    ),
    // Everything else keeps whatever the server sent.
    _ => section,
  };
}
