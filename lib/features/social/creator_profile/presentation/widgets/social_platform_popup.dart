import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/social_account_summary.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/youtube_channel.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Shows a half-cylinder bottom sheet with social platform details.
/// For YouTube (the only platform with a direct public API today),
/// fetches rich channel info via the YouTube Data API. Other platforms
/// show the existing SocialAccount fields until the BE adds the
/// /profile endpoint.
Future<void> showSocialPlatformPopup(
  BuildContext context, {
  required String platformId,
  required SocialAccountSummary? summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (_) => SocialPlatformPopup(
      platformId: platformId,
      summary: summary,
    ),
  );
}

class SocialPlatformPopup extends ConsumerWidget {
  const SocialPlatformPopup({
    super.key,
    required this.platformId,
    required this.summary,
  });

  final String platformId;
  final SocialAccountSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = kCreatorPlatforms.firstWhere(
      (p) => p.id == platformId,
      orElse: () => kCreatorPlatforms.first,
    );
    final isConnected = summary != null;
    final youtubeChannelId = platformId == 'youtube' ? summary?.providerUserId ?? '' : '';
    final AsyncValue<YouTubeChannel?> channelAsync =
        platformId == 'youtube' && isConnected
            ? ref.watch(youtubeChannelProvider(youtubeChannelId))
            : const AsyncValue<YouTubeChannel?>.data(null);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: DesignTokens.bgAppBody.withOpacity(0.92),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _grabber(context),
                  if (!isConnected)
                    _NotConnectedBody(platform: platform)
                  else
                    _ConnectedBody(
                      platform: platform,
                      summary: summary!,
                      channelAsync: channelAsync,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grabber(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: DesignTokens.borderDefault,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

// ── Not connected ──────────────────────────────────────────────────────────

class _NotConnectedBody extends ConsumerWidget {
  const _NotConnectedBody({required this.platform});
  final CreatorPlatformOption platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: DesignTokens.s24),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(18),
            child: SvgThumb(asset: platform.assetPath),
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            'You are not connected to ${platform.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          const Text(
            'Connect your account to showcase it on your creator profile.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: DesignTokens.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onConnect(context, ref),
              icon: const Icon(Icons.link_rounded, color: Colors.white),
              label: Text('Connect ${platform.name}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: platform.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    );
  }

  Future<void> _onConnect(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(socialConnectNotifierProvider.notifier);
    final plat = _slugToPlatform(platform.id);
    if (plat == null) return;
    await notifier.connect(plat);
    if (context.mounted) Navigator.of(context).pop();
    // Result is ignored here — the existing social-connect flow handles its own UI.
  }
}

// ── Connected ─────────────────────────────────────────────────────────────

class _ConnectedBody extends ConsumerWidget {
  const _ConnectedBody({
    required this.platform,
    required this.summary,
    required this.channelAsync,
  });

  final CreatorPlatformOption platform;
  final SocialAccountSummary summary;
  final AsyncValue<YouTubeChannel?> channelAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = channelAsync.maybeWhen(data: (c) => c, orElse: () => null);
    final title = channel?.title ?? summary.displayName ?? platform.name;
    final handle = channel?.handle ?? (summary.handle.isNotEmpty ? '@${summary.handle}' : '');
    final description = channel?.description ?? '';
    final avatarUrl = channel?.avatarUrl ?? summary.avatarUrl;
    final bannerUrl = channel?.bannerUrl ?? '';
    final subs = channel?.subscriberCount ?? summary.followerCount;
    final videos = channel?.videoCount ?? 0;
    final views = channel?.viewCount ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner with avatar overlay
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                image: bannerUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(bannerUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
            ),
            Positioned(
              top: 60,
              left: 24,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: DesignTokens.bgAppBody, width: 3),
                ),
                padding: const EdgeInsets.all(6),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              SvgThumb(asset: platform.assetPath),
                        )
                      : SvgThumb(asset: platform.assetPath),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                ),
              ),
              if (handle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  handle,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                _DescriptionBlock(text: description),
              ],
              const SizedBox(height: DesignTokens.s20),
              _StatsRow(subscribers: subs, videos: videos, views: views),
              const SizedBox(height: DesignTokens.s24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _onDisconnect(context, ref),
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.colorError,
                    side: BorderSide(color: DesignTokens.colorError.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _onDisconnect(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(socialConnectNotifierProvider.notifier);
    final plat = _slugToPlatform(platform.id);
    if (plat == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: Text('Disconnect ${platform.name}?'),
        content: const Text(
          'This will remove the link between your creator profile and your social account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await notifier.disconnect(plat);
    ref.invalidate(creatorConnectedSocialIdsProvider);
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _DescriptionBlock extends StatefulWidget {
  const _DescriptionBlock({required this.text});
  final String text;

  @override
  State<_DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends State<_DescriptionBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final truncated = widget.text.length > 140 && !_expanded
        ? '${widget.text.substring(0, 140)}...'
        : widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          truncated,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textMuted,
            height: 1.4,
          ),
        ),
        if (widget.text.length > 140)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _expanded ? 'Read less' : 'Read more',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.subscribers,
    required this.videos,
    required this.views,
  });
  final int subscribers;
  final int videos;
  final int views;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _stat('Subscribers', _fmt(subscribers))),
        _vDivider(),
        Expanded(child: _stat('Videos', _fmt(videos))),
        _vDivider(),
        Expanded(child: _stat('Views', _fmt(views))),
      ],
    );
  }

  Widget _stat(String label, String value) => Column(
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
          ),
        ],
      );

  Widget _vDivider() => Container(
        width: 1,
        height: 36,
        color: DesignTokens.borderDefault,
      );

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

/// Tiny inline SVG thumbnail fallback so this widget has no extra deps
/// besides what's already imported in the screen.
class SvgThumb extends StatelessWidget {
  const SvgThumb({super.key, required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.public_rounded,
        color: DesignTokens.textMuted,
      ),
    );
  }
}


SocialPlatform? _slugToPlatform(String slug) => switch (slug) {
      'instagram' => SocialPlatform.instagram,
      'tiktok' => SocialPlatform.tiktok,
      'youtube' => SocialPlatform.youtube,
      'facebook' => SocialPlatform.facebook,
      _ => null,
    };
