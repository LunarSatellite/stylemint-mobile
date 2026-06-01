import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/entities/co_watch.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/notifiers/co_watch_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/screens/co_watch_session_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CoWatchScreen extends ConsumerWidget {
  const CoWatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coWatchSessionsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Co-Watch', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (sessions) => _buildBody(context, ref, sessions),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load sessions',
                  style: DesignTokens.mediumRegular),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                onPressed: () => ref
                    .read(coWatchSessionsNotifierProvider.notifier)
                    .loadSessions(),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.primaryGreen,
        onPressed: () {},
        icon: const Icon(Icons.play_circle_fill,
            color: DesignTokens.buttonPrimaryText),
        label: const Text('Start Co-Watch',
            style: TextStyle(color: DesignTokens.buttonPrimaryText)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      List<CoWatchSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.live_tv,
                size: 64, color: DesignTokens.textMuted),
            const SizedBox(height: DesignTokens.s16),
            const Text('No active co-watch sessions',
                style: DesignTokens.mediumRegular),
            const SizedBox(height: DesignTokens.s4),
            const Text('Start one to watch with friends!',
                style: DesignTokens.smallRegular),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(coWatchSessionsNotifierProvider.notifier).loadSessions(),
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.s16),
        itemCount: sessions.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: DesignTokens.s12),
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionTile(context, session);
        },
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, CoWatchSession session) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CoWatchSessionScreen(sessionId: session.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: Image.network(
                session.thumbnailUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundImage:
                            NetworkImage(session.hostAvatarUrl),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      Expanded(
                        child: Text(session.hostName,
                            style: DesignTokens.mediumSemibold),
                      ),
                      _sessionStatusBadge(session.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    session.contentType == CoWatchContentType.reel
                        ? 'Watching a reel'
                        : 'Browsing a product',
                    style: DesignTokens.smallRegular,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people,
                          size: 14, color: DesignTokens.textMuted),
                      const SizedBox(width: 4),
                      Text(
                          '${session.participants.length} watching',
                          style: DesignTokens.tiny),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: session.status == CoWatchSessionStatus.live
                  ? () {}
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.buttonPrimaryText,
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s8),
              ),
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionStatusBadge(CoWatchSessionStatus status) {
    Color color;
    String label;
    switch (status) {
      case CoWatchSessionStatus.live:
        color = DesignTokens.primaryGreen;
        label = 'LIVE';
      case CoWatchSessionStatus.waiting:
        color = DesignTokens.colorInfo;
        label = 'Waiting';
      case CoWatchSessionStatus.ended:
        color = DesignTokens.textMuted;
        label = 'Ended';
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(label,
          style: DesignTokens.tiny.copyWith(color: color)),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
