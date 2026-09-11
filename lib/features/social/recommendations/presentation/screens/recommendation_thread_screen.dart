import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/entities/recommendation.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/notifiers/recommendations_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class RecommendationThreadScreen extends ConsumerStatefulWidget {
  const RecommendationThreadScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<RecommendationThreadScreen> createState() =>
      _RecommendationThreadScreenState();
}

class _RecommendationThreadScreenState
    extends ConsumerState<RecommendationThreadScreen> {
  final _replyController = TextEditingController();
  bool _showProductField = false;
  bool _isSendingReply = false;
  final _productController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(recommendationsNotifierProvider.notifier)
          .loadThread(widget.requestId);
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _productController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text(
          'Thread',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: state.when(
        initial: _loader,
        requestsLoadInProgress: _loader,
        requestsLoadSuccess: (_, __, ___) => _loader(),
        requestsLoadFailure: (_) => _loader(),
        threadLoadInProgress: (_, __, ___) => _loader(),
        threadLoadSuccess: (_, __, ___, request, replies) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  children: [
                    _buildRequestHeader(request),
                    const SizedBox(height: DesignTokens.s24),
                    Text(
                      '${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                      style: DesignTokens.mediumSemibold,
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    if (replies.isEmpty)
                      const SmEmptyState(
                        message: 'No replies yet. Be the first to respond!',
                        icon: Icons.chat_bubble_outline,
                      )
                    else
                      ...replies.map((reply) => _buildReplyCard(reply)),
                  ],
                ),
              ),
              SafeArea(top: false, child: _buildReplyInput()),
            ],
          );
        },
        threadLoadFailure: (_, __, ___, failure) => SmErrorView(
          message: 'Failed to load thread.',
          onRetry: () => ref
              .read(recommendationsNotifierProvider.notifier)
              .loadThread(widget.requestId),
        ),
      ),
    );
  }

  Widget _buildRequestHeader(RecommendationRequest request) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: DesignTokens.avatarMedium / 2,
                backgroundImage: request.userAvatarUrl.isEmpty
                    ? null
                    : NetworkImage(request.userAvatarUrl),
                child: request.userAvatarUrl.isEmpty
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  request.userName,
                  style: DesignTokens.mediumSemibold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            request.question,
            style: DesignTokens.bodyText,
          ),
          if (request.context != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              request.context!,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
          if (request.taggedCategories.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s6,
              children: request.taggedCategories.map((cat) {
                return Chip(
                  label: Text(
                    cat,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  backgroundColor: DesignTokens.primaryGreenLight,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (request.taggedProducts.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.taggedProducts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: DesignTokens.s8),
                itemBuilder: (_, index) {
                  final p = request.taggedProducts[index];
                  return Container(
                    width: 140,
                    padding: const EdgeInsets.all(DesignTokens.s8),
                    decoration: DesignTokens.cardDecoration(
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      hasShadow: false,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.s4,
                          ),
                          child: Image.network(
                            p.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.productName,
                                style: DesignTokens.smallRegular.copyWith(
                                  color: DesignTokens.textWhite,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                formatMoney(p.price),
                                style: DesignTokens.smallRegular.copyWith(
                                  color: DesignTokens.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyCard(RecommendationReply reply) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: reply.userAvatarUrl.isEmpty
                      ? null
                      : NetworkImage(reply.userAvatarUrl),
                  child: reply.userAvatarUrl.isEmpty
                      ? const Icon(Icons.person_outline, size: 18)
                      : null,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    reply.userName,
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
                IconButton(
                  tooltip: 'Like reply',
                  onPressed: () async {
                    final error = await ref
                        .read(recommendationsNotifierProvider.notifier)
                        .likeReply(reply.id);
                    if (mounted && error != null) _showMessage(error);
                  },
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: DesignTokens.iconSmall,
                        color: DesignTokens.textMuted,
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        '${reply.likeCount}',
                        style: DesignTokens.smallRegular,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(reply.content, style: DesignTokens.bodyText),
            if (reply.suggestedProduct != null) ...[
              const SizedBox(height: DesignTokens.s8),
              InkWell(
                onTap: () {
                  // Backend doesn't populate this field yet (always null in
                  // practice) — was previously an empty if-block that did
                  // nothing even when a URL was present, silently eating
                  // the tap on this chip.
                  final url = reply.suggestedProductUrl;
                  if (url != null) {
                    unawaited(
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(DesignTokens.s8),
                  decoration: DesignTokens.cardDecoration(
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    hasShadow: false,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: DesignTokens.iconSmall,
                        color: DesignTokens.primaryGreen,
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      Expanded(
                        child: Text(
                          reply.suggestedProduct!,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(
            color: DesignTokens.borderDefault.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showProductField)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: TextField(
                controller: _productController,
                enabled: !_isSendingReply,
                style: DesignTokens.bodyText,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Suggest a product name or link...',
                ),
              ),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: _isSendingReply
                    ? null
                    : () => setState(
                        () => _showProductField = !_showProductField,
                      ),
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  size: DesignTokens.iconSmall,
                ),
                label: const Text('Suggest'),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.textWhite,
                  backgroundColor: _showProductField
                      ? DesignTokens.primaryGreenLight
                      : DesignTokens.bgAppBodyLight,
                  minimumSize: const Size(48, 48),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  enabled: !_isSendingReply,
                  style: DesignTokens.bodyText,
                  decoration: DesignTokens.inputDecoration(
                    hintText: 'Write a reply...',
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              IconButton(
                key: const Key('recommendation-send-reply'),
                tooltip: 'Send reply',
                onPressed: _isSendingReply ? null : _sendReply,
                style: IconButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  minimumSize: const Size(48, 48),
                ),
                icon: _isSendingReply
                    ? const SizedBox.square(
                        dimension: DesignTokens.iconMedium,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        size: DesignTokens.iconMedium,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty || _isSendingReply) return;
    setState(() => _isSendingReply = true);
    final error = await ref
        .read(recommendationsNotifierProvider.notifier)
        .reply(
          requestId: widget.requestId,
          content: content,
          suggestedProduct: _showProductField
              ? _productController.text.trim()
              : null,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _isSendingReply = false);
      _showMessage(error);
      return;
    }
    _replyController.clear();
    _productController.clear();
    setState(() {
      _isSendingReply = false;
      _showProductField = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
