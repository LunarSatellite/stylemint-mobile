import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PreviewReelScreen extends StatefulWidget {
  const PreviewReelScreen({super.key, required this.reel});

  final ImportableReel reel;

  @override
  State<PreviewReelScreen> createState() => _PreviewReelScreenState();
}

class _PreviewReelScreenState extends State<PreviewReelScreen> {
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Preview Your Reel', style: DesignTokens.titleMedium),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform-aware player. Switches between mp4 (Instagram),
                  // YouTube IFrame, and an external-app launcher for TikTok /
                  // Facebook. See [ReelPlayer] for the full matrix.
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.65,
                        height: MediaQuery.of(context).size.width * 0.85,
                        child: ReelPlayer(
                          reel: reel,
                          isActive: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // Reel info card
                  _ReelInfoCard(reel: reel),
                  const SizedBox(height: DesignTokens.s16),

                  // Caption input
                  Container(
                    height: 160,
                    decoration: DesignTokens.cardDecoration(),
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    child: TextField(
                      controller: _captionController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a Caption (Optional)',
                        hintStyle: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(top: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            color: DesignTokens.bgAppFoundation,
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  final updatedReel = reel.copyWith(
                    caption: _captionController.text,
                  );
                  unawaited(context.push(
                    RouteNames.reelImportTagProducts
                        .replaceFirst(':postId', updatedReel.platformPostId),
                    extra: updatedReel,
                  ));
                },
                style: DesignTokens.primaryButtonStyle(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue to Tag Products'),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelInfoCard extends StatelessWidget {
  const _ReelInfoCard({required this.reel});

  final ImportableReel reel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PlatformCircleIcon(platform: reel.platform),
              const SizedBox(width: DesignTokens.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${reel.platform.displayName} Reel',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    if (reel.caption.isNotEmpty)
                      Text(
                        reel.caption,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        reel.sourceUrl,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: DesignTokens.s8),
                    const _SuccessBadge(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Platform circle icon
class _PlatformCircleIcon extends StatelessWidget {
  const _PlatformCircleIcon({required this.platform});

  final SocialPlatform platform;

  static const _svgAssets = {
    SocialPlatform.instagram: 'assets/icons/instagram.svg',
    SocialPlatform.tiktok: 'assets/icons/tiktok.svg',
    SocialPlatform.youtube: 'assets/icons/youtube.svg',
    SocialPlatform.facebook: 'assets/icons/facebook.svg',
  };

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 50,
        height: 50,
        child: SvgPicture.asset(
          _svgAssets[platform]!,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// Success badge
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF166534),
          ),
          const SizedBox(width: DesignTokens.s6),
          Text(
            'Successfully Imported',
            style: DesignTokens.smallRegular.copyWith(
              color: const Color(0xFF166534),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
