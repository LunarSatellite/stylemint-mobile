import 'package:stylemint_mobile_frontend/features/customer/ai_rails/data/datasources/ai_rails_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/entities/ai_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/repositories/ai_rails_repository.dart';

/// Every failure — 404 (not deployed, or an unknown anchor), a timeout, a
/// 5xx, a malformed body — is an empty rail. Nothing here surfaces an error:
/// the page around a rail already works without it.
class AiRailsRepositoryImpl implements AiRailsRepository {
  AiRailsRepositoryImpl({required this.remoteDataSource});

  final AiRailsRemoteDataSource remoteDataSource;

  static const int defaultLimit = 10;

  @override
  Future<ReelRail> alsoWatched(String reelId, {int limit = defaultLimit}) =>
      _rail(() => remoteDataSource.alsoWatched(reelId, limit: limit));

  @override
  Future<ProductRail> boughtTogether(
    String productId, {
    int limit = defaultLimit,
  }) => _rail(() => remoteDataSource.boughtTogether(productId, limit: limit));

  @override
  Future<ProductRail> alsoViewed(
    String productId, {
    int limit = defaultLimit,
  }) => _rail(() => remoteDataSource.alsoViewed(productId, limit: limit));

  @override
  Future<ReelMatches> reelsForProduct(
    String productId, {
    int limit = defaultLimit,
  }) => _matches(
    () => remoteDataSource.reelsForProduct(productId, limit: limit),
  );

  @override
  Future<ReelMatches> similarReels(
    String reelId, {
    int limit = defaultLimit,
  }) => _matches(() => remoteDataSource.similarReels(reelId, limit: limit));

  static Future<AiRail<T>> _rail<T>(Future<AiRail<T>> Function() read) async {
    try {
      return await read();
    } on Object catch (_) {
      return AiRail<T>.empty(AiRailStatus.notDeployed);
    }
  }

  static Future<ReelMatches> _matches(
    Future<ReelMatches> Function() read,
  ) async {
    try {
      return await read();
    } on Object catch (_) {
      return const ReelMatches.notDeployed();
    }
  }
}
