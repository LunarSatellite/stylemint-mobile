import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReelCreatorStrip extends ConsumerStatefulWidget {
  const ReelCreatorStrip({
    required this.creatorId,
    required this.creatorHandle,
    required this.creatorDisplayName,
    required this.creatorAvatarUrl,
    required this.caption,
    required this.initialFollowing,
    super.key,
  });

  final String creatorId;
  final String creatorHandle;
  final String creatorDisplayName;
  final String creatorAvatarUrl;
  final String? caption;
  final bool? initialFollowing;

  @override
  ConsumerState<ReelCreatorStrip> createState() => _ReelCreatorStripState();
}

class _ReelCreatorStripState extends ConsumerState<ReelCreatorStrip> {
  bool _captionExpanded = false;

  @override
  void initState() {
    super.initState();
    final initialFollowing = widget.initialFollowing;
    if (initialFollowing != null) {
      ref.read(followNotifierProvider.notifier).seed(
            widget.creatorId,
            following: initialFollowing,
          );
    }
  }

  Future<void> _toggleFollow() async {
    try {
      await ref.read(followNotifierProvider.notifier).toggle(widget.creatorId);
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    }
  }

  void _openProfile() {
    if (widget.creatorId.isEmpty) return;
    context.push(
      '/creator-profile/${widget.creatorId}',
      extra: CreatorProfileArgs(
        accountId: widget.creatorId,
        displayName: widget.creatorDisplayName,
        handle: widget.creatorHandle,
        avatarUrl: widget.creatorAvatarUrl.isEmpty
            ? null
            : widget.creatorAvatarUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final following = ref.watch(followNotifierProvider).contains(widget.creatorId);
    final displayName = widget.creatorDisplayName.isEmpty
        ? '@${widget.creatorHandle}'
        : widget.creatorDisplayName;
    final avatar = widget.creatorAvatarUrl;
    final caption = widget.caption;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _openProfile,
                child: ClipOval(
                  child: SizedBox(
                    width: DesignTokens.avatarMedium,
                    height: DesignTokens.avatarMedium,
                    child: avatar.isEmpty
                        ? const ColoredBox(
                            color: DesignTokens.bgAppBodyLight,
                            child: Icon(Icons.person, color: DesignTokens.iconLight),
                          )
                        : Image.network(
                            avatar,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: DesignTokens.bgAppBodyLight,
                              child: Icon(Icons.person, color: DesignTokens.iconLight),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: GestureDetector(
                  onTap: _openProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      if (widget.creatorHandle.isNotEmpty)
                        Text(
                          '@${widget.creatorHandle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.creatorId.isNotEmpty) ...[
                const SizedBox(width: DesignTokens.s8),
                _FollowButton(
                  following: following,
                  onTap: _toggleFollow,
                ),
              ],
            ],
          ),
          if (caption != null && caption.trim().isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            GestureDetector(
              onTap: () => setState(() => _captionExpanded = !_captionExpanded),
              child: Text(
                caption,
                maxLines: _captionExpanded ? null : 2,
                overflow: _captionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.following, required this.onTap});

  final bool following;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: following
              ? DesignTokens.bgAppBodyLight
              : DesignTokens.primaryGreen,
          borderRadius: BorderRadius.circular(999),
          border: following
              ? Border.all(color: DesignTokens.borderDefault)
              : null,
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: DesignTokens.oneLinerSemibold.copyWith(
            color: following
                ? DesignTokens.textWhite
                : DesignTokens.buttonPrimaryText,
          ),
        ),
      ),
    );
  }
}
