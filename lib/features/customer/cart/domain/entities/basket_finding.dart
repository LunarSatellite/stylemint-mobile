/// The basket optimiser's evidence-backed findings — backend
/// `BasketFinding` / `BasketFindingFact` / `BasketFindingAction`.
///
/// Three rules govern everything in this file and the widgets that read it:
///
/// 1. The optimiser suggests; the customer decides. [BasketFindingAction] is a
///    *description* of an endpoint the customer's client may choose to reach
///    through its own existing paths. Nothing here acts on render.
/// 2. No number is invented or restated. [BasketFindingFact] carries its own
///    value and the record it came from; the client renders them as given and
///    never totals, averages, counts or scores them. There is no confidence
///    field on the wire and there must not appear to be one in the UI.
/// 3. The kind list grows. [BasketFindingKind] keeps the raw string, so a kind
///    this build has never heard of still renders its headline, detail and
///    facts instead of throwing or blanking.
library;

/// One piece of evidence, with the record it was read from.
class BasketFindingFact {
  const BasketFindingFact({
    required this.label,
    required this.value,
    required this.source,
  });

  /// Tolerant of a malformed element: a fact missing any of the three strings
  /// is dropped by [BasketFinding.listFromJson] rather than rendered blank.
  static BasketFindingFact? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final label = json['label'];
    final value = json['value'];
    final source = json['source'];
    if (label is! String || value is! String || source is! String) return null;
    if (label.isEmpty && value.isEmpty) return null;
    return BasketFindingFact(label: label, value: value, source: source);
  }

  final String label;

  /// Rendered verbatim. Already formatted by the backend, units and all.
  final String value;

  /// The record behind it, e.g. `catalog.product_attribute_value`.
  final String source;
}

/// What the customer *may* choose to do, as the backend describes it.
///
/// [path] is a server-side description of an existing guarded route, not a URL
/// to hand to the HTTP client. The client maps [kind] onto its own navigation
/// or cart operations and ignores a kind it does not recognise.
class BasketFindingAction {
  const BasketFindingAction({
    required this.kind,
    required this.label,
    required this.method,
    required this.path,
  });

  static BasketFindingAction? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final kind = json['kind'];
    final label = json['label'];
    if (kind is! String || kind.isEmpty) return null;
    if (label is! String || label.isEmpty) return null;
    return BasketFindingAction(
      kind: kind,
      label: label,
      method: json['method'] is String ? json['method'] as String : '',
      path: json['path'] is String ? json['path'] as String : '',
    );
  }

  final String kind;
  final String label;
  final String method;
  final String path;
}

/// The finding kinds this build knows how to weight and label. [unknown]
/// carries the wire string forward so a newer backend still renders.
enum BasketFindingKind {
  duplicateListing('duplicateListing'),
  priceChanged('priceChanged'),
  restrictedItem('restrictedItem'),
  currencyMismatch('currencyMismatch'),
  betterValuePerUnit('betterValuePerUnit'),
  deliverySplit('deliverySplit'),
  slowestLine('slowestLine'),

  /// Any kind added after this build shipped.
  unknown('');

  const BasketFindingKind(this.wireValue);

  final String wireValue;

  static BasketFindingKind parse(String? raw) {
    for (final kind in values) {
      if (kind != unknown && kind.wireValue == raw) return kind;
    }
    return unknown;
  }
}

/// Which sheet stage produced the finding. Unrecognised stages fall to
/// [unknown] and change nothing about how the finding renders.
enum BasketFindingStage {
  inspect('inspect'),
  compare('compare'),
  coordinate('coordinate'),
  unknown('');

  const BasketFindingStage(this.wireValue);

  final String wireValue;

  static BasketFindingStage parse(String? raw) {
    for (final stage in values) {
      if (stage != unknown && stage.wireValue == raw) return stage;
    }
    return unknown;
  }
}

/// One thing the optimiser noticed, and the records it rests on.
class BasketFinding {
  const BasketFinding({
    required this.kind,
    required this.rawKind,
    required this.stage,
    required this.headline,
    required this.detail,
    required this.facts,
    required this.lineIds,
    this.suggestedAction,
  });

  /// Parses the `findings` array. An element missing the three fields that are
  /// always present on the wire — `headline`, `detail`, `facts` — is dropped:
  /// a finding with nothing to say is not rendered.
  static List<BasketFinding> listFromJson(Object? json) {
    if (json is! List) return const [];
    final parsed = <BasketFinding>[];
    for (final element in json) {
      final finding = _tryFromJson(element);
      if (finding != null) parsed.add(finding);
    }
    return List.unmodifiable(parsed);
  }

  static BasketFinding? _tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final headline = json['headline'];
    final detail = json['detail'];
    if (headline is! String || headline.isEmpty) return null;

    final facts = <BasketFindingFact>[];
    final rawFacts = json['facts'];
    if (rawFacts is List) {
      for (final rawFact in rawFacts) {
        final fact = BasketFindingFact.tryFromJson(rawFact);
        if (fact != null) facts.add(fact);
      }
    }

    final rawKind = json['kind'] is String ? json['kind'] as String : '';
    return BasketFinding(
      kind: BasketFindingKind.parse(rawKind),
      rawKind: rawKind,
      stage: BasketFindingStage.parse(
        json['stage'] is String ? json['stage'] as String : null,
      ),
      headline: headline,
      detail: detail is String ? detail : '',
      facts: List.unmodifiable(facts),
      lineIds: List.unmodifiable(
        (json['lineIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>(),
      ),
      suggestedAction: BasketFindingAction.tryFromJson(json['suggestedAction']),
    );
  }

  final BasketFindingKind kind;

  /// The wire string, kept so an unknown kind is still identifiable in
  /// diagnostics without the UI guessing at its meaning.
  final String rawKind;

  final BasketFindingStage stage;
  final String headline;
  final String detail;
  final List<BasketFindingFact> facts;
  final List<String> lineIds;
  final BasketFindingAction? suggestedAction;

  /// A safety finding, not a price observation. Ordered first and drawn with
  /// the heaviest treatment the Mall kit has.
  bool get isSafety => kind == BasketFindingKind.restrictedItem;

  /// The basket may cost something other than the customer expects.
  bool get isPriceIntegrity =>
      kind == BasketFindingKind.priceChanged ||
      kind == BasketFindingKind.currencyMismatch;
}

/// Sort weight: safety first, then price integrity, then the rest in the order
/// the backend sent them. An unknown kind sorts with the ordinary findings
/// rather than being pushed out of sight — it has a headline worth reading.
int basketFindingWeight(BasketFinding finding) {
  if (finding.isSafety) return 0;
  if (finding.isPriceIntegrity) return 1;
  return 2;
}

/// Safety and price-integrity findings first, everything else untouched in
/// backend order. A stable sort, so the backend's own ordering survives inside
/// each band.
List<BasketFinding> orderBasketFindings(List<BasketFinding> findings) {
  final indexed =
      [
        for (var i = 0; i < findings.length; i++)
          (index: i, finding: findings[i]),
      ]..sort((a, b) {
        final byWeight = basketFindingWeight(
          a.finding,
        ).compareTo(basketFindingWeight(b.finding));
        return byWeight != 0 ? byWeight : a.index.compareTo(b.index);
      });
  return [for (final entry in indexed) entry.finding];
}
