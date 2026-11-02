/// One declared value (`DeclaredValueDto`).
class DeclaredValue {
  const DeclaredValue({
    required this.department,
    required this.context,
    required this.value,
  });

  final String department;
  final String context;
  final String value;
}

/// A dimension the shopper may declare (`DeclarableDimensionDto`).
class DeclarableDimension {
  const DeclarableDimension({
    required this.key,
    required this.label,
    required this.group,
    required this.valueType,
    required this.values,
    required this.sensitivity,
    this.departments = const [],
    this.unit,
    this.description,
    this.current = const [],
  });

  final String key;
  final String label;
  final String group;

  /// categorical | multi | numeric | range | boolean.
  final String valueType;
  final List<String> values;
  final List<String> departments;

  /// normal | declared_only.
  final String sensitivity;
  final String? unit;
  final String? description;
  final List<DeclaredValue> current;

  bool get isMulti => valueType == 'multi';
  bool get isDeclaredOnly => sensitivity == 'declared_only';

  /// The values declared for all departments in [context].
  Set<String> selectedIn(String context, {String department = '*'}) => {
    for (final v in current)
      if (v.context == context && v.department == department) v.value,
  };

  DeclarableDimension withCurrent(List<DeclaredValue> next) =>
      DeclarableDimension(
        key: key,
        label: label,
        group: group,
        valueType: valueType,
        values: values,
        departments: departments,
        sensitivity: sensitivity,
        unit: unit,
        description: description,
        current: next,
      );
}

/// `GET v1/customer/preferences` (`PreferenceCentreDto`).
class PreferenceCentre {
  const PreferenceCentre({
    required this.registryVersion,
    required this.contexts,
    required this.dimensions,
  });

  final int registryVersion;
  final List<String> contexts;
  final List<DeclarableDimension> dimensions;

  /// Dimensions with choosable values, grouped in first-seen group order.
  Map<String, List<DeclarableDimension>> get byGroup {
    final out = <String, List<DeclarableDimension>>{};
    for (final d in dimensions) {
      if (d.values.isEmpty) continue;
      (out[d.group] ??= []).add(d);
    }
    return out;
  }

  PreferenceCentre replacing(DeclarableDimension next) => PreferenceCentre(
    registryVersion: registryVersion,
    contexts: contexts,
    dimensions: [
      for (final d in dimensions) d.key == next.key ? next : d,
    ],
  );
}
