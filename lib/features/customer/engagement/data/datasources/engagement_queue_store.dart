import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';

/// Where unsent engagement events wait — on this device only — so a flight
/// mode, a dead network or a killed app does not lose them.
abstract interface class EngagementQueueStore {
  Future<PendingEngagement?> read();

  Future<void> write(PendingEngagement pending);

  Future<void> clear();
}

/// [EngagementQueueStore] in `shared_preferences`.
class SharedPreferencesEngagementQueueStore implements EngagementQueueStore {
  const SharedPreferencesEngagementQueueStore();

  static const String storageKey = 'engagement.pending.v1';

  @override
  Future<PendingEngagement?> read() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(storageKey);
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final owner = json['owner'];
      final rows = json['events'];
      if (owner is! String || owner.isEmpty || rows is! List) return null;
      return PendingEngagement(
        owner: owner,
        events: [
          for (final row in rows)
            if (EngagementEvent.fromJson(row) case final event?) event,
        ],
      );
    } on Object catch (_) {
      // A corrupt entry is worth less than the app starting: drop it.
      return null;
    }
  }

  @override
  Future<void> write(PendingEngagement pending) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (pending.events.isEmpty) {
        await preferences.remove(storageKey);
        return;
      }
      await preferences.setString(
        storageKey,
        jsonEncode({
          'owner': pending.owner,
          'events': [for (final event in pending.events) event.toJson()],
        }),
      );
    } on Object catch (_) {
      // Best effort: the in-memory queue still holds the events.
    }
  }

  @override
  Future<void> clear() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(storageKey);
    } on Object catch (_) {}
  }
}

/// An [EngagementQueueStore] in memory, for tests.
class InMemoryEngagementQueueStore implements EngagementQueueStore {
  PendingEngagement? pending;

  @override
  Future<PendingEngagement?> read() async => pending;

  @override
  Future<void> write(PendingEngagement value) async =>
      pending = value.events.isEmpty ? null : value;

  @override
  Future<void> clear() async => pending = null;
}
