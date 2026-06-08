import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_comment_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_comments_controller.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Reel Comments — list + post. Pixel-matched to `Reel Comments.pdf`.
/// Backend: GET/POST `/v1/customer/reels/{reelId}/comments`.
class ReelCommentsScreen extends ConsumerStatefulWidget {
  const ReelCommentsScreen({super.key, required this.reelId});

  final String reelId;

  @override
  ConsumerState<ReelCommentsScreen> createState() =>
      _ReelCommentsScreenState();
}

class _ReelCommentsScreenState extends ConsumerState<ReelCommentsScreen> {
  final _inputCtrl = TextEditingController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = reelCommentsControllerProvider(widget.reelId);
    final state = ref.watch(provider);

    ref.listen<ReelCommentsState>(provider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        // Spec: header title 16/600/lh1.0 white, centered.
        title: const Text('Comments',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.0,
              color: DesignTokens.textWhite,
            )),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen))
                : state.comments.isEmpty
                    ? Center(
                        child: Text('No comments yet. Be the first!',
                            style: DesignTokens.bodyText),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(DesignTokens.s16),
                        itemCount: state.comments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: DesignTokens.s32),
                        itemBuilder: (_, i) =>
                            _CommentTile(comment: state.comments[i]),
                      ),
          ),
          _Composer(
            controller: _inputCtrl,
            sending: state.isPosting,
            onSend: () {
              final text = _inputCtrl.text;
              _inputCtrl.clear();
              ref.read(provider.notifier).post(text);
            },
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  const _CommentTile({required this.comment});

  final ReelCommentDto comment;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  // MOCK — the comment DTO has no `isLiked` flag and there's no like endpoint
  // yet, so the like toggle is local/optimistic only (not persisted).
  bool _liked = false;
  late int _likeCount = widget.comment.likeCount;

  static const TextStyle _metaStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.0,
    color: DesignTokens.textMuted,
  );

  void _toggleLike() => setState(() {
        _liked = !_liked;
        _likeCount += _liked ? 1 : -1;
      });

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final avatar = comment.authorAvatarUrl;
    final handle = '@${comment.authorDisplayName ?? 'User'}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
            // Spec: 32px comment avatar.
            width: 32,
            height: 32,
            child: (avatar == null || avatar.isEmpty)
                ? Container(
                    color: DesignTokens.bgAppBodyLight,
                    alignment: Alignment.center,
                    child: const Icon(Icons.person,
                        size: 22, color: DesignTokens.iconLight),
                  )
                : Image.network(avatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: DesignTokens.bgAppBodyLight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.person,
                              size: 22, color: DesignTokens.iconLight),
                        )),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spec: @handle • time meta line 10/600/lh1.0 #9F9FA9, dot sep.
              Row(
                children: [
                  Flexible(
                    child: Text(handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _metaStyle),
                  ),
                  Container(
                    width: 3,
                    height: 3,
                    margin:
                        const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF71717B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Text(_relative(comment.createdUtc), style: _metaStyle),
                ],
              ),
              const SizedBox(height: DesignTokens.s4),
              // Spec: comment body 12/400/lh1.5 #FFFFFF.
              Text(comment.body,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: DesignTokens.textWhite,
                  )),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        // Spec: trailing like column — 20px icon (#9F9FA9 / liked #FB2C36) +
        // count 10/600 #9F9FA9 below.
        GestureDetector(
          onTap: _toggleLike,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _liked ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: _liked ? const Color(0xFFFB2C36) : DesignTokens.iconLight,
              ),
              const SizedBox(height: 2),
              Text(_compact(_likeCount), style: _metaStyle),
            ],
          ),
        ),
      ],
    );
  }

  static String _compact(int n) {
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

class _Composer extends StatelessWidget {
  const _Composer({
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
        // Spec: composer padding 16/16/16/0, 1px top border, 12px gap.
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s16,
            DesignTokens.s16, 0),
        decoration: const BoxDecoration(
          color: DesignTokens.bgAppFoundation,
          border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: DesignTokens.bodyText,
                cursorColor: DesignTokens.primaryGreen,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add a comment…',
                  // Spec: placeholder 14/400/lh1.5 #9F9FA9.
                  hintStyle: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: DesignTokens.textMuted,
                  ),
                  filled: true,
                  fillColor: DesignTokens.inputFieldFill,
                  isDense: true,
                  // Spec: radius 8, 1px #52525C border, padding 12/10.
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                    borderSide:
                        const BorderSide(color: DesignTokens.inputFieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                    borderSide:
                        const BorderSide(color: DesignTokens.inputFieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                    borderSide:
                        const BorderSide(color: DesignTokens.primaryGreen),
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            sending
                ? const Padding(
                    padding: EdgeInsets.all(DesignTokens.s8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: DesignTokens.primaryGreen),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: DesignTokens.primaryGreen),
                    onPressed: onSend,
                  ),
          ],
        ),
      ),
    );
  }
}
