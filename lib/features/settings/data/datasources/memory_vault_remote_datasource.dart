import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/memory_consent.dart';
import 'package:uuid/uuid.dart';

/// Maps a backend `CompanionMemoryDto`.
CompanionMemory companionMemoryFromJson(Map<String, dynamic> json) =>
    CompanionMemory(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      rememberedAt:
          DateTime.tryParse(json['createdUtc'] as String? ?? '') ??
          DateTime.now(),
      category: _categoryLabel(json['category']),
    );

/// `MemoryCategory` arrives as its name or its int value.
String? _categoryLabel(Object? value) => switch (value) {
  final String name when name.isNotEmpty => name,
  1 => 'Purchase',
  2 => 'Browsed',
  _ => null,
};

/// Maps a backend `MemoryPurposeDecision`.
///
/// A decision this build cannot name is kept rather than dropped: the
/// customer can still see that something is claiming their vault, and still
/// refuse it. Only [MemoryConsent.permitted] is read as permission, and it
/// defaults to false, so a malformed row is off rather than on.
MemoryConsent memoryConsentFromJson(Map<String, dynamic> json) {
  final rawPurpose = json['purpose'];
  final purpose = MemoryPurpose.fromWire(rawPurpose);
  return MemoryConsent(
    purpose: purpose,
    purposeCode: purpose?.wireValue ?? (rawPurpose is int ? rawPurpose : 0),
    permitted: json['permitted'] as bool? ?? false,
    basis: ConsentBasis.fromWire(json['basis']),
    reason: json['reason'] as String? ?? '',
    needsDecision: json['needsDecision'] as bool? ?? false,
    expiresUtc: DateTime.tryParse(json['expiresUtc'] as String? ?? ''),
  );
}

/// Memory Vault endpoints under `/v1/customer/companion`.
class MemoryVaultRemoteDataSource {
  MemoryVaultRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/customer/companion';

  Options _mutation() => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': const Uuid().v4()},
  );

  /// Just the consent flag from `GET /me`, without pulling the memories.
  ///
  /// The Memory Vault's pause switch is the customer's one control over
  /// being remembered, so anything that personalises what they are shown
  /// reads it from here rather than inventing a second setting. No companion
  /// yet (404) means nothing has been remembered and nothing is paused.
  Future<bool> isMemoryPaused() async {
    try {
      final me = await apiClient.get('$_base/me') as Map<String, dynamic>;
      return me['memoryPaused'] as bool? ?? false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return false;
      rethrow;
    }
  }

  Future<MemoryVault> load() async {
    final bool paused;
    try {
      final me = await apiClient.get('$_base/me') as Map<String, dynamic>;
      paused = me['memoryPaused'] as bool? ?? false;
    } on DioException catch (e) {
      // No companion yet, so nothing has been remembered.
      if (e.response?.statusCode == 404) {
        return const MemoryVault(paused: false, memories: []);
      }
      rethrow;
    }
    final list =
        await apiClient.get(
              '$_base/memories',
              queryParameters: {'limit': 100},
            )
            as List<dynamic>;
    return MemoryVault(
      paused: paused,
      memories: list
          .whereType<Map<String, dynamic>>()
          .map(companionMemoryFromJson)
          .toList(),
      consents: await loadConsents(),
    );
  }

  /// The current decision for every purpose the backend knows about.
  ///
  /// An absent list is not an answer. It comes back empty and the screen
  /// shows every purpose as undecided, which is exactly what it is.
  Future<List<MemoryConsent>> loadConsents() async {
    try {
      final list =
          await apiClient.get('$_base/memories/consents') as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(memoryConsentFromJson)
          .toList();
    } on DioException catch (e) {
      // No companion yet: nothing has been decided.
      if (e.response?.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Agrees to one purpose against [explanation] — the text the customer was
  /// shown. The backend stores it as the thing they agreed to, so callers
  /// pass the displayed string itself and never a paraphrase of it.
  Future<void> grantConsent({
    required MemoryPurpose purpose,
    required String explanation,
    DateTime? expiresUtc,
  }) async {
    final expiry = expiresUtc?.toUtc().toIso8601String();
    await apiClient.post(
      '$_base/memories/consents',
      data: {
        'purpose': purpose.wireValue,
        'explanation': explanation,
        'expiresUtc': ?expiry,
      },
      options: _mutation(),
    );
  }

  /// Withdraws one purpose. Takes the wire code rather than the enum so a
  /// purpose this build cannot name can still be refused.
  Future<void> revokeConsent(int purposeCode) async {
    await apiClient.authDelete(
      '$_base/memories/consents/$purposeCode',
      options: _mutation(),
    );
  }

  Future<CompanionMemory> correct(String memoryId, String content) async {
    final json =
        await apiClient.put(
              '$_base/memories/$memoryId',
              data: {'content': content},
              options: _mutation(),
            )
            as Map<String, dynamic>;
    return companionMemoryFromJson(json);
  }

  Future<void> forget(String memoryId) async {
    await apiClient.authDelete(
      '$_base/memories/$memoryId',
      options: _mutation(),
    );
  }

  Future<void> forgetAll() async {
    await apiClient.authDelete('$_base/memories', options: _mutation());
  }

  Future<void> setPaused({required bool paused}) async {
    await apiClient.patch(
      '$_base/me',
      data: {'memoryPaused': paused},
      options: _mutation(),
    );
  }

  /// The export document, pretty-printed for sharing.
  Future<String> export() async {
    final json = await apiClient.get('$_base/memories/portable-twin');
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  Future<Map<String, dynamic>> importPortableTwin(String bundleJson) async {
    final decoded = jsonDecode(bundleJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The private twin payload is invalid.');
    }
    return await apiClient.post(
          '$_base/memories/portable-twin/import',
          data: decoded,
          options: _mutation(),
        )
        as Map<String, dynamic>;
  }
}
