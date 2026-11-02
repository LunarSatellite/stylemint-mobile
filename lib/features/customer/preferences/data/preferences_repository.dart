import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/mall_json_readers.dart';
import 'package:stylemint_mobile_frontend/features/customer/preferences/domain/preference_centre.dart';

/// The shopper preference centre (lead360 `CustomerPreferencesController`).
/// Throws on failure; callers show the error.
class PreferencesRepository {
  PreferencesRepository({required this.apiClient});

  final ApiClient apiClient;

  static const String path = '/v1/customer/preferences';
  static final Options _auth = Options(headers: {'requiresToken': true});

  Future<PreferenceCentre> load() async =>
      parsePreferenceCentre(readJsonObject(await apiClient.get(path)));

  /// Replaces the full value set for (key, department, context); empty clears.
  Future<DeclarableDimension?> put({
    required String key,
    required List<String> values,
    String? department,
    String context = 'self',
  }) async {
    final raw = await apiClient.put(
      path,
      data: {
        'key': key,
        'department': ?department,
        'context': context,
        'values': values,
      },
      options: _auth,
    );
    return raw is Map ? parseDeclarableDimension(raw) : null;
  }

  Future<void> clear({
    required String key,
    String? department,
    String context = 'self',
  }) async {
    await apiClient.authDelete(
      path,
      queryParameters: {
        'key': key,
        'department': ?department,
        'context': context,
      },
    );
  }

  Future<void> questionAsked({required String key, String? department}) async {
    await apiClient.post(
      '$path/questions-asked',
      data: {'key': key, 'department': ?department},
      options: _auth,
    );
  }
}

PreferenceCentre parsePreferenceCentre(Map<String, dynamic> json) {
  final dims = <DeclarableDimension>[];
  final raw = json['dimensions'];
  if (raw is List) {
    for (final entry in raw) {
      if (entry is! Map) continue;
      final d = parseDeclarableDimension(entry);
      if (d != null) dims.add(d);
    }
  }
  final contexts = readStringList(json['contexts']);
  return PreferenceCentre(
    registryVersion: readInt(json['registryVersion']),
    contexts: contexts.isEmpty ? const ['self'] : contexts,
    dimensions: List.unmodifiable(dims),
  );
}

DeclarableDimension? parseDeclarableDimension(Map<dynamic, dynamic> json) {
  final key = readString(json['key']);
  if (key.isEmpty) return null;
  final current = <DeclaredValue>[];
  final rawCurrent = json['current'];
  if (rawCurrent is List) {
    for (final c in rawCurrent) {
      if (c is! Map) continue;
      final value = readString(c['value']);
      if (value.isEmpty) continue;
      final dep = readString(c['department']);
      final ctx = readString(c['context']);
      current.add(
        DeclaredValue(
          department: dep.isEmpty ? '*' : dep,
          context: ctx.isEmpty ? 'self' : ctx,
          value: value,
        ),
      );
    }
  }
  final label = readString(json['label']);
  final group = readString(json['group']);
  return DeclarableDimension(
    key: key,
    label: label.isEmpty ? key : label,
    group: group.isEmpty ? 'other' : group,
    valueType: readString(json['valueType']),
    values: readStringList(json['values']),
    departments: readStringList(json['departments']),
    sensitivity: readString(json['sensitivity']),
    unit: readOptionalString(json['unit']),
    description: readOptionalString(json['description']),
    current: List.unmodifiable(current),
  );
}
