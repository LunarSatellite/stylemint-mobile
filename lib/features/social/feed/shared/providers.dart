import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/datasources/feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/repositories/feed_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/post_composer_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>(
  (ref) => FeedRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(
    remoteDataSource: ref.watch(feedRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final feedNotifierProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(
    ref.watch(feedRepositoryProvider),
    // Read at call time, not watched: a profile change must not rebuild the
    // notifier and drop the loaded feed.
    readViewer: () => ref.read(feedViewerProvider),
  ),
);

/// The post composer's attachments and their uploads. Auto-disposed: closing
/// the composer drops whatever was picked.
final postComposerNotifierProvider =
    StateNotifierProvider.autoDispose<PostComposerNotifier, PostComposerState>(
      (ref) => PostComposerNotifier(ref.watch(feedRepositoryProvider)),
    );
