import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_comment_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_comments_controller.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

void showReelCommentsSheet(
  BuildContext context,
  String reelId, {
  VoidCallback? onCommentPosted,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        ReelCommentsSheet(reelId: reelId, onCommentPosted: onCommentPosted),
  );
}

class ReelCommentsSheet extends ConsumerStatefulWidget {
  const ReelCommentsSheet({
    required this.reelId,
    this.onCommentPosted,
    super.key,
  });

  final String reelId;
  final VoidCallback? onCommentPosted;

  @override
  ConsumerState<ReelCommentsSheet> createState() => _ReelCommentsSheetState();
}

class _ReelCommentsSheetState extends ConsumerState<ReelCommentsSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = reelCommentsControllerProvider(widget.reelId);
    final state = ref.watch(provider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 14),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'Comments',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Divider(color: DesignTokens.borderDefault, height: 1),

            // Comments list
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen,
                      ),
                    )
                  : state.comments.isEmpty
                  ? Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: DesignTokens.mediumRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: state.comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (_, i) => _CommentRow(
                        comment: state.comments[i],
                        liked: state.likedCommentIds.contains(
                          state.comments[i].id,
                        ),
                        likeCount: state.likeCounts[state.comments[i].id],
                        onLike: () => ref
                            .read(provider.notifier)
                            .toggleLike(state.comments[i].id),
                      ),
                    ),
            ),

            // Input bar
            _CommentInputBar(
              controller: _ctrl,
              sending: state.isPosting,
              onSend: () async {
                final text = _ctrl.text.trim();
                if (text.isEmpty) return;
                _ctrl.clear();
                final posted = await ref.read(provider.notifier).post(text);
                if (posted) widget.onCommentPosted?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMMENT ROW ──────────────────────────────────────────────────────────────
class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.liked,
    required this.onLike,
    this.likeCount,
  });

  final ReelCommentDto comment;
  final bool liked;
  final int? likeCount;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final c = comment;
    final handle = '@${c.authorDisplayName ?? 'User'}';
    final avatar = c.authorAvatarUrl ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: avatar.isNotEmpty
                ? Image.network(
                    avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        const SizedBox(width: 12),

        // Handle + body
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$handle  •  ${_relative(c.createdUtc)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                c.body,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Like
        GestureDetector(
          onTap: onLike,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: liked ? const Color(0xFFFB2C36) : DesignTokens.iconLight,
              ),
              const SizedBox(height: 2),
              Text(
                _compact(likeCount ?? c.likeCount),
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: DesignTokens.bgAppBodyLight,
    alignment: Alignment.center,
    child: const Icon(Icons.person, size: 22, color: DesignTokens.iconLight),
  );

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  String _relative(DateTime? dt) {
    if (dt == null) return '';
    final d = DateTime.now().difference(dt.toLocal());
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }
}

// ─── INPUT BAR ────────────────────────────────────────────────────────────────
class _CommentInputBar extends StatelessWidget {
  const _CommentInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: DesignTokens.bgAppBody,
          border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1),
          ),
        ),
        child: Row(
          children: [
            // User avatar placeholder
            ClipOval(
              child: Container(
                width: 36,
                height: 36,
                color: DesignTokens.bgAppBodyLight,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Text field (full-pill shape matching Figma)
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.textWhite,
                ),
                cursorColor: DesignTokens.primaryGreen,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: DesignTokens.textMuted,
                  ),
                  filled: true,
                  fillColor: DesignTokens.inputFieldFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: DesignTokens.inputFieldBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: DesignTokens.inputFieldBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                  suffixIcon: sending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: onSend,
                          child: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
