import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/support/data/datasources/support_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/support/data/repositories/support_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/repositories/support_repository.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/help_center_content.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — support feature
// ============================================================================

final supportRemoteDataSourceProvider = Provider<SupportRemoteDataSource>(
  (ref) => SupportRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepositoryImpl(
    remoteDataSource: ref.watch(supportRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final contactChannelsProvider = FutureProvider<ContactChannels>((ref) async {
  final result = await ref
      .watch(supportRepositoryProvider)
      .getContactChannels();
  return result.match(
    (failure) => throw StateError(failure.toString()),
    (channels) => channels,
  );
});

final helpCategoriesProvider = FutureProvider<List<HelpCenterCategory>>((
  ref,
) async {
  final result = await ref.watch(supportRepositoryProvider).getHelpCategories();
  return result.match(
    (failure) => throw StateError(failure.toString()),
    (categories) => categories,
  );
});

final helpArticlesProvider = FutureProvider.family
    .autoDispose<List<HelpArticleSummary>, String>((ref, categoryCode) async {
      final result = await ref
          .watch(supportRepositoryProvider)
          .getHelpArticles(categoryCode);
      return result.match(
        (failure) => throw StateError(failure.toString()),
        (articles) => articles,
      );
    });

final helpArticleProvider = FutureProvider.family
    .autoDispose<HelpArticleContent, ({String categoryCode, String slug})>(
      (ref, key) async {
        final result = await ref
            .watch(supportRepositoryProvider)
            .getHelpArticle(key.categoryCode, key.slug);
        return result.match(
          (failure) => throw StateError(failure.toString()),
          (article) => article,
        );
      },
    );

final supportNotifierProvider =
    StateNotifierProvider<SupportNotifier, TicketsState>(
      (ref) => SupportNotifier(ref.watch(supportRepositoryProvider)),
    );

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>(
      (ref) => CategoriesNotifier(ref.watch(supportRepositoryProvider)),
    );

final createTicketNotifierProvider =
    StateNotifierProvider<CreateTicketNotifier, CreateTicketState>(
      (ref) => CreateTicketNotifier(ref.watch(supportRepositoryProvider)),
    );
