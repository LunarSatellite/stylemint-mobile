import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_queue_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/entities/engagement_event.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/repositories/engagement_repository.dart';

class EngagementRepositoryImpl implements EngagementRepository {
  EngagementRepositoryImpl({
    required this.remoteDataSource,
    required this.store,
  });

  final EngagementRemoteDataSource remoteDataSource;
  final EngagementQueueStore store;

  @override
  Future<EngagementSendOutcome> send(List<EngagementEvent> events) =>
      remoteDataSource.send(events);

  @override
  Future<PendingEngagement?> readPending() => store.read();

  @override
  Future<void> writePending(PendingEngagement pending) => store.write(pending);

  @override
  Future<void> clearPending() => store.clear();
}
