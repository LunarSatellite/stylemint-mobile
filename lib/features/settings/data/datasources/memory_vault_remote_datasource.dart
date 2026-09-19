import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
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

/// Memory Vault endpoints under `/v1/customer/companion`.
class MemoryVaultRemoteDataSource {
  MemoryVaultRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/customer/companion';

  Options _mutation() => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': const Uuid().v4()},
  );

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
