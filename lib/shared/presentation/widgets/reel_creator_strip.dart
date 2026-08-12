import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator strip on the public reel-detail screen (used from
/// `ReelDetailsScreen`): avatar + display name + @handle + Follow toggle,
/// followed by a tap-to-expand caption. Visually mirrors [CreatorInfo] but
/// takes the creator fields directly rather than a `Reel` (the customer
/// reel entity binds payload the creator view does not need).
///
/// Follow is gated through the shared [ensureAuth] for guests and persists
/// via the one-way follow graph ([followNotifierProvider] -> POST/DELETE
/// /v1/follows/{creatorId}). Initial state is seeded from [initialFollowing]
/// when non-null. When [creatorId] is empty the strip still renders
/// (avatar -> placeholder, no Follow button) so the layout does not collapse
/// when the backend omits the creator payload.
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
  bool _busy = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    final id = widget.creatorId;
    final seed = widget.initialFollowing;
    if (id.isNotEmpty && seed != null) {
      // Seed shared follow state after first frame (do not mutate a provider
      // during init/build), matching [CreatorInfo].
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(followNotifierProvider.notifier)
              .seed(id, following: seed);
        }
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (!await ensureAuth(context, ref, reason: AuthReason.follow)) return;
    final id = widget.creatorId;
    if (id.isEmpty) {
      if (mounted) {
        SmSnackbar.error(
          context,
          "This creator can't be followed right now.",
        );
      }
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(followNotifierProvider.notifier).toggle(id);
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(
          context,
          "Couldn't update follow. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.creatorDisplayName.isNotEmpty
        ? widget.creatorDisplayName
        : widget.creatorHandle;
    final hasCreator = widget.creatorId.isNotEmpty;
    final isFollowing = hasCreator
        ? ref.watch(followNotifierProvider).contains(widget.creatorId)
        : false;
    final hasCaption =
        widget.caption != null && widget.caption!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: DesignTokens.avatarMedium / 2,
              backgroundColor: DesignTokens.bgAppBodyLight,
              backgroundImage: widget.creatorAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.creatorAvatarUrl)
                  : null,
              child: widget.creatorAvatarUrl.isEmpty
                  ? const Icon(Icons.person, color: DesignTokens.iconLight)
                  : null,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.textWhite),
                  ),
                  if (widget.creatorHandle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${widget.creatorHandle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            if (hasCreator)
              _FollowButton(
                isFollowing: isFollowing,
                busy: _busy,
                onTap: _toggleFollow,
              ),
          ],
        ),
        if (hasCaption) ...[
          const SizedBox(height: DesignTokens.s12),
          GestureDetector(
            onTap: _toggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Text(
              widget.caption!,
              maxLines: _expanded ? null : 3,
              overflow: _expanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              // Spec: caption 12/400/130% white. Inline style keeps it stable
              // even if DesignTokens.body shifts in the future.
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.3,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.busy,
    required this.onTap,
  });

  final bool isFollowing;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        // Spec: 8px/16px padding, white border; default state solid fill.
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : DesignTokens.textWhite,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          border: Border.all(color: DesignTokens.textWhite),
        ),
        child: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: DesignTokens.textWhite),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                // Spec: 12/600/130%, #52525C (Button-White-Text).
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ).copyWith(
                  color: isFollowing
                      ? DesignTokens.textWhite
                      : const Color(0xFF52525C),
                ),
              ),
      ),
    );
  }
}
