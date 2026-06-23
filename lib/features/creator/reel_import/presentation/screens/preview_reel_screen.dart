import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PreviewReelScreen extends StatefulWidget {
  const PreviewReelScreen({
    super.key,
    required this.url,
    required this.platform,
  });

  final String url;
  final SocialPlatform platform;

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
                  // ── Video thumbnail ────────────────────────────────────
                  Center(child: _VideoThumbnail()),
                  const SizedBox(height: DesignTokens.s16),

                  // ── Reel info card ─────────────────────────────────────
                  _ReelInfoCard(
                    url: widget.url,
                    platform: widget.platform,
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // ── Caption input ──────────────────────────────────────
                  Container(
                    height: 160,
                    decoration: DesignTokens.cardDecoration(),
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    child: TextField(
                      controller: _captionController,
                      maxLines: null,
                      expands: true,
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
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Continue button ────────────────────────────────────────────
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
                  final reel = ImportableReel(
                    id: 'preview-post',
                    platform: widget.platform,
                    platformPostId: 'preview-post',
                    sourceUrl: widget.url,
                    thumbnailUrl: '',
                    caption: _captionController.text,
                    createdAt: DateTime.now(),
                    videoDuration: 55,
                  );
                  context.push(
                    RouteNames.reelImportTagProducts
                        .replaceFirst(':postId', 'preview-post'),
                    extra: reel,
                  );
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

// ── Video thumbnail ───────────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.60;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Placeholder background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A1A0A), Color(0xFF0D0D1A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Subtle grid texture
            Opacity(
              opacity: 0.08,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                ),
                itemBuilder: (_, _i) => Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            // Duration badge
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '0:43 / 0:55',
                  style: DesignTokens.smallRegular.copyWith(
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reel info card ────────────────────────────────────────────────────────────

class _ReelInfoCard extends StatelessWidget {
  const _ReelInfoCard({required this.url, required this.platform});

  final String url;
  final SocialPlatform platform;

  static const _stats = [
    (Icons.favorite_rounded, '23.8k'),
    (Icons.visibility_outlined, '465k'),
    (Icons.bookmark_border_rounded, '1.8k'),
    (Icons.share_outlined, '13.67k'),
    (Icons.chat_bubble_outline_rounded, '976'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlatformCircleIcon(platform: platform),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delicious Chocolate Cakes for Birthdays',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textWhite,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      url,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    _SuccessBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          const SizedBox(height: DesignTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _stats
                .map(
                  (s) => Column(
                    children: [
                      Icon(s.$1, size: 20, color: DesignTokens.textLight),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        s.$2,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Platform circle icon ──────────────────────────────────────────────────────

class _PlatformCircleIcon extends StatelessWidget {
  const _PlatformCircleIcon({required this.platform});

  final SocialPlatform platform;

  @override
  Widget build(BuildContext context) {
    switch (platform) {
      case SocialPlatform.instagram:
        return Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 20,
          ),
        );
      case SocialPlatform.youtube:
        return Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFFF0000),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 22,
          ),
        );
      case SocialPlatform.tiktok:
        return Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF010101),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: 18,
          ),
        );
      case SocialPlatform.facebook:
        return Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF1877F2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    }
  }
}

// ── Success badge ─────────────────────────────────────────────────────────────

class _SuccessBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(width: DesignTokens.s4),
          Text(
            'Successfully Imported',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
