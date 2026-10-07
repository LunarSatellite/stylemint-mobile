import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_formatters.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

/// Opens [FeedCommentsSheet] for the post at [postIndex], Instagram-style:
/// a rounded sheet that rises over the feed and follows the keyboard.
Future<void> showFeedCommentsSheet(
  BuildContext context, {
  required String postId,
  required int postIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLarge),
      ),
    ),
    builder: (_) => FeedCommentsSheet(postId: postId, postIndex: postIndex),
  );
}

class FeedCommentsSheet extends ConsumerStatefulWidget {
  const FeedCommentsSheet({
    required this.postId,
    required this.postIndex,
    super.key,
  });

  final String postId;
  final int postIndex;

  @override
  ConsumerState<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends ConsumerState<FeedCommentsSheet> {
  final _commentController = TextEditingController();
  List<FeedComment> _comments = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadComments());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final result = await ref
        .read(feedNotifierProvider.notifier)
        .loadComments(widget.postId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loading = false;
        _error = 'Could not load comments.';
      }),
      (page) => setState(() {
        _loading = false;
        _error = null;
        _comments = page.items;
      }),
    );
  }

  Future<void> _submit() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(feedNotifierProvider.notifier)
        .commentOnPost(widget.postId, content, widget.postIndex);
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _submitting = false;
        _error = 'Could not post comment.';
      }),
      (comment) => setState(() {
        _submitting = false;
        _commentController.clear();
        _comments = [..._comments, comment];
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewer = ref.watch(feedViewerProvider);
    final canPost = _commentController.text.trim().isNotEmpty && !_submitting;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    // Shrinks while the keyboard is up so the sheet never runs off the top.
    final sheetHeight = math.min(
      screenHeight * 0.72,
      screenHeight - keyboard - MediaQuery.paddingOf(context).top,
    );

    return Padding(
      // The sticky input rides up with the keyboard.
      padding: EdgeInsets.only(bottom: keyboard),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: math.max(sheetHeight, 0.0),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(
                  top: DesignTokens.s12,
                  bottom: DesignTokens.s8,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.sectionOnBase,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.s12),
                child: Text('Comments', style: DesignTokens.mediumSemibold),
              ),
              const Divider(height: 1, color: DesignTokens.borderDefault),
              Expanded(child: _buildComments()),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s4,
                  ),
                  child: Text(
                    _error!,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  ),
                ),
              const Divider(height: 1, color: DesignTokens.borderDefault),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s12,
                  DesignTokens.s8,
                  DesignTokens.s4,
                  DesignTokens.s8,
                ),
                child: Row(
                  children: [
                    FeedAvatar(
                      url: viewer?.avatarUrl,
                      size: DesignTokens.avatarMedium - 4,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: TextField(
                        key: const Key('feed-comments-input'),
                        controller: _commentController,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        style: DesignTokens.mediumRegular.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          hintStyle: DesignTokens.mediumRegular.copyWith(
                            color: DesignTokens.inputFieldPlaceholder,
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: DesignTokens.bgAppBodyLight,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16,
                            vertical: DesignTokens.s12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.chipRadius,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('feed-comments-post'),
                      onPressed: canPost ? _submit : null,
                      style: TextButton.styleFrom(
                        foregroundColor: DesignTokens.primaryGreen,
                        disabledForegroundColor: DesignTokens.primaryGreen
                            .withValues(alpha: 0.4),
                        textStyle: DesignTokens.mediumSemibold,
                      ),
                      child: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DesignTokens.primaryGreen,
                              ),
                            )
                          : const Text('Post'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComments() {
    if (_loading) return const SmPageLoader();
    if (_comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No comments yet',
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Start the conversation.',
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      itemCount: _comments.length,
      itemBuilder: (_, index) => _CommentRow(comment: _comments[index]),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.comment});

  final FeedComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAvatar(url: comment.userAvatarUrl),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: comment.userName,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '  ${feedTimeAgo(comment.createdAt)}',
                        style: DesignTokens.smallRegular,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
