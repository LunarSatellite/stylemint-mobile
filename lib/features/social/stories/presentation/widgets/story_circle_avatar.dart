import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class StoryCircleAvatar extends StatelessWidget {
  const StoryCircleAvatar({
    required this.userName,
    required this.avatarUrl,
    required this.hasUnwatched,
    required this.isMyStory,
    required this.onTap,
    super.key,
  });

  final String userName;
  final String avatarUrl;
  final bool hasUnwatched;
  final bool isMyStory;
  final VoidCallback onTap;

  static const double _avatarSize = 64;
  static const double _ringWidth = 3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isMyStory
                ? _MyStoryPlaceholder(onTap: onTap)
                : Container(
                    width: _avatarSize + _ringWidth * 4,
                    height: _avatarSize + _ringWidth * 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          hasUnwatched
                              ? const LinearGradient(
                                  colors: [
                                    DesignTokens.primaryGreen,
                                    DesignTokens.secondaryYellow,
                                    DesignTokens.colorError,
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    DesignTokens.borderDefault,
                                    DesignTokens.borderDefault,
                                  ],
                                ),
                    ),
                    padding: const EdgeInsets.all(_ringWidth),
                    child: CircleAvatar(
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      backgroundImage:
                          avatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(avatarUrl)
                              : null,
                      child:
                          avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: DesignTokens.iconLight,
                                )
                              : null,
                    ),
                  ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyStoryPlaceholder extends StatelessWidget {
  const _MyStoryPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StoryCircleAvatar._avatarSize + StoryCircleAvatar._ringWidth * 4,
      height: StoryCircleAvatar._avatarSize + StoryCircleAvatar._ringWidth * 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.bgAppBodyLight,
        border: Border.all(
          color: DesignTokens.borderDefault,
          width: StoryCircleAvatar._ringWidth,
        ),
      ),
      child: const Center(
        child: Icon(Icons.add, color: DesignTokens.iconLight, size: 28),
      ),
    );
  }
}
