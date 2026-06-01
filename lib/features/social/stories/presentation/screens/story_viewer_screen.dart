import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({
    required this.userId,
    required this.stories,
    super.key,
  });

  final String userId;
  final List<Story> stories;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _animController;
  Timer? _autoAdvanceTimer;
  int _currentIndex = 0;

  List<Story> get _stories => widget.stories;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _animController.addStatusListener(_onAnimStatus);
    _startAutoAdvance();
    _markViewed(0);
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _animController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goNext();
    }
  }

  void _startAutoAdvance() {
    _animController.reset();
    _animController.forward();
  }

  void _markViewed(int index) {
    if (index < _stories.length) {
      ref.read(storiesNotifierProvider.notifier).viewStory(
        _stories[index].id,
      );
    }
  }

  void _goNext() {
    if (_currentIndex < _stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < screenWidth / 2) {
          _goPrev();
        } else {
          _goNext();
        }
      },
      onLongPressStart: (_) => _animController.stop(),
      onLongPressEnd: (_) => _startAutoAdvance(),
      child: Scaffold(
        backgroundColor: DesignTokens.baseBlack,
        body: SafeArea(
          child: Stack(
            children: [
              // Progress bar
              Positioned(
                top: 0,
                left: DesignTokens.s8,
                right: DesignTokens.s8,
                child: Row(
                  children: List.generate(_stories.length, (i) {
                    return Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Story page view
              PageView.builder(
                controller: _pageController,
                itemCount: _stories.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _markViewed(index);
                  _startAutoAdvance();
                },
                itemBuilder: (_, i) => _storyContent(_stories[i]),
              ),

              // User header
              Positioned(
                top: DesignTokens.s12,
                left: DesignTokens.s12,
                right: DesignTokens.s12,
                child: _StoryHeader(
                  story: _stories[_currentIndex],
                  onClose: () => Navigator.of(context).pop(),
                ),
              ),

              // Tagged products overlay
              if (_stories[_currentIndex].taggedProductIds.isNotEmpty)
                Positioned(
                  bottom: DesignTokens.s40,
                  left: DesignTokens.s16,
                  right: DesignTokens.s16,
                  child: _TaggedProductBar(
                    productIds: _stories[_currentIndex].taggedProductIds,
                  ),
                ),

              // Caption
              if (_stories[_currentIndex].caption != null &&
                  _stories[_currentIndex].caption!.isNotEmpty)
                Positioned(
                  bottom: DesignTokens.s8,
                  left: DesignTokens.s16,
                  right: DesignTokens.s16,
                  child: Text(
                    _stories[_currentIndex].caption!,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storyContent(Story story) {
    if (story.mediaType == 'video') {
      return Center(
        child: CachedNetworkImage(
          imageUrl: story.mediaUrl,
          fit: BoxFit.contain,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
          ),
          errorWidget: (_, __, ___) => const Icon(
            Icons.broken_image,
            color: DesignTokens.iconLight,
            size: 64,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      ),
      errorWidget: (_, __, ___) => const Icon(
        Icons.broken_image,
        color: DesignTokens.iconLight,
        size: 64,
      ),
    );
  }
}

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({required this.story, required this.onClose});

  final Story story;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: DesignTokens.avatarSmall / 2,
          backgroundColor: DesignTokens.bgAppBodyLight,
          backgroundImage:
              story.userAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(story.userAvatarUrl)
                  : null,
          child:
              story.userAvatarUrl.isEmpty
                  ? const Icon(Icons.person, color: DesignTokens.iconLight, size: DesignTokens.iconSmall)
                  : null,
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Text(
            story.userName,
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        GestureDetector(
          onTap: onClose,
          child: const Icon(
            Icons.close,
            color: DesignTokens.iconWhite,
            size: DesignTokens.iconMedium,
          ),
        ),
      ],
    );
  }
}

class _TaggedProductBar extends StatelessWidget {
  const _TaggedProductBar({required this.productIds});

  final List<String> productIds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: DesignTokens.primaryGreen,
            size: DesignTokens.iconSmall,
          ),
          const SizedBox(width: DesignTokens.s8),
          Text(
            '${productIds.length} product${productIds.length != 1 ? 's' : ''} tagged',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          const Spacer(),
          Text(
            'Swipe up',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
