import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator row (avatar, name, track) with a Follow toggle, plus the caption.
/// Follow is gated through the shared [ensureAuth] for guests.
class CreatorInfo extends ConsumerStatefulWidget {
  const CreatorInfo({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<CreatorInfo> createState() => _CreatorInfoState();
}

class _CreatorInfoState extends ConsumerState<CreatorInfo> {
  late bool _isFollowing = widget.reel.isCreatorFollowed ?? false;

  Future<void> _toggleFollow() async {
    if (!await ensureAuth(context, ref, reason: AuthReason.follow)) return;
    setState(() => _isFollowing = !_isFollowing);
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
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
              _FollowButton(isFollowing: _isFollowing, onTap: _toggleFollow),
            ],
          ),
          if (reel.caption.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            Text(reel.caption, maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textWhite)),
          ],
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowing, required this.onTap});

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s6,
        ),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : DesignTokens.primaryGreen,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          border: Border.all(
            color: isFollowing
                ? DesignTokens.textWhite
                : DesignTokens.primaryGreen,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: DesignTokens.smallRegular.copyWith(
            color: isFollowing
                ? DesignTokens.textWhite
                : DesignTokens.buttonPrimaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
