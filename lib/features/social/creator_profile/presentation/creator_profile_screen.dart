import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart' as reels_providers;
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/notifiers/creator_profile_notifier.dart';
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

// ── State ─────────────────────────────────────────────────────────────────────

class _CreatorProfileScreenState extends ConsumerState<CreatorProfileScreen> {
  bool _expanded = false;
  int _reelFilter = 1;

  void _showBadgesSheet() {
    final showcased = ref.read(showcasedBadgesProvider);
    if (showcased.isEmpty) return;
    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BadgesSheet(badges: showcased),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = ref.watch(sessionControllerProvider)
        .maybeWhen(authenticated: (id) => id, orElse: () => '');
    final effectiveAccountId =
        widget.args.accountId.isNotEmpty ? widget.args.accountId : sessionId;

    ref.listen<CreatorProfileState>(
      creatorProfileNotifierProvider(effectiveAccountId),
      (_, next) {
        next.maybeWhen(
          loadSuccess: (profile) =>
              ref.read(creatorProfileEditProvider.notifier).seed(profile),
          orElse: () {},
        );
      },
    );

    final profileData = ref.watch(creatorProfileEditProvider);
    final CreatorProfile? loadedProfile = ref
        .watch(creatorProfileNotifierProvider(effectiveAccountId))
        .maybeWhen<CreatorProfile?>(
          loadSuccess: (p) => p,
          orElse: () => null,
        );

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
                    _topBar(effectiveAccountId, loadedProfile),
                    const SizedBox(height: DesignTokens.s12),
                    _avatarSection(),
                    const SizedBox(height: DesignTokens.s12),
                    _nameRow(profileData, loadedProfile),
                    const SizedBox(height: 4),
                    _handleText(loadedProfile),
                    const SizedBox(height: DesignTokens.s12),
                    _achievementChips(profileData.tags),
                    const SizedBox(height: DesignTokens.s8),
                    _badgesRow(),
                    const SizedBox(height: DesignTokens.s8),
                    _partnerChips(),
                    const SizedBox(height: DesignTokens.s16),
                    _brandLogosRow(),
                    const SizedBox(height: DesignTokens.s16),
                    _statsRow(loadedProfile),
                    const SizedBox(height: DesignTokens.s8),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.s20),
              _socialPlatforms(),
              const SizedBox(height: DesignTokens.s20),
              _aboutMe(loadedProfile),
              const SizedBox(height: DesignTokens.s20),
              _categoryNiche(effectiveAccountId),
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

  Widget _topBar(String effectiveAccountId, CreatorProfile? loadedProfile) {
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
                accountId: effectiveAccountId,
                displayName: loadedProfile?.displayName ?? widget.args.displayName,
                handle: loadedProfile?.handle ?? widget.args.handle,
                avatarUrl: loadedProfile?.avatarUrl ?? widget.args.avatarUrl,
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

  Widget _nameRow(CreatorProfileEditData profileData, CreatorProfile? loaded) {
    final name = loaded?.displayName.isNotEmpty == true
        ? loaded!.displayName
        : (profileData.displayName.isNotEmpty
            ? profileData.displayName
            : (widget.args.displayName.isNotEmpty
                ? widget.args.displayName
                : 'Creator'));
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

  Widget _handleText(CreatorProfile? loaded) {
    final h = loaded?.handle.isNotEmpty == true
        ? loaded!.handle
        : (widget.args.handle.isNotEmpty ? widget.args.handle : '@handle');
    return Text(
      h.startsWith('@') ? h : '@$h',
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 13,
        color: DesignTokens.primaryGreen,
      ),
    );
  }

  Widget _achievementChips(List<String> tags) {
    if (tags.isEmpty) return const SizedBox.shrink();
    const emojis = ['🚀', '👟', '🌟', '🎯', '💪', '🔥'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: List.generate(tags.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s8),
            child: _AchievementChip(
              emoji: emojis[i % emojis.length],
              label: tags[i],
              bg: i == 0
                  ? const Color(0xFF3A2F00)
                  : DesignTokens.bgAppBodyLight,
            ),
          );
        }),
      ),
    );
  }

  Widget _badgesRow() {
    final showcased = ref.watch(showcasedBadgesProvider);
    if (showcased.isEmpty) return const SizedBox.shrink();

    const maxVisible = 4;
    final visible = showcased.take(maxVisible).toList();
    final overflow = showcased.length - maxVisible;

    return GestureDetector(
      onTap: _showBadgesSheet,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...visible.map(
              (badge) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: DesignTokens.s4),
                child: Image.network(
                  badge.badgeIconUrl,
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.verified_outlined,
                    color: DesignTokens.textMuted,
                    size: 36,
                  ),
                ),
              ),
            ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(left: DesignTokens.s4),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: DesignTokens.borderDefault),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+$overflow',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textLight,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _partnerChips() {
    final active = ref.watch(activePartnershipsProvider);

    if (active.isEmpty) return const SizedBox.shrink();

    const emojis = ['🎯', '⚡', '🌟', '💼', '🏆', '✨'];
    final visible = active.take(2).toList();
    final remaining = active.length - visible.length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: [
          ...visible.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: DesignTokens.s8),
                  child: _PartnerChip(
                    emoji: emojis[e.key % emojis.length],
                    label: e.value.vendorName,
                  ),
                ),
              ),
          if (remaining > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
              ),
              child: Text(
                '+$remaining more',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _brandLogosRow() {
    final active = ref.watch(activePartnershipsProvider);

    if (active.isEmpty) return const SizedBox.shrink();

    final visible = active.take(4).toList();
    final remaining = active.length - visible.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...visible.map(
            (p) => GestureDetector(
              onTap: _showBadgesSheet,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipOval(
                  child: Image.network(
                    p.vendorLogoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
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
          ),
          if (remaining > 0)
            GestureDetector(
              onTap: _showBadgesSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$remaining',
                  style: const TextStyle(
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

  Widget _statsRow(CreatorProfile? loaded) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          _StatItem(
            value: loaded != null ? _fmtCount(loaded.followersCount) : '—',
            label: 'Followers',
          ),
          _vDivider(),
          _StatItem(
            value: loaded != null ? _fmtCount(loaded.partnershipsCount) : '—',
            label: 'Partnership',
          ),
          _vDivider(),
          _StatItem(
            value: loaded != null ? _fmtCount(loaded.reelsCount) : '—',
            label: 'Reels',
          ),
          _vDivider(),
          _StatItem(
            value: loaded != null ? _fmtCount(loaded.likesCount) : '—',
            label: 'Likes',
          ),
        ],
      ),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
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

  Widget _aboutMe(CreatorProfile? loadedProfile) {
    const truncateAt = 120;
    final fullBio = loadedProfile?.bio ?? '';
    final needsTruncation = fullBio.length > truncateAt;
    final truncated = needsTruncation ? fullBio.substring(0, truncateAt) : fullBio;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: (_expanded || !needsTruncation)
                ? Text(
                    fullBio,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      color: DesignTokens.textMuted,
                      height: 1.5,
                    ),
                  )
                : Text.rich(
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
          ),
        ],
      ),
    );
  }

  Widget _categoryNiche(String accountId) {
    final nichesAsync = ref.watch(creatorNicheNamesProvider(accountId));
    return nichesAsync.maybeWhen(
      data: (niches) {
        if (niches.isEmpty) return const SizedBox.shrink();
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
              const SizedBox(height: DesignTokens.s8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignTokens.s16),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.cardRadius),
                ),
                child: Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: niches.map((n) => _NicheChip(label: n)).toList(),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _reelsSection() {
    final (sortBy, order) = switch (_reelFilter) {
      0 => ('publishedAt', 'asc'),
      2 => ('views', 'desc'),
      _ => ('publishedAt', 'desc'),
    };
    final reelsAsync = ref.watch(
      reels_providers.creatorReelSummariesProvider((sortBy, order)),
    );

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
          const SizedBox(height: DesignTokens.s8),
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
          reelsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.s20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (reels) => GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: DesignTokens.s8,
              crossAxisSpacing: DesignTokens.s8,
              childAspectRatio: 0.78,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: reels.map((r) => _ReelCard(reel: r)).toList(),
            ),
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
  });
  final String emoji;
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerChip extends StatelessWidget {
  const _PartnerChip({required this.emoji, required this.label});
  final String emoji;
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
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textMuted,
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
            color: DesignTokens.bgAppBodyLight,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(18),
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
  const _NicheChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          color: DesignTokens.textLight,
        ),
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
  final CreatorReelSummary reel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          reel.thumbnailUrl != null
              ? Image.network(
                  reel.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, _e) => _placeholder(),
                )
              : _placeholder(),
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
            child: Row(
              children: [
                const Icon(Icons.play_arrow_rounded,
                    size: 13, color: Colors.white),
                const SizedBox(width: 2),
                Text(
                  _fmtCount(reel.views),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: DesignTokens.bgAppBodyLight,
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_outline,
            color: DesignTokens.textMuted, size: 32),
      );

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}

// ── Badges bottom sheet ───────────────────────────────────────────────────────

class _BadgesSheet extends StatelessWidget {
  const _BadgesSheet({required this.badges});
  final List<BadgeAward> badges;

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
            itemBuilder: (_, i) => _BadgeDisplayTile(badge: badges[i]),
          ),
        ],
      ),
    );
  }
}

class _BadgeDisplayTile extends StatelessWidget {
  const _BadgeDisplayTile({required this.badge});
  final BadgeAward badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(10),
      child: Image.network(
        badge.badgeIconUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.verified_outlined,
          color: DesignTokens.textMuted,
        ),
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
      height: 68 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      child: SafeArea(
        top: false,
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
            iconWidget: Image.asset(
              'assets/images/creatordash/Analytics_icon.png',
              width: 22,
              height: 22,
            ),
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
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconWidget,
    this.active = false,
  });

  final IconData icon;
  final Widget? iconWidget;
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
            iconWidget ?? Icon(icon, size: 22, color: color),
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
