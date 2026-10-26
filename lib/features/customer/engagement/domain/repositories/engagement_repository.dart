import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';

/// Sends engagement batches and keeps the unsent ones on this device.
///
/// Nothing here throws: a send answers with what to do next, and a store
/// that cannot be read or written behaves as an empty one.
abstract interface class EngagementRepository {
  /// One batch, at most [maxBatch] events.
  Future<EngagementSendOutcome> send(List<EngagementEvent> events);

  Future<PendingEngagement?> readPending();

  Future<void> writePending(PendingEngagement pending);

  Future<void> clearPending();

  /// The contract's ceiling per call.
  static const int maxBatch = 50;
}
