import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Top Creators" card: avatar, name/handle, follow toggle, category,
/// description, rating + followers.
class DiscoverCreatorCard extends StatefulWidget {
  const DiscoverCreatorCard({required this.creator, super.key});

  final DiscoverCreator creator;

  @override
  State<DiscoverCreatorCard> createState() => _DiscoverCreatorCardState();
}

class _DiscoverCreatorCardState extends State<DiscoverCreatorCard> {
  late bool _isFollowing = widget.creator.isFollowing;

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    // TODO(discovery): call follow/unfollow via a Riverpod notifier.
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.creator;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: DesignTokens.avatarMedium / 2,
                backgroundColor: DesignTokens.bgAppBodyLight,
                backgroundImage:
                    c.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(c.avatarUrl)
                        : null,
                child:
                    c.avatarUrl.isEmpty
                        ? const Icon(
                          Icons.person,
                          color: DesignTokens.iconLight,
                        )
                        : null,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    Text(
                      c.handle,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _FollowButton(isFollowing: _isFollowing, onTap: _toggleFollow),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          if (c.category.isNotEmpty)
            Text(
              c.category,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              c.description,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: DesignTokens.iconSmall,
                color: DesignTokens.secondaryYellow,
              ),
              const SizedBox(width: DesignTokens.s4),
              Text(
                '${c.rating.toStringAsFixed(1)} Stars',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              const Icon(
                Icons.person_outline_rounded,
                size: DesignTokens.iconSmall,
                color: DesignTokens.iconLight,
              ),
              const SizedBox(width: DesignTokens.s4),
              Text(
                '${_compact(c.followers)} Followers',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
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
          color:
              isFollowing
                  ? DesignTokens.textWhite
                  : DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: DesignTokens.smallRegular.copyWith(
            color: isFollowing ? DesignTokens.textDark : DesignTokens.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

String _compact(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}
