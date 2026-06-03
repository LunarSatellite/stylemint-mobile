import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator row (avatar, name, track) with a Follow toggle, plus the caption.
/// Follow is gated through the shared [ensureAuth] for guests and persists via
/// the one-way follow graph ([followNotifierProvider] → POST/DELETE
/// /v1/follows/{creatorId}). Initial state is seeded from the reel's
/// isCreatorFollowed flag.
class CreatorInfo extends ConsumerStatefulWidget {
  const CreatorInfo({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<CreatorInfo> createState() => _CreatorInfoState();
}

class _CreatorInfoState extends ConsumerState<CreatorInfo> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final reel = widget.reel;
    final seed = reel.isCreatorFollowed;
    if (reel.creatorId.isNotEmpty && seed != null) {
      // Seed shared follow state after first frame (don't mutate a provider
      // during init/build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(followNotifierProvider.notifier)
              .seed(reel.creatorId, following: seed);
        }
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (!await ensureAuth(context, ref, reason: AuthReason.follow)) return;
    final id = widget.reel.creatorId;
    if (id.isEmpty) {
      if (mounted) {
        SmSnackbar.error(context, "This creator can't be followed right now.");
      }
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(followNotifierProvider.notifier).toggle(id);
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final isFollowing =
        ref.watch(followNotifierProvider).contains(reel.creatorId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: DesignTokens.avatarMedium / 2,
                backgroundColor: DesignTokens.bgAppBodyLight,
                backgroundImage: reel.creatorAvatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(reel.creatorAvatarUrl)
                    : null,
                child: reel.creatorAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: DesignTokens.iconLight)
                    : null,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reel.creatorName, maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textWhite)),
                    if (reel.musicTitle.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.s4),
                      Row(
                        children: [
                          const Icon(Icons.music_note,
                              size: DesignTokens.iconSmall,
                              color: DesignTokens.textLight),
                          const SizedBox(width: DesignTokens.s4),
                          Expanded(
                            child: Text(reel.musicTitle, maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DesignTokens.smallRegular.copyWith(
                                    color: DesignTokens.textLight)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              _FollowButton(
                  isFollowing: isFollowing, busy: _busy, onTap: _toggleFollow),
            ],
          ),
          if (reel.caption.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            Text(reel.caption, maxLines: 3,
                overflow: TextOverflow.ellipsis,
                // Spec: caption 12/400/130% white.
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: DesignTokens.textWhite,
                )),
          ],
        ],
      ),
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
        // Spec: white solid fill, #52525C text, 8px/16px padding (default state).
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : DesignTokens.textWhite,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          border: Border.all(
            color: isFollowing
                ? DesignTokens.textWhite
                : DesignTokens.textWhite,
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: DesignTokens.textWhite))
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
