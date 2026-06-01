import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/entities/co_watch.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/notifiers/co_watch_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CoWatchSessionScreen extends ConsumerWidget {
  const CoWatchSessionScreen({super.key, required this.sessionId});

  final String sessionId;

  static const _reactions = ['❤️', '🔥', '😂', '😮', '👏'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coWatchSessionDetailNotifierProvider(sessionId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Co-Watch', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (session) =>
            _buildContent(context, ref, session),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load session',
                  style: DesignTokens.mediumRegular),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                onPressed: () {},
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, CoWatchSession session) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
          child: Row(
            children: [
              ...session.participants.take(5).map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundImage: NetworkImage(p.userAvatarUrl),
                      ),
                    ),
                  ),
              if (session.participants.length > 5)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: DesignTokens.bgAppBodyLight,
                  child: Text(
                    '+${session.participants.length - 5}',
                    style: DesignTokens.tiny,
                  ),
                ),
              const Spacer(),
              Text(
                '${session.participants.length} watching',
                style: DesignTokens.smallRegular,
              ),
            ],
          ),
        ),
        const Divider(color: DesignTokens.borderDefault, height: 1),
        Expanded(
          flex: 3,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: Image.network(session.thumbnailUrl,
                      fit: BoxFit.contain),
                ),
                const Positioned(
                  bottom: DesignTokens.s8,
                  left: DesignTokens.s8,
                  child: _FloatingReactions(),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            border: const Border(
                top: BorderSide(color: DesignTokens.borderDefault)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactions
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      ref
                          .read(coWatchSessionsNotifierProvider.notifier)
                          .sendReaction(session.id, emoji);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.s8),
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(
                            DesignTokens.chipRadius),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: OutlinedButton(
            onPressed: () {
              ref
                  .read(coWatchSessionsNotifierProvider.notifier)
                  .leave(session.id);
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
              side: const BorderSide(color: DesignTokens.colorError),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius)),
            ),
            child: const Text('Leave Session'),
          ),
        ),
      ],
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}

class _FloatingReactions extends StatefulWidget {
  const _FloatingReactions();

  @override
  State<_FloatingReactions> createState() => _FloatingReactionsState();
}

class _FloatingReactionsState extends State<_FloatingReactions>
    with SingleTickerProviderStateMixin {
  final List<_FloatingReaction> _reactions = [];
  final _random = Random();
  Timer? _timer;

  static const _emojiList = ['❤️', '🔥', '😂', '😮', '👏'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _reactions.add(_FloatingReaction(
          emoji: _emojiList[_random.nextInt(_emojiList.length)],
          left: _random.nextDouble() * 0.6 + 0.2,
          startTime: DateTime.now(),
          id: DateTime.now().microsecondsSinceEpoch.toString(),
        ));
      });
      _reactions.removeWhere(
          (r) => DateTime.now().difference(r.startTime).inSeconds > 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 300,
      child: Stack(
        children: _reactions.map((r) {
          return AnimatedPositioned(
            duration: const Duration(seconds: 3),
            left: r.left * 200,
            bottom: DateTime.now().difference(r.startTime).inSeconds < 1
                ? 0.0
                : 300.0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: DateTime.now().difference(r.startTime).inSeconds > 2
                  ? 0.0
                  : 1.0,
              child: Text(r.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FloatingReaction {
  final String emoji;
  final double left;
  final DateTime startTime;
  final String id;

  const _FloatingReaction({
    required this.emoji,
    required this.left,
    required this.startTime,
    required this.id,
  });
}
