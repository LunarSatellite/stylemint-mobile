import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Display info handed to [CreatorProfileScreen] via go_router `extra`.
class CreatorProfileArgs {
  const CreatorProfileArgs({
    required this.accountId,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
  });

  final String accountId;
  final String displayName;
  final String handle;
  final String? avatarUrl;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class CreatorProfileScreen extends ConsumerStatefulWidget {
  const CreatorProfileScreen({required this.args, super.key});
  final CreatorProfileArgs args;

  @override
  ConsumerState<CreatorProfileScreen> createState() =>
      _CreatorProfileScreenState();
}

// ── Arc painter (green arc around avatar, gap at bottom) ──────────────────────

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = DesignTokens.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    // Start at 7 o'clock (120° from 3 o'clock), sweep 300°, gap at bottom
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 2 / 3,
      math.pi * 5 / 3,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Data models ───────────────────────────────────────────────────────────────

class _ReelItem {
  const _ReelItem(this.imagePath, this.duration);
  final String imagePath;
  final String duration;
}

class _BrandDot {
  const _BrandDot(this.badgePath);
  final String badgePath;
}

// ── State ─────────────────────────────────────────────────────────────────────

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  bool _expanded = false;
  int _reelFilter = 1;

  static const _allBadges = [
    'assets/images/profile_badges/diamond_badge.png',
    'assets/images/profile_badges/red_badge.png',
    'assets/images/profile_badges/golden_badge.png',
    'assets/images/profile_badges/silver_badge.png',
    'assets/images/profile_badges/badge_5.png',
    'assets/images/profile_badges/badge_6.png',
    'assets/images/profile_badges/badge_7.png',
  ];

  void _showBadgesSheet() {
    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BadgesSheet(badges: _allBadges),
    ));
  }

  static const _tagEmojis = [
    '🚀', '🏃', '🎯', '⚡', '📱', '⚽', '💪', '🍕',
    '🌟', '🔥', '🏆', '✨',
  ];

  // All visible tags: achievement tags + partner labels
  static const _partnerLabels = [
    'Nike Creator', 'FastPaced', 'Gadget Obsessed',
    'Football Lover', 'Fitness Monster', 'Foodie',
  ];

  void _showTagsSheet(List<String> achievementTags) {
    final combined = <String>[
      ...achievementTags,
      ..._partnerLabels.where((p) => !achievementTags.contains(p)),
    ];
    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagsSheet(tags: combined, emojis: _tagEmojis),
    ));
  }

  static const _reels = <_ReelItem>[
    _ReelItem('assets/images/product_nike_air_jordan.png', '00:47'),
    _ReelItem('assets/images/sample_shoe1.png', '1:20'),
    _ReelItem('assets/images/attachment_3.png', '00:20'),
    _ReelItem('assets/images/sample_shoe2.png', '00:58'),
    _ReelItem('assets/images/attachment_1.png', '00:35'),
    _ReelItem('assets/images/product_nike_air_max.png', '00:47'),
  ];

  static const _brands = <_BrandDot>[
    _BrandDot('assets/images/profile_badges/diamond_badge.png'),
    _BrandDot('assets/images/profile_badges/golden_badge.png'),
    _BrandDot('assets/images/profile_badges/red_badge.png'),
    _BrandDot('assets/images/profile_badges/silver_badge.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final profileData = ref.watch(creatorProfileEditProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      bottomNavigationBar: const _BottomNav(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _topBar(),
                    const SizedBox(height: DesignTokens.s12),
                    _avatarSection(),
                    const SizedBox(height: DesignTokens.s12),
                    _nameRow(profileData),
                    const SizedBox(height: 4),
                    _handleText(),
                    const SizedBox(height: DesignTokens.s12),
                    _achievementChips(profileData),
                    const SizedBox(height: DesignTokens.s8),
                    _partnerChips(profileData),
                    const SizedBox(height: DesignTokens.s16),
                    _brandLogosRow(),
                    const SizedBox(height: DesignTokens.s16),
                    _statsRow(),
                    const SizedBox(height: DesignTokens.s8),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.s20),
              _socialPlatforms(),
              const SizedBox(height: DesignTokens.s20),
              _aboutMe(profileData),
              const SizedBox(height: DesignTokens.s20),
              _categoryNiche(profileData),
              const SizedBox(height: DesignTokens.s20),
              _reelsSection(),
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
      child: Row(
        children: [
          if (context.canPop())
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: DesignTokens.textWhite),
            ),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              color: DesignTokens.textWhite, size: 22),
          const SizedBox(width: DesignTokens.s16),
          GestureDetector(
            onTap: () => context.push(
              RouteNames.creatorProfileSettings,
              extra: CreatorProfileArgs(
                accountId: widget.args.accountId,
                displayName: widget.args.displayName,
                handle: widget.args.handle,
                avatarUrl: widget.args.avatarUrl,
              ),
            ),
            child: const Icon(Icons.settings_outlined,
                color: DesignTokens.textWhite, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _avatarSection() {
    final localPath = ref.watch(avatarImagePathProvider);
    final url = widget.args.avatarUrl;
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: const Size(124, 124), painter: _ArcPainter()),
          ClipOval(
            child: SizedBox(
              width: 100,
              height: 100,
              child: localPath != null
                  ? Image.file(File(localPath), fit: BoxFit.cover)
                  : (url != null && url.isNotEmpty)
                      ? Image.network(url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, _e) => _avatarFallback())
                      : _avatarFallback(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: DesignTokens.bgAppBodyLight,
        alignment: Alignment.center,
        child: const Icon(Icons.person,
            size: 40, color: DesignTokens.iconLight),
      );

  Widget _nameRow(CreatorProfileEditData profileData) {
    final name = profileData.displayName.isNotEmpty
        ? profileData.displayName
        : (widget.args.displayName.isNotEmpty ? widget.args.displayName : 'Danny Perierra');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(width: 6),
        Image.asset(
          'assets/images/ph_seal-check-fill.png',
          width: 22,
          height: 22,
          fit: BoxFit.contain,
          errorBuilder: (_, __, _e) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _handleText() {
    final h = widget.args.handle.isNotEmpty
        ? widget.args.handle
        : '@wandererperierra';
    return Text(
      h.startsWith('@') ? h : '@$h',
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 13,
        color: DesignTokens.primaryGreen,
      ),
    );
  }

  Widget _achievementChips(CreatorProfileEditData profileData) {
    if (profileData.tags.isEmpty) return const SizedBox.shrink();
    const emojis = ['🏆', '🏃', '🌟', '🎯', '💪', '🔥'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: List.generate(profileData.tags.length, (i) {
          return Padding(
            padding: EdgeInsets.only(
                right: i < profileData.tags.length - 1 ? DesignTokens.s8 : 0),
            child: _AchievementChip(
              emoji: emojis[i % emojis.length],
              label: profileData.tags[i],
              bg: i == 0 ? const Color(0xFF3A2F00) : DesignTokens.bgAppBodyLight,
              onTap: () => _showTagsSheet(profileData.tags),
            ),
          );
        }),
      ),
    );
  }

  Widget _partnerChips(CreatorProfileEditData profileData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: [
          const _PartnerChip(
              color: Color(0xFFCC0000), label: 'Nike Creator', initial: 'N'),
          const SizedBox(width: DesignTokens.s8),
          const _PartnerChip(
              color: Color(0xFF1565C0), label: 'FastPaced', initial: 'F'),
          const SizedBox(width: DesignTokens.s8),
          GestureDetector(
            onTap: () => _showTagsSheet(profileData.tags),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius:
                    BorderRadius.circular(DesignTokens.chipRadius),
              ),
              child: const Text(
                '+3 more',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandLogosRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ..._brands.map(
            (b) => GestureDetector(
              onTap: _showBadgesSheet,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  b.badgePath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, _e) => Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: DesignTokens.bgAppBodyLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showBadgesSheet,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '+3',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          const _StatItem(value: '435k', label: 'Followers'),
          _vDivider(),
          const _StatItem(value: '234', label: 'Partnership'),
          _vDivider(),
          const _StatItem(value: '212', label: 'Reels'),
          _vDivider(),
          const _StatItem(value: '412k', label: 'Likes'),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: DesignTokens.borderDefault);

  Widget _socialPlatforms() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SocialIcon(svgPath: 'assets/icons/youtube.svg'),
          const SizedBox(width: DesignTokens.s12),
          const _SocialIcon(svgPath: 'assets/icons/instagram.svg'),
          const SizedBox(width: DesignTokens.s12),
          const _SocialIcon(svgPath: 'assets/icons/facebook.svg', warning: true),
          const SizedBox(width: DesignTokens.s12),
          const _SocialIcon(svgPath: 'assets/icons/tiktok.svg'),
        ],
      ),
    );
  }

  Widget _aboutMe(CreatorProfileEditData profileData) {
    const truncateAt = 120;
    final fullBio = profileData.bio;
    final needsTruncation = fullBio.length > truncateAt;
    final truncated = needsTruncation ? fullBio.substring(0, truncateAt) : fullBio;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Me',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          if (_expanded || !needsTruncation)
            Text(
              fullBio,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                color: DesignTokens.textMuted,
                height: 1.5,
              ),
            )
          else
            Text.rich(
              TextSpan(
                text: truncated,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.textMuted,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: '... '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => setState(() => _expanded = true),
                      child: const Text(
                        'Read More',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryNiche(CreatorProfileEditData profileData) {
    if (profileData.niches.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Niche',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: profileData.niches
                .map((niche) => _NicheChip(
                      svgPath: 'assets/images/interests/$niche.svg',
                      label: niche,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _reelsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'Reels',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
              Spacer(),
              Icon(Icons.search_rounded,
                  color: DesignTokens.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              _FilterTab(
                label: 'Oldest',
                selected: _reelFilter == 0,
                onTap: () => setState(() => _reelFilter = 0),
              ),
              const SizedBox(width: DesignTokens.s8),
              _FilterTab(
                label: 'Latest',
                selected: _reelFilter == 1,
                onTap: () => setState(() => _reelFilter = 1),
              ),
              const SizedBox(width: DesignTokens.s8),
              _FilterTab(
                label: 'Most Popular',
                selected: _reelFilter == 2,
                onTap: () => setState(() => _reelFilter = 2),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: DesignTokens.s8,
            crossAxisSpacing: DesignTokens.s8,
            childAspectRatio: 0.78,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: _reels.map((r) => _ReelCard(reel: r)).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _AchievementChip extends StatelessWidget {
  const _AchievementChip({
    required this.emoji,
    required this.label,
    required this.bg,
    this.onTap,
  });
  final String emoji;
  final String label;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip(
      {required this.color, required this.label, required this.initial});
  final Color color;
  final String label;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: DesignTokens.fontFamily,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              color: DesignTokens.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.svgPath, this.warning = false});
  final String svgPath;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppFoundation,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: SvgPicture.asset(svgPath, fit: BoxFit.contain),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: warning
                  ? const Color(0xFFFFAA00)
                  : DesignTokens.primaryGreen,
              shape: BoxShape.circle,
              border:
                  Border.all(color: DesignTokens.bgAppFoundation, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Icon(
              warning ? Icons.priority_high_rounded : Icons.check_rounded,
              color: Colors.white,
              size: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _NicheChip extends StatelessWidget {
  const _NicheChip({required this.svgPath, required this.label});
  final String svgPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
                DesignTokens.textLight, BlendMode.srcIn),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.primaryGreenLight
              : DesignTokens.bgAppFoundation,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(
            color: selected
                ? DesignTokens.chipsSelectedBorder
                : DesignTokens.borderDefault,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

class _ReelCard extends StatelessWidget {
  const _ReelCard({required this.reel});
  final _ReelItem reel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            reel.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, _e) => Container(
              color: DesignTokens.bgAppBodyLight,
              alignment: Alignment.center,
              child: const Icon(Icons.play_circle_outline,
                  color: DesignTokens.textMuted, size: 32),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 40,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 8,
            child: Text(
              reel.duration,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badges bottom sheet ───────────────────────────────────────────────────────

class _BadgesSheet extends StatelessWidget {
  const _BadgesSheet({required this.badges});
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Row(
            children: [
              const Text(
                'Your Badges',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close_rounded,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: badges.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: DesignTokens.s12,
              crossAxisSpacing: DesignTokens.s12,
            ),
            itemBuilder: (_, i) => _BadgeDisplayTile(asset: badges[i]),
          ),
        ],
      ),
    );
  }
}

class _BadgeDisplayTile extends StatelessWidget {
  const _BadgeDisplayTile({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(
          Icons.verified_outlined,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}

// ── Tags bottom sheet ─────────────────────────────────────────────────────────

class _TagsSheet extends StatelessWidget {
  const _TagsSheet({required this.tags, required this.emojis});
  final List<String> tags;
  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Row(
            children: [
              const Text(
                'Your Tags',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.close_rounded,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: List.generate(tags.length, (i) {
              return _SheetTagChip(
                emoji: emojis[i % emojis.length],
                label: tags[i],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SheetTagChip extends StatelessWidget {
  const _SheetTagChip({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => context.canPop() ? context.pop() : null,
          ),
          _NavBtn(
            icon: Icons.auto_graph_rounded,
            label: 'Analytics',
            onTap: () => context.push(RouteNames.creatorAnalytics),
          ),
          _NavBtn(
            icon: Icons.explore_outlined,
            label: 'Explore',
            onTap: () {},
          ),
          const _NavBtn(
            icon: Icons.person_rounded,
            label: 'Profile',
            active: true,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? DesignTokens.primaryGreen : DesignTokens.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
