import 'dart:convert';

import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
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
      // `category` is an enum the server sends as a number.
      category: json['category']?.toString(),
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
    templateKey: templateKey,
    variablesJson: variablesJson,
  );

  /// The line for the commonest notifications, by type. The server renders
  /// the real text from its template catalog, which the app does not ship.
  static const Map<String, String> _knownTitles = {
    'order.placed': 'Your order was placed',
    'order.packed': 'Your order is packed and ready',
    'order.shipped': 'Your order is on its way',
    'order.delivered': 'Your order was delivered',
    'order.cancelled': 'Your order was cancelled',
    'order.refunded': 'Your refund is complete',
    'delivery.confirm_request': 'Your parcel is at the door — confirm delivery',
    'delivery.interest': 'A rider is ready to take your parcel',
    'delivery.delivered': 'Delivered — the recipient confirmed',
    'delivery.at_risk': 'Your delivery may be late',
    'plan.reminder.upcoming': 'A payment plan instalment is due soon',
    'plan.reminder.due': 'A payment plan instalment is due today',
    'plan.reminder.overdue': 'A payment plan instalment is overdue',
    'plan.defaulted': 'Your payment plan was closed',
    'payout.paid': 'Your payout was sent',
    'payout.failed': 'Your payout could not be sent',
  };

  /// Display text is normally rendered server-/catalog-side from [templateKey]
  /// + [variablesJson]. We don't ship the template catalog, so this is a
  /// best-effort fallback: pull a human string out of the variables, then a
  /// known line for the type, else humanize the template key or event name.
  String _displayTitle() {
    final vars = _decodeVars();
    for (final key in const ['title', 'message', 'body', 'text']) {
      final v = vars[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    final type = notificationTypeFromTemplateKey(templateKey);
    final known = type == null ? null : _knownTitles[type];
    if (known != null) return known;
    return _humanize(type ?? eventName ?? 'Notification');
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
