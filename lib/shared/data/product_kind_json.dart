/// Reads Catalog's `productKind` off a variant payload.
library;

import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';

const Map<String, int> _kindNames = {
  'physical': ProductKinds.physical,
  'digital': ProductKinds.digital,
  'service': ProductKinds.service,
  'subscription': ProductKinds.subscription,
  'bundle': ProductKinds.bundle,
};

/// Catalog's `ProductKind` as the int the enum defines, or null.
///
/// The wire may carry the enum as a number (`2`) or as its name (`"Digital"`)
/// depending on the serializer's converters, so both are read. **Null is
/// returned for anything else, including a missing field and a name this
/// build does not know** — the digital-goods gate treats null as "the server
/// did not say" and leaves the product alone, which is why this must never
/// fall back to [ProductKinds.physical]. A default of 1 would assert
/// "physical" about every payload from a server that sends no kind.
int? readProductKind(Object? raw) => switch (raw) {
  final num value => value.toInt(),
  final String value =>
    int.tryParse(value.trim()) ?? _kindNames[value.trim().toLowerCase()],
  _ => null,
};

/// The kind to attribute to a product whose variants carry [kinds].
///
/// A product is digital when **any** variant the payload named is digital: a
/// mixed product is still a path to digital content, and the card cannot say
/// which variant a quick add would land on. Null when no variant stated one.
int? resolveProductKind(Iterable<int?> kinds) {
  int? firstKnown;
  for (final kind in kinds) {
    if (kind == null) continue;
    if (isDigitalProductKind(kind)) return kind;
    firstKnown ??= kind;
  }
  return firstKnown;
}
