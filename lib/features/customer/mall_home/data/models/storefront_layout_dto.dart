import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';

/// Reads `GET v1/customer/feed/storefront-layout`.
///
/// Hand-written and deliberately tolerant. The server record is
/// `StorefrontLayout(RankedCategories, IsPersonalized, Status, Modules,
/// Context)`; whether it reaches the wire camelCased or PascalCased depends
/// on the serializer, and a personalised home page is not worth losing to
/// that. A ranking entry with no category id is dropped rather than silently
/// reordering nothing.
///
/// Additive fields are read with the same tolerance and the same silence: a
/// module whose kind this build does not know parses as
/// [StorefrontModuleKind.unknown] and is dropped by the layer that renders,
/// never here — the server still ranked it, and the ranks stay contiguous in
/// what the client did keep.
StorefrontLayout storefrontLayoutFromJson(Map<String, dynamic> json) {
  final ranked = _rankedFrom(
    json['rankedCategories'] ?? json['RankedCategories'],
  );
  final personalized = readBool(
    json['isPersonalized'] ?? json['IsPersonalized'],
  );
  final status = _statusFrom(readString(json['status'] ?? json['Status']));

  // The customer's own choice, honoured before anything else is read.
  if (status == StorefrontLayoutStatus.personalizationPaused) {
    return const StorefrontLayout(
      rankedCategories: [],
      isPersonalized: false,
      status: StorefrontLayoutStatus.personalizationPaused,
    );
  }

  final modules = _modulesFrom(json['modules'] ?? json['Modules']);
  final hasRanking = personalized && ranked.isNotEmpty;
  if (!hasRanking && modules.isEmpty) {
    return StorefrontLayout(
      rankedCategories: const [],
      isPersonalized: false,
      status: status,
    );
  }

  return StorefrontLayout(
    rankedCategories: hasRanking ? ranked : const [],
    isPersonalized: hasRanking,
    status: status,
    modules: modules,
    context: _contextFrom(json['context'] ?? json['Context']),
  );
}

List<StorefrontCategoryRank> _rankedFrom(Object? raw) {
  final ranked = <StorefrontCategoryRank>[];
  if (raw is! List) return ranked;
  for (final entry in raw) {
    if (entry is! Map) continue;
    final item = Map<String, dynamic>.from(entry);
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
  return ranked;
}

/// Modules in the server's rank order. A malformed entry is dropped; the
/// order of what survives is the server's, not the list's.
List<StorefrontModule> _modulesFrom(Object? raw) {
  if (raw is! List) return const [];
  final modules = <StorefrontModule>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final item = Map<String, dynamic>.from(entry);
    final kind = _kindFrom(readString(item['kind'] ?? item['Kind']));
    modules.add(
      StorefrontModule(
        kind: kind,
        rank: readInt(item['rank'] ?? item['Rank']),
        signal: _signalFrom(readString(item['signal'] ?? item['Signal'])),
        // Never invented: an absent or unreadable count reads as zero, and
        // zero is not shown.
        evidence: readInt(item['evidence'] ?? item['Evidence']),
        categoryIds: _idsFrom(item['categoryIds'] ?? item['CategoryIds']),
        target: _targetFrom(item['target'] ?? item['Target']),
      ),
    );
  }
  modules.sort((a, b) => a.rank.compareTo(b.rank));
  return modules;
}

List<String> _idsFrom(Object? raw) {
  if (raw is! List) return const [];
  final ids = <String>[];
  for (final entry in raw) {
    final id = readString(entry);
    if (id.isNotEmpty) ids.add(id);
  }
  return ids;
}

/// The module's destination, in the home page's own see-all vocabulary.
HomeSeeAll? _targetFrom(Object? raw) {
  if (raw is! Map) return null;
  final item = Map<String, dynamic>.from(raw);
  final name = readString(item['target'] ?? item['Target']);
  if (name.isEmpty) return null;
  final params = <String, String>{};
  final rawParams = item['params'] ?? item['Params'];
  if (rawParams is Map) {
    for (final MapEntry(:key, :value) in rawParams.entries) {
      final k = readString(key);
      final v = readString(value);
      if (k.isNotEmpty && v.isNotEmpty) params[k] = v;
    }
  }
  return HomeSeeAll(target: homeSeeAllTargetFromWire(name), params: params);
}

StorefrontContext _contextFrom(Object? raw) {
  if (raw is! Map) return StorefrontContext.none;
  final item = Map<String, dynamic>.from(raw);
  final intent = readString(item['sessionIntent'] ?? item['SessionIntent']);
  return StorefrontContext(
    sessionIntent: intent.isEmpty ? 'browsing' : intent.toLowerCase(),
    signalsUsed: _signalsFrom(item['signalsUsed'] ?? item['SignalsUsed']),
    signalsUnavailable: _signalsFrom(
      item['signalsUnavailable'] ?? item['SignalsUnavailable'],
    ),
  );
}

List<StorefrontSignal> _signalsFrom(Object? raw) {
  if (raw is! List) return const [];
  return [for (final entry in raw) _signalFrom(readString(entry))];
}

/// The wire sends names; an int enum would also arrive as a name through
/// `JsonStringEnumConverter`, so only names are matched and anything else is
/// [StorefrontLayoutStatus.unknown] — which renders as the ordinary page.
StorefrontLayoutStatus _statusFrom(String raw) => switch (raw.toLowerCase()) {
  'personalized' || 'personalised' => StorefrontLayoutStatus.personalized,
  'nohistory' => StorefrontLayoutStatus.noHistory,
  'unavailable' => StorefrontLayoutStatus.unavailable,
  'personalizationpaused' ||
  'personalisationpaused' => StorefrontLayoutStatus.personalizationPaused,
  // Absent is the old contract, which only ever meant "personalized".
  '' => StorefrontLayoutStatus.personalized,
  _ => StorefrontLayoutStatus.unknown,
};

StorefrontModuleKind _kindFrom(String raw) => switch (raw.toLowerCase()) {
  'continuemission' => StorefrontModuleKind.continueMission,
  'refill' => StorefrontModuleKind.refill,
  'becauseyouwatched' => StorefrontModuleKind.becauseYouWatched,
  'boughtbefore' => StorefrontModuleKind.boughtBefore,
  _ => StorefrontModuleKind.unknown,
};

StorefrontSignal _signalFrom(String raw) => switch (raw.toLowerCase()) {
  'recentpurchases' => StorefrontSignal.recentOrders,
  'watchedreels' => StorefrontSignal.watchedReels,
  'activemission' => StorefrontSignal.activeMission,
  'replenishmentdue' => StorefrontSignal.replenishmentDue,
  'sessionintent' => StorefrontSignal.sessionIntent,
  _ => StorefrontSignal.unknown,
};
