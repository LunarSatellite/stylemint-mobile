import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

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
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: Text('Comments', style: DesignTokens.sectionInnerTitle),
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                MediaQuery.viewInsetsOf(context).bottom + DesignTokens.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _submit(),
                      decoration: DesignTokens.inputDecoration(
                        hintText: 'Add a comment',
                      ),
                      style: DesignTokens.bodyText,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  IconButton(
                    tooltip: 'Post comment',
                    onPressed:
                        _commentController.text.trim().isNotEmpty &&
                            !_submitting
                        ? _submit
                        : null,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_comments.isEmpty) {
      return const Center(
        child: Text('No comments yet.', style: DesignTokens.mediumRegular),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.s16),
      itemCount: _comments.length,
      separatorBuilder: (_, _) => const Divider(
        height: DesignTokens.s24,
        color: DesignTokens.borderDefault,
      ),
      itemBuilder: (_, index) {
        final comment = _comments[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(comment.userName, style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s4),
            Text(comment.content, style: DesignTokens.mediumRegular),
          ],
        );
      },
    );
  }
}
