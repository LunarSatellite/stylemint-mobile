import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/notifiers/live_sessions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Live Now" — Voyager doc's Social and Community Commerce capability.
/// Lists currently-live and upcoming Live Commerce sessions
/// (GET /v1/live-commerce/live and /upcoming).
class LiveSessionsScreen extends ConsumerWidget {
  const LiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveSessionsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Live'),
      ),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loadInProgress: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        loadFailure: (failure) => SmErrorView(
          message: failure.isNoInternet
              ? 'No internet connection.'
              : 'Failed to load live sessions.',
          onRetry: () => ref.read(liveSessionsNotifierProvider.notifier).load(),
        ),
        loadSuccess: (live, upcoming) {
          if (live.isEmpty && upcoming.isEmpty) {
            return const SmEmptyState(
              message: 'No live sessions right now. Check back soon!',
              icon: Icons.live_tv_outlined,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () => ref.read(liveSessionsNotifierProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                if (live.isNotEmpty) ...[
                  const Text('Live Now', style: DesignTokens.sectionInnerTitle),
                  const SizedBox(height: DesignTokens.s8),
                  ...live.map((s) => _SessionCard(session: s, isLive: true)),
                  const SizedBox(height: DesignTokens.s24),
                ],
                if (upcoming.isNotEmpty) ...[
                  const Text('Coming Up', style: DesignTokens.sectionInnerTitle),
                  const SizedBox(height: DesignTokens.s8),
                  ...upcoming.map((s) => _SessionCard(session: s, isLive: false)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.isLive});

  final LiveSession session;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLive
                  ? DesignTokens.colorError.withValues(alpha: 0.15)
                  : DesignTokens.bgAppBodyLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLive ? Icons.podcasts : Icons.schedule,
              color: isLive ? DesignTokens.colorError : DesignTokens.textMuted,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: DesignTokens.mediumSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isLive
                      ? '${session.currentViewerCount} watching now'
                      : 'Starts ${_formatTime(session.scheduledStartUtc)}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: isLive ? DesignTokens.colorError : DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (isLive)
            ElevatedButton(
              onPressed: () => context.push(
                RouteNames.liveRoom.replaceFirst(':sessionId', session.id),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.colorError,
                foregroundColor: DesignTokens.textWhite,
              ),
              child: const Text('Watch'),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
