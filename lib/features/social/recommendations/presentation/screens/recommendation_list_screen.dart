import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/notifiers/recommendations_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/widgets/recommendation_card.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/widgets/request_create_sheet.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:go_router/go_router.dart';

class RecommendationListScreen extends ConsumerWidget {
  const RecommendationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: DesignTokens.primaryGreen,
            ),
            SizedBox(width: DesignTokens.s8),
            Text(
              'Ask Friends',
              style: DesignTokens.sectionInnerTitle,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: DesignTokens.primaryGreen,
        onRefresh: () =>
            ref.read(recommendationsNotifierProvider.notifier).loadRequests(),
        child: state.when(
          initial: _loader,
          requestsLoadInProgress: _loader,
          requestsLoadSuccess: (requests, _, __) {
            if (requests.isEmpty) {
              return const SmEmptyState(
                message: 'No questions yet. Be the first to ask!',
                icon: Icons.help_outline_rounded,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              itemCount: requests.length,
              itemBuilder: (_, index) => RecommendationCard(
                request: requests[index],
                onTap: () => context.pushNamed(
                  RouteNames.recommendations,
                  pathParameters: {'requestId': requests[index].id},
                ),
              ),
            );
          },
          requestsLoadFailure: (failure) => SmErrorView(
            message: 'Failed to load recommendations.',
            onRetry: () =>
                ref
                    .read(recommendationsNotifierProvider.notifier)
                    .loadRequests(),
          ),
          threadLoadInProgress: (requests, _, __) {
            if (requests.isEmpty) {
              return const SmEmptyState(
                message: 'No questions yet.',
                icon: Icons.help_outline_rounded,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              itemCount: requests.length,
              itemBuilder: (_, index) => RecommendationCard(
                request: requests[index],
                onTap: () => context.pushNamed(
                  RouteNames.recommendations,
                  pathParameters: {'requestId': requests[index].id},
                ),
              ),
            );
          },
          threadLoadSuccess: (requests, _, __, ___, ____) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              itemCount: requests.length,
              itemBuilder: (_, index) => RecommendationCard(
                request: requests[index],
                onTap: () => context.pushNamed(
                  RouteNames.recommendations,
                  pathParameters: {'requestId': requests[index].id},
                ),
              ),
            );
          },
          threadLoadFailure: (requests, _, __, ___) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              itemCount: requests.length,
              itemBuilder: (_, index) => RecommendationCard(
                request: requests[index],
                onTap: () => context.pushNamed(
                  RouteNames.recommendations,
                  pathParameters: {'requestId': requests[index].id},
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryGreen,
        onPressed: () => _showCreateRequestSheet(context, ref),
        child: const Icon(Icons.add, color: DesignTokens.textWhite),
      ),
    );
  }

  void _showCreateRequestSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.cardRadius)),
      ),
      builder: (_) => RequestCreateSheet(
        onSubmit: (question, context_, categories) {
          ref
              .read(recommendationsNotifierProvider.notifier)
              .createRequest(
                question: question,
                context: context_,
                categories: categories,
              );
        },
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
