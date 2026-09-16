/// Cart, checkout and order lines freeze a `variantLabelSnapshot` — today the
/// SKU. The catalog contract's `optionLabel` ("M / Emerald") reads far better
/// on a line, so wherever a payload carries both, prefer the option label.
///
/// Applied to the raw JSON before the freezed DTOs parse it, so every screen
/// that already shows the variant text picks the better label up automatically
/// once the backend starts sending `optionLabel` on cart/order lines.
Map<String, dynamic> withOptionLabels(Map<String, dynamic> json) {
  final result = <String, dynamic>{};
  for (final MapEntry(:key, :value) in json.entries) {
    result[key] = _normalize(value);
  }
  final label = (result['optionLabel'] as String?)?.trim();
  if (result.containsKey('variantLabelSnapshot') &&
      label != null &&
      label.isNotEmpty) {
    result['variantLabelSnapshot'] = label;
  }
  return result;
}

dynamic _normalize(dynamic value) => switch (value) {
  Map<String, dynamic>() => withOptionLabels(value),
  List<dynamic>() => value.map(_normalize).toList(),
  _ => value,
};
