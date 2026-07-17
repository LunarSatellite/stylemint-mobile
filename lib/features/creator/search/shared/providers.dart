import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/data/datasources/creator_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/presentation/notifiers/creator_search_notifier.dart';

final creatorSearchRemoteDataSourceProvider =
    Provider<CreatorSearchRemoteDataSource>(
  (ref) => CreatorSearchRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  ),
);

final creatorSearchNotifierProvider =
    StateNotifierProvider.autoDispose<CreatorSearchNotifier, CreatorSearchState>(
  (ref) => CreatorSearchNotifier(ref.watch(creatorSearchRemoteDataSourceProvider)),
);
