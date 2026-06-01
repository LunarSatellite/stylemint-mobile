import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_items_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saved_item_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class SavedItemsScreen extends ConsumerWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedItemsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Saved Items',
          style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
        ),
        centerTitle: true,
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (items, hasMore, nextCursor) {
          if (items.isEmpty) {
            return const SmEmptyState(
              message: "You haven't saved any items yet. Tap the heart on products you love.",
              icon: Icons.bookmark_border_rounded,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () => ref.read(savedItemsNotifierProvider.notifier).load(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200 &&
                    hasMore) {
                  ref.read(savedItemsNotifierProvider.notifier).loadMore();
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(DesignTokens.s16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: DesignTokens.s12,
                  mainAxisSpacing: DesignTokens.s12,
                  childAspectRatio: 0.62,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => SavedItemCard(
                  item: items[i],
                  onTap: () {
                    // TODO: navigate to product detail
                  },
                  onRemove: () => ref
                      .read(savedItemsNotifierProvider.notifier)
                      .removeItem(items[i].id),
                ),
              ),
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load saved items.',
          onRetry: () => ref.read(savedItemsNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
