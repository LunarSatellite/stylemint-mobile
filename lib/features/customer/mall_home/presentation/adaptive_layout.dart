import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';

/// Rearranges the Mall home page around what this customer actually buys.
///
/// What the contract offers, and what this does with it. `storefront-layout`
/// returns a ranked list of *category ids* **and** an ordered set of modules,
/// each naming its destination in the home page's own see-all vocabulary.
/// There is still no server-sent copy, imagery or product data, so nothing of
/// the sort is faked here. What the server decides is **which slots, in what
/// order, about what, on what evidence**; what this does with it is:
///
/// * every category tile the page already carries is sorted by the ranking,
///   so the customer's own categories lead the mosaic;
/// * any section the page ties to a ranked category (its "see all" points at
///   that category) is promoted to the front, best-ranked first, while the
///   hero keeps the top of the page and the trust strip keeps the bottom;
/// * a promoted section gets an honest reason line if it had none;
/// * every module is matched to a section the page already renders — by its
///   target first, by the categories it is about second — and the matches
///   lead the page in the server's rank order;
/// * a module with no section here and a real destination (an open mission)
///   becomes a typographic prompt stating its recorded count;
/// * a module this build cannot render — an unknown kind, a target with
///   nowhere to go — is dropped without a trace.
///
/// Everything else keeps the server's merchandised order exactly. Sections
/// are moved, never dropped, rewritten or invented, so the personalised page
/// and the fixed page are made of the same blocks and the same data — which
/// is what makes falling back to [StorefrontLayout.none] invisible.
MallHome applyStorefrontLayout(MallHome home, StorefrontLayout layout) {
  if (layout.isEmpty || home.sections.isEmpty) return home;

  // Ranking first, modules second: the module pass moves what it matched to
  // the very front and leaves the relative order of everything else alone,
  // so the page reads modules, then ranked categories, then the server's own
  // merchandising.
  final ranked = layout.hasRanking ? _applyRanking(home, layout) : home;
  return layout.hasModules ? _applyModules(ranked, layout) : ranked;
}

/// The module pass: organise the page around the slots the server asked for.
///
/// A module is matched to a section the page already renders — first by
/// speaking the section's own "see all" vocabulary, then by the categories
/// the module is about. What matches is promoted, in the server's rank
/// order. What does not match is either drawn as a typographic prompt (the
/// kinds that have no section on this page) or **skipped in silence**: an
/// unknown kind, and a target with no destination in this build, leave the
/// page exactly as it was. Nothing is ever drawn empty or half-built.
MallHome _applyModules(MallHome home, StorefrontLayout layout) {
  final sections = home.sections;
  final (start, end) = _movableBand(sections);
  if (end <= start) return home;

  final claimed = <int>{};
  final lead = <HomeSection>[];

  for (final module in layout.modules) {
    if (module.kind == StorefrontModuleKind.unknown) continue;

    final index = _matchSection(sections, start, end, module, claimed);
    if (index != null) {
      claimed.add(index);
      lead.add(_withModuleReason(sections[index], module));
      continue;
    }

    final prompt = _promptFor(module);
    if (prompt != null) lead.add(prompt);
  }

  if (lead.isEmpty) return home;

  return MallHome(
    sections: [
      ...sections.take(start),
      ...lead,
      for (var i = start; i < end; i++)
        if (!claimed.contains(i)) sections[i],
      ...sections.skip(end),
    ],
    personalized: true,
    generatedUtc: home.generatedUtc,
    greetingFirstName: home.greetingFirstName,
  );
}

/// The band a section may be moved within: after a leading hero, before a
/// trailing trust strip. Both keep their place on every page.
(int, int) _movableBand(List<HomeSection> sections) {
  var start = 0;
  while (start < sections.length && sections[start] is HomeCampaignsSection) {
    start++;
  }
  var end = sections.length;
  while (end > start && sections[end - 1] is HomeTrustSection) {
    end--;
  }
  return (start, end);
}

/// The section this module is about, or null when the page has none.
int? _matchSection(
  List<HomeSection> sections,
  int start,
  int end,
  StorefrontModule module,
  Set<int> claimed,
) {
  final target = module.target;
  if (target != null && target.target != HomeSeeAllTarget.unknown) {
    for (var i = start; i < end; i++) {
      if (claimed.contains(i)) continue;
      if (_matchesTarget(target, sections[i])) return i;
    }
  }
  // The older, narrower key: a section whose see-all carries one of the
  // categories this module is about. Both are real and both still work.
  for (final id in module.categoryIds) {
    final key = _key(id);
    if (key.isEmpty) continue;
    for (var i = start; i < end; i++) {
      if (claimed.contains(i)) continue;
      if (_categoryOf(sections[i]) == key) return i;
    }
  }
  return null;
}

/// Whether [section] is the one [target] points at.
///
/// The target vocabulary is the primary key: a module that says `reels` is
/// about the page's reels rail. Params only refine it, so a mismatch needs
/// both sides to carry an identity and to disagree — a module naming a
/// category never lands on a section about a different one.
bool _matchesTarget(HomeSeeAll target, HomeSection section) {
  final seeAll = section.seeAll;
  if (seeAll == null || seeAll.target != target.target) return false;
  final want = _identityOf(target);
  if (want.isEmpty) return true;
  final have = _identityOf(seeAll);
  return have.isEmpty || have == want;
}

/// The one value that says *which* thing a see-all points at.
String _identityOf(HomeSeeAll seeAll) {
  const keys = [
    'categoryId',
    'categoryid',
    'categorySlug',
    'slug',
    'collectionSlug',
    'missionId',
    'id',
  ];
  for (final key in keys) {
    final value = _key(seeAll.params[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

/// The ranked-category pass: the original contract, unchanged.
MallHome _applyRanking(MallHome home, StorefrontLayout layout) {
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
  final (start, end) = _movableBand(sections);
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

/// The reason line a *module* earns, when the server left the section's own
/// empty.
///
/// Only the watched-reels module gets one, and it states the signal without
/// dressing it up. Counts are not spent here: this module's evidence counts
/// categories, not reels and not anything about this rail, and a number that
/// does not describe what the customer is looking at is worse than no number.
/// The recorded counts are surfaced on the prompt blocks, where they are
/// exactly about the one thing shown.
HomeSection _withModuleReason(HomeSection section, StorefrontModule module) {
  if (module.kind != StorefrontModuleKind.becauseYouWatched) return section;
  if (module.evidence <= 0) return section;
  final existing = section.reason;
  if (existing != null && existing.trim().isNotEmpty) return section;
  return _copyWithReason(section, 'From reels you have been watching');
}

/// What a module with no section on this page renders: a typographic prompt,
/// no imagery, stating a recorded count and opening a screen the app already
/// has.
///
/// Returns null — and the module is dropped in silence — when this build has
/// nowhere to send the shopper. `Refill` is that case today: "Buy It Again"
/// has a repository and a notifier but no screen, and a card promising items
/// due with nothing behind it is the broken block the fallback exists to
/// prevent.
HomePromptSection? _promptFor(StorefrontModule module) {
  final target = module.target;
  if (target == null) return null;

  final (id, eyebrow, title, action) = switch (module.kind) {
    StorefrontModuleKind.continueMission => (
      'storefront-mission',
      'Your mission',
      'Pick up where you left off',
      'Open mission',
    ),
    StorefrontModuleKind.refill => (
      'storefront-refill',
      'Running low',
      'Time to restock',
      'Buy it again',
    ),
    _ => ('', '', '', ''),
  };
  if (id.isEmpty) return null;

  final prompt = HomePromptSection(
    id: id,
    eyebrow: eyebrow,
    title: title,
    action: action,
    fact: _factFor(module),
    seeAll: target,
  );
  // The last word on whether this can be rendered belongs to routing, which
  // is the thing that actually knows where a target leads.
  return destinationForSeeAll(prompt) == null ? null : prompt;
}

/// The evidence line: the server's recorded count, phrased as the count it
/// is. No count, no line — and never a number the server did not send.
String? _factFor(StorefrontModule module) {
  final n = module.evidence;
  if (n <= 0) return null;
  return switch (module.kind) {
    StorefrontModuleKind.continueMission => n == 1
        ? '1 item still on your list'
        : '$n items still on your list',
    StorefrontModuleKind.refill => n == 1
        ? '1 item you buy regularly is due'
        : '$n items you buy regularly are due',
    _ => null,
  };
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
  return _copyWithReason(section, "Because you've been buying $label");
}

/// Re-makes [section] carrying [reason]. Section kinds with nowhere sensible
/// to put a reason line keep whatever the server sent.
HomeSection _copyWithReason(HomeSection section, String reason) {
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
