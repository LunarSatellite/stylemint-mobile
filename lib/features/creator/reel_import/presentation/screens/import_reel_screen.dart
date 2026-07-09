import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/importable_reel_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportReelScreen extends ConsumerStatefulWidget {
  const ImportReelScreen({super.key});

  @override
  ConsumerState<ImportReelScreen> createState() => _ImportReelScreenState();
}

class _ImportReelScreenState extends ConsumerState<ImportReelScreen> {
  SocialPlatform _selectedPlatform = SocialPlatform.instagram;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref
            .read(reelImportNotifierProvider.notifier)
            .load(_selectedPlatform),
      );
    });
  }

  void _onPlatformChanged(SocialPlatform platform) {
    if (platform == _selectedPlatform) return;
    setState(() => _selectedPlatform = platform);
    unawaited(
      ref.read(reelImportNotifierProvider.notifier).load(platform),
    );
  }

  void _onReelTapped(ImportableReel reel) {
    final route = RouteNames.reelImportTagProducts
        .replaceFirst(':postId', reel.platformPostId);
    unawaited(context.push(route, extra: reel));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelImportNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Import Reel', style: DesignTokens.titleMedium),
      ),
      body: Column(
        children: [
          // ── Platform selector ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, DesignTokens.s12,
              DesignTokens.s16, DesignTokens.s4,
            ),
            child: Row(
              children: SocialPlatform.values.map((platform) {
                final isLast = platform == SocialPlatform.values.last;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: isLast ? 0 : DesignTokens.s8,
                    ),
                    child: _PlatformTile(
                      platform: platform,
                      isSelected: platform == _selectedPlatform,
                      onTap: () => _onPlatformChanged(platform),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: state.when(
              initial: () => const SizedBox.shrink(),
              loadInProgress: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              loadSuccess: (reels) {
                if (reels.isEmpty) {
                  return _EmptyState(
                    platform: _selectedPlatform,
                    onPasteUrl: () =>
                        context.push(RouteNames.reelImportPreview),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s12,
                    DesignTokens.s16,
                    DesignTokens.s32,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: DesignTokens.s8,
                    mainAxisSpacing: DesignTokens.s8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: reels.length,
                  itemBuilder: (_, i) => ImportableReelCard(
                    reel: reels[i],
                    onTap: () => _onReelTapped(reels[i]),
                  ),
                );
              },
              loadFailure: (_) => _ErrorState(
                onRetry: () => unawaited(
                  ref
                      .read(reelImportNotifierProvider.notifier)
                      .load(_selectedPlatform),
                ),
              ),
            ),
          ),

          // ── Paste URL fallback ───────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: GestureDetector(
                onTap: () => context.push(RouteNames.reelImportPreview),
                child: Text(
                  "Can't see your posts? Paste a URL instead",
                  textAlign: TextAlign.center,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    decoration: TextDecoration.underline,
                    decorationColor: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Platform tile ────────────────────────────────────────────────────────────

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({
    required this.platform,
    required this.isSelected,
    required this.onTap,
  });

  final SocialPlatform platform;
  final bool isSelected;
  final VoidCallback onTap;

  static const Map<SocialPlatform, String> _svgAssets = {
    SocialPlatform.instagram: 'assets/icons/instagram.svg',
    SocialPlatform.tiktok: 'assets/icons/tiktok.svg',
    SocialPlatform.youtube: 'assets/icons/youtube.svg',
    SocialPlatform.facebook: 'assets/icons/facebook.svg',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              border: Border.all(
                color: isSelected
                    ? DesignTokens.primaryGreen
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  _svgAssets[platform]!,
                  width: 36,
                  height: 36,
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  platform.displayName,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (isSelected)
            Positioned(
              top: -9,
              right: -9,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: DesignTokens.bgAppBody,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.platform, required this.onPasteUrl});

  final SocialPlatform platform;
  final VoidCallback onPasteUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.video_library_outlined,
              size: 56,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'No posts found on ${platform.displayName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Make sure your account is connected and has published posts.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            TextButton(
              onPressed: onPasteUrl,
              child: Text(
                'Paste a URL instead',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  decoration: TextDecoration.underline,
                  decorationColor: DesignTokens.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: DesignTokens.s16),
            const Text(
              'Could not load your posts',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Check your connection and make sure your '
              'social account is connected.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            ElevatedButton(
              onPressed: onRetry,
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
