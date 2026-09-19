import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/adaptive_storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/adaptive_storefront_repository.dart';

/// Swallows every failure by design — see the interface. A 401, a timeout, a
/// 500 and a malformed body all mean the same thing to the Mall: show the
/// page everybody else sees.
class AdaptiveStorefrontRepositoryImpl implements AdaptiveStorefrontRepository {
  AdaptiveStorefrontRepositoryImpl({required this.remoteDataSource});

  final AdaptiveStorefrontRemoteDataSource remoteDataSource;

  @override
  Future<StorefrontLayout> getLayout() async {
    try {
      return await remoteDataSource.getLayout();
    } on Object catch (_) {
      return StorefrontLayout.none;
    }
  }

  @override
  Future<void> trackInteraction(FeedSignal signal) async {
    try {
      await remoteDataSource.trackInteraction(signal);
    } on Object catch (_) {
      // A signal is worth nothing if losing it costs the customer anything.
    }
  }
}
