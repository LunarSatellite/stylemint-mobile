import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Creator row (avatar, name, track) with a Follow toggle, plus the caption.
/// Follow action requires authentication — tapping prompts sign-in if logged out.
class CreatorInfo extends ConsumerStatefulWidget {
  const CreatorInfo({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<CreatorInfo> createState() => _CreatorInfoState();
}

class _CreatorInfoState extends ConsumerState<CreatorInfo> {
  late bool _isFollowing = widget.reel.isCreatorFollowed ?? false;

  bool get _isAuthenticated {
    final session = ref.read(sessionControllerProvider);
    return session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
  }

  void _toggleFollow() {
    if (!_isAuthenticated) {
      showModalBottomSheet(
        context: context,
        backgroundColor: DesignTokens.bgAppBody,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.s24),
          ),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s24, DesignTokens.s24,
            DesignTokens.s24, DesignTokens.s32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              Text('Sign in to follow creators',
                  style: DesignTokens.titleMedium.copyWith(
                      color: DesignTokens.textWhite)),
              const SizedBox(height: DesignTokens.s8),
              Text('Follow your favorite creators to see their content.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textMuted)),
              const SizedBox(height: DesignTokens.s24),
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  style: DesignTokens.primaryButtonStyle(),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(RouteNames.signInMethod);
                  },
                  child: const Text('Sign In',
                      style: TextStyle(fontFamily: DesignTokens.fontFamily,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
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
