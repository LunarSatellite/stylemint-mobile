import 'dart:convert';

import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';

/// Matches the backend `NotificationDispatchDto` from
/// `GET /api/v1/notifications/inbox`. Fields are tolerant (nullable) — the
/// inbox contract is broad and partially template-driven.
class NotificationDispatchDto {
  const NotificationDispatchDto({
    required this.id,
    this.eventName,
    this.category,
    this.templateKey,
    this.variablesJson,
    this.queuedUtc,
    this.readUtc,
  });

  final String id;
  final String? eventName;
  final String? category;
  final String? templateKey;
  final String? variablesJson;
  final DateTime? queuedUtc;
  final DateTime? readUtc;

  factory NotificationDispatchDto.fromJson(Map<String, dynamic> json) {
    return NotificationDispatchDto(
      id: (json['id'] ?? '').toString(),
      eventName: json['eventName'] as String?,
      category: json['category'] as String?,
      templateKey: json['templateKey'] as String?,
      variablesJson: json['variablesJson'] as String?,
      queuedUtc: _parseDate(json['queuedUtc']),
      readUtc: _parseDate(json['readUtc']),
    );
  }

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  ActivityItem toDomain() => ActivityItem(
    id: id,
    title: _displayTitle(),
    occurredAt: queuedUtc,
    isRead: readUtc != null,
  );

  /// Display text is normally rendered server-/catalog-side from [templateKey]
  /// + [variablesJson]. We don't ship the template catalog, so this is a
  /// best-effort fallback: pull a human string out of the variables, else
  /// humanize the event name.
  String _displayTitle() {
    final vars = _decodeVars();
    for (final key in const ['title', 'message', 'body', 'text']) {
      final v = vars[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return _humanize(eventName ?? templateKey ?? 'Notification');
  }

  Map<String, dynamic> _decodeVars() {
    final raw = variablesJson;
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static String _humanize(String code) {
    final cleaned = code.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (cleaned.isEmpty) return 'Notification';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}
