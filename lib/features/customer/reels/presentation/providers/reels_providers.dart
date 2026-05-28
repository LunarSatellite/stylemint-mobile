import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import '../../data/datasources/reels_remote_datasource.dart';
import '../../data/repositories/reels_repository_impl.dart';
import '../../domain/repositories/reels_repository.dart';
import '../../domain/usecases/get_reels_feed.dart';
import '../../domain/usecases/like_reel.dart';

part 'reels_providers.g.dart';

/// Provider for ReelsRemoteDatasource
@riverpod
ReelsRemoteDatasource reelsRemoteDatasource(ReelsRemoteDatasourceRef ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReelsRemoteDatasourceImpl(dioClient);
}

/// Provider for ReelsRepository
@riverpod
ReelsRepository reelsRepository(ReelsRepositoryRef ref) {
  final datasource = ref.watch(reelsRemoteDatasourceProvider);
  return ReelsRepositoryImpl(datasource);
}

/// Provider for GetReelsFeedUseCase
@riverpod
GetReelsFeed getReelsFeedUseCase(GetReelsFeedUseCaseRef ref) {
  final repository = ref.watch(reelsRepositoryProvider);
  return GetReelsFeed(repository);
}

/// Provider for LikeReelUseCase
@riverpod
LikeReel likeReelUseCase(LikeReelUseCaseRef ref) {
  final repository = ref.watch(reelsRepositoryProvider);
  return LikeReel(repository);
}
