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
                DesignTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small player at the top, matches the image proportion.
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.42,
                        height: MediaQuery.of(context).size.width * 0.62,
                        child: ReelPlayer(
                          reel: reel,
                          isActive: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // Reel info card (profile + caption + URL + badge + stats).
                  _ReelInfoCard(reel: reel),
                  const SizedBox(height: DesignTokens.s16),

                  // Caption input (no internal border, blends with card).
                  Container(
                    decoration: DesignTokens.cardDecoration(),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 4,
                      minLines: 4,
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
                        enabledBorder: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                          borderSide: const BorderSide(
                            color: DesignTokens.primaryGreen,
                            width: 1.5,
                          ),
                        ),
                        disabledBorder: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.all(DesignTokens.s16),
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
              child: ElevatedButton(
                onPressed: () {
                  context.push(
                    RouteNames.reelImportTagProducts.replaceFirst(':postId', reel.platformPostId),
                    extra: reel.copyWith(caption: _captionController.text),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.textWhite,
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
      padding: const EdgeInsets.all(DesignTokens.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PlatformCircleIcon(platform: reel.platform),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.caption.isNotEmpty
                          ? reel.caption
                          : '${reel.platform.displayName} Reel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    if (reel.sourceUrl.isNotEmpty)
                      Text(
                        reel.sourceUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: DesignTokens.s8),
                    const _SuccessBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Divider between header and stats row.
          Divider(
            color: DesignTokens.borderDefault,
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: DesignTokens.s12),
          _StatsRow(
            likeCount: reel.likeCount,
            viewCount: reel.viewCount,
            bookmarkCount: reel.bookmarkCount,
            shareCount: reel.shareCount,
            commentCount: reel.commentCount,
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.likeCount,
    required this.viewCount,
    required this.bookmarkCount,
    required this.shareCount,
    required this.commentCount,
  });

  final int likeCount;
  final int viewCount;
  final int bookmarkCount;
  final int shareCount;
  final int commentCount;

  @override
  Widget build(BuildContext context) {
    final entries = <_StatEntry>[
      _StatEntry(
        icon: Icons.favorite_rounded,
        value: likeCount,
      ),
      _StatEntry(
        icon: Icons.visibility_rounded,
        value: viewCount,
      ),
      _StatEntry(
        icon: Icons.bookmark_rounded,
        value: bookmarkCount,
      ),
      _StatEntry(
        icon: Icons.send_rounded,
        value: shareCount,
      ),
      _StatEntry(
        icon: Icons.chat_bubble_rounded,
        value: commentCount,
      ),
    ];

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            _StatItem(entry: entries[i]),
            if (i < entries.length - 1)
              const SizedBox(width: DesignTokens.s40),
          ],
        ],
      ),
    );
  }
}

class _StatEntry {
  const _StatEntry({required this.icon, required this.value});
  final IconData icon;
  final int value;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.entry});
  final _StatEntry entry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          entry.icon,
          size: 24,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(height: 6),
        Text(
          _formatCount(entry.value),
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

String _formatCount(int value) {
  if (value <= 0) return '0';
  if (value < 1000) return value.toString();
  if (value < 1000000) {
    final k = value / 1000.0;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
  }
  final m = value / 1000000.0;
  return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
}

// Platform circle icon (light grey bg, all platforms same color).
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
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.inputFieldBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SvgPicture.asset(
          _svgAssets[platform]!,
          fit: BoxFit.contain,
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