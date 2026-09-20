import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/last_import_platform_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/content_freshness_banner.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/importable_reel_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/shared/providers.dart'
    show socialConnectNotifierProvider;
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportReelScreen extends ConsumerStatefulWidget {
  const ImportReelScreen({super.key});

  @override
  ConsumerState<ImportReelScreen> createState() => _ImportReelScreenState();
}

class _ImportReelScreenState extends ConsumerState<ImportReelScreen> {
  /// How long to wait for the connected-accounts list when choosing the
  /// opening platform before falling back to Instagram.
  static const _accountsWait = Duration(seconds: 4);

  SocialPlatform _selectedPlatform = SocialPlatform.instagram;

  /// False until the opening platform is chosen (saved, else first connected
  /// account, else Instagram); the content area shows a loader until then.
  bool _platformResolved = false;
  ImportableReel? _selectedReel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openInitialPlatform());
    });
  }

  Future<void> _openInitialPlatform() async {
    final saved = await ref.read(lastImportPlatformProvider.notifier).restored;
    if (!mounted || _platformResolved) return;
    final accounts = saved == null
        ? await _connectedAccounts()
        : const <SocialAccount>[];
    // The creator may have tapped a platform while this was resolving.
    if (!mounted || _platformResolved) return;
    final platform = resolveImportPlatform(saved: saved, accounts: accounts);
    setState(() {
      _selectedPlatform = platform;
      _platformResolved = true;
    });
    unawaited(ref.read(reelImportNotifierProvider.notifier).load(platform));
  }

  /// Connected accounts once the social-connect list has loaded; empty when
  /// it fails or takes longer than [_accountsWait].
  Future<List<SocialAccount>> _connectedAccounts() async {
    final completer = Completer<List<SocialAccount>>();
    final subscription = ref.listenManual<SocialConnectState>(
      socialConnectNotifierProvider,
      (_, next) {
        final accounts = next.maybeWhen<List<SocialAccount>?>(
          loadSuccess: (accounts) => accounts,
          loadFailure: (_) => const [],
          orElse: () => null,
        );
        if (accounts != null && !completer.isCompleted) {
          completer.complete(accounts);
        }
      },
      fireImmediately: true,
    );
    try {
      return await completer.future.timeout(
        _accountsWait,
        onTimeout: () => const [],
      );
    } finally {
      if (mounted) subscription.close();
    }
  }

  void _onPlatformChanged(SocialPlatform platform) {
    if (_platformResolved && platform == _selectedPlatform) return;
    setState(() {
      _selectedPlatform = platform;
      _platformResolved = true;
      _selectedReel = null;
    });
    unawaited(
      ref.read(lastImportPlatformProvider.notifier).setPlatform(platform),
    );
    unawaited(
      ref.read(reelImportNotifierProvider.notifier).load(platform),
    );
  }

  /// Opens the social connect screen, then refreshes on return so a
  /// reconnected account shows its posts straight away.
  Future<void> _openSocialConnect() async {
    await context.push<void>(RouteNames.socialConnect);
    if (!mounted) return;
    await ref.read(reelImportNotifierProvider.notifier).refresh();
  }

  Future<void> _refresh() =>
      ref.read(reelImportNotifierProvider.notifier).refresh();

  void _retryLoad() => unawaited(
    ref.read(reelImportNotifierProvider.notifier).load(_selectedPlatform),
  );

  void _onReelTapped(ImportableReel reel) {
    setState(() {
      _selectedReel = _selectedReel?.id == reel.id ? null : reel;
    });
  }

  void _onImportPressed(ImportableReel reel) {
    unawaited(
      context.push(
        RouteNames.reelImportPreview,
        extra: reel,
      ),
    );
  }

  void _showUrlPasteSheet() {
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.s16),
        ),
      ),
      builder: (_) => _UrlPasteSheet(platform: _selectedPlatform),
    ).then((url) {
      if (url == null || url.isEmpty || !mounted) return;
      final pastedReel = _findVerifiedReel(url);
      if (pastedReel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Connect and refresh this account, then choose the reel from the verified list.',
            ),
          ),
        );
        return;
      }
      unawaited(
        context.push(
          RouteNames.reelImportPreview,
          extra: pastedReel,
        ),
      );
    }).ignore();
  }

  ImportableReel? _findVerifiedReel(String sourceUrl) {
    final candidates = ref
        .read(reelImportNotifierProvider)
        .maybeWhen(
          loadSuccess: (reels, _, _, _, _, _) => reels,
          orElse: () => const <ImportableReel>[],
        );
    for (final reel in candidates) {
      if (reel.sourceUrl == sourceUrl && reel.videoDuration > 0) return reel;
    }
    return null;
  }

  /// Snackbar for a pull to refresh that was skipped (provider asked us to
  /// wait) or failed while the current list stayed on screen.
  void _onImportStateChanged(ReelImportState? previous, ReelImportState next) {
    next.maybeWhen(
      loadSuccess: (_, _, _, freshness, blockedUntil, refreshFailure) {
        final (previousBlocked, previousFailure) =
            previous?.maybeWhen<(DateTime?, NetworkExceptions?)?>(
              loadSuccess: (_, _, _, _, blocked, failure) => (blocked, failure),
              orElse: () => null,
            ) ??
            (null, null);
        final String message;
        if (blockedUntil != null && blockedUntil != previousBlocked) {
          message = ContentFreshnessCopy.refreshBlocked(
            freshness.providerStatus?.issue,
            _selectedPlatform,
            blockedUntil,
            DateTime.now(),
          );
        } else if (refreshFailure != null &&
            refreshFailure != previousFailure) {
          message = ContentFreshnessCopy.refreshFailed(
            refreshFailure,
            _selectedPlatform,
          );
        } else {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      orElse: () {},
    );
  }

  Widget _buildReels({
    required List<ImportableReel> reels,
    required bool hasMore,
    required bool isLoadingMore,
    required ContentFreshness freshness,
  }) {
    final banner = ContentFreshnessBanner(
      freshness: freshness,
      platform: _selectedPlatform,
      onReconnect: () => unawaited(_openSocialConnect()),
    );

    if (reels.isEmpty && !hasMore) {
      return Column(
        children: [
          banner,
          Expanded(
            child: RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: _refresh,
              child: _EmptyState(
                platform: _selectedPlatform,
                onPasteUrl: _showUrlPasteSheet,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        banner,
        Expanded(
          child: RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: _refresh,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s12,
                DesignTokens.s16,
                DesignTokens.s12,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: DesignTokens.s8,
                mainAxisSpacing: DesignTokens.s8,
                childAspectRatio: 0.75,
              ),
              itemCount: reels.length,
              itemBuilder: (_, i) {
                final reel = reels[i];
                return ImportableReelCard(
                  reel: reel,
                  isSelected: _selectedReel?.id == reel.id,
                  onTap: () => _onReelTapped(reel),
                );
              },
            ),
          ),
        ),
        // A single provider page can be entirely non-video posts (e.g. a run
        // of photos), so "hasMore" stays visible even when this page
        // contributed zero importable reels — the empty-state check above
        // only fires once there's truly nothing left to fetch.
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s16),
            child: isLoadingMore
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => unawaited(
                      ref.read(reelImportNotifierProvider.notifier).loadMore(),
                    ),
                    child: const Text('Load more'),
                  ),
          )
        // Saved pages end at what is saved; older or newer posts need a
        // live read, which is what pull to refresh asks for.
        else if (freshness.servedFromCache)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              0,
              DesignTokens.s16,
              DesignTokens.s12,
            ),
            child: Text(
              "That's all your saved reels. Pull down to refresh.",
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFailure(NetworkExceptions failure) {
    final name = _selectedPlatform.displayName;
    final notConnected = _NotConnectedState(
      platform: _selectedPlatform,
      onConnect: () => unawaited(_openSocialConnect()),
    );
    if (failure.isNotFound) return notConnected;

    return switch (ContentProviderIssue.fromCode(failure.validationCode)) {
      ContentProviderIssue.reconnect => _MessageState(
        icon: Icons.link_off_rounded,
        title: 'Reconnect $name',
        message:
            'Your $name connection has stopped working. '
            'Reconnect to see your reels.',
        actionLabel: 'Reconnect',
        onAction: () => unawaited(_openSocialConnect()),
      ),
      ContentProviderIssue.permissionMissing => _MessageState(
        icon: Icons.lock_outline_rounded,
        title: '$name needs permission again',
        message:
            'Reconnect $name and allow access to your posts '
            'so we can list your reels.',
        actionLabel: 'Reconnect',
        onAction: () => unawaited(_openSocialConnect()),
      ),
      ContentProviderIssue.rateLimited => _MessageState(
        icon: Icons.schedule_rounded,
        title: '$name is limiting requests right now',
        message:
            'None of your $name posts are saved yet. '
            'Try again later.',
        actionLabel: 'Try again',
        onAction: _retryLoad,
      ),
      ContentProviderIssue.unavailable => _MessageState(
        icon: Icons.cloud_off_rounded,
        title: "$name isn't responding",
        message: 'Try again in a few minutes.',
        actionLabel: 'Try again',
        onAction: _retryLoad,
      ),
      ContentProviderIssue.notConnected => notConnected,
      null when failure.isNoInternet => _MessageState(
        icon: Icons.wifi_off_rounded,
        title: 'No internet connection',
        message: 'Check your connection and try again.',
        actionLabel: 'Try again',
        onAction: _retryLoad,
      ),
      null => _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load your posts',
        message:
            'Check your connection and make sure your '
            'social account is connected.',
        actionLabel: 'Try again',
        onAction: _retryLoad,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReelImportState>(
      reelImportNotifierProvider,
      _onImportStateChanged,
    );
    final state = ref.watch(reelImportNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text('Import Reel', style: DesignTokens.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: DesignTokens.textWhite),
            tooltip: 'Import history',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: DesignTokens.bgAppFoundation,
              isScrollControlled: true,
              builder: (_) => const _ImportHistorySheet(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Helper text ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s4,
            ),
            child: Text(
              'Select the reel from your social media and we will '
              'import it automatically for you.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                height: 1.4,
              ),
            ),
          ),

          // ── Platform selector ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              0,
              DesignTokens.s16,
              DesignTokens.s4,
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
                      isSelected:
                          _platformResolved && platform == _selectedPlatform,
                      onTap: () => _onPlatformChanged(platform),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: !_platformResolved
                ? const SmPageLoader()
                : state.when(
                    initial: () => const SizedBox.shrink(),
                    loadInProgress: () => const SmPageLoader(),
                    loadSuccess:
                        (reels, hasMore, isLoadingMore, freshness, _, _) =>
                            _buildReels(
                              reels: reels,
                              hasMore: hasMore,
                              isLoadingMore: isLoadingMore,
                              freshness: freshness,
                            ),
                    loadFailure: _buildFailure,
                  ),
          ),

          // ── Bottom action bar ────────────────────────────────────────────────────────────
          SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                border: Border(
                  top: BorderSide(color: DesignTokens.borderDefault),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s12,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: DesignTokens.buttonHeight,
                          child: OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Drafts will be available soon.',
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: DesignTokens.buttonGrayFill,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.buttonRadius,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Save as Draft',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                color: DesignTokens.textWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: DesignTokens.buttonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              final selected = _selectedReel;
                              if (selected == null) return;
                              _onImportPressed(selected);
                            },
                            style: DesignTokens.primaryButtonStyle(),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Import Reel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: DesignTokens.s8),
                                Icon(Icons.download_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        // Scrollable even when it fits, so pull to refresh works here too.
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
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
                    'Make sure your account is connected '
                    'and has published posts.',
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
          ),
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────

/// Full-area message with one action, used when nothing is saved to show.
class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 56, color: DesignTokens.textMuted),
                  const SizedBox(height: DesignTokens.s16),
                  Text(
                    title,
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
                    message,
                    textAlign: TextAlign.center,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s24),
                  ElevatedButton(
                    onPressed: onAction,
                    style: DesignTokens.primaryButtonStyle(),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Not connected state ──────────────────────────────────────────────────────

class _NotConnectedState extends StatelessWidget {
  const _NotConnectedState({required this.platform, required this.onConnect});

  final SocialPlatform platform;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.link_off_rounded,
                    size: 56,
                    color: DesignTokens.textMuted,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  Text(
                    '${platform.displayName} not connected',
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
                    'Connect your ${platform.displayName} account '
                    'to import your reels.',
                    textAlign: TextAlign.center,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s24),
                  ElevatedButton(
                    onPressed: onConnect,
                    style: DesignTokens.primaryButtonStyle(),
                    child: const Text('Connect Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── URL paste sheet ──────────────────────────────────────────────────────────

class _UrlPasteSheet extends StatefulWidget {
  const _UrlPasteSheet({required this.platform});

  final SocialPlatform platform;

  @override
  State<_UrlPasteSheet> createState() => _UrlPasteSheetState();
}

class _UrlPasteSheetState extends State<_UrlPasteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: DesignTokens.s16,
          right: DesignTokens.s16,
          top: DesignTokens.s24,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste a Reel URL', style: DesignTokens.titleMedium),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Paste a link from your connected ${widget.platform.displayName} '
              "account. We'll verify it before importing.",
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
              decoration: InputDecoration(
                hintText: 'https://',
                hintStyle: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
                filled: true,
                fillColor: DesignTokens.bgAppFoundation,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s12,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: () =>
                    Navigator.of(context).pop(_controller.text.trim()),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prior imports for this creator, read from [importHistoryNotifierProvider].
///
/// The notifier loads once when first read; the sheet offers an explicit
/// refresh because an import completed elsewhere in the app will not
/// invalidate it on its own.
class _ImportHistorySheet extends ConsumerWidget {
  const _ImportHistorySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importHistoryNotifierProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Import history',
                      style: DesignTokens.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: DesignTokens.textWhite,
                    ),
                    tooltip: 'Refresh',
                    onPressed: () => unawaited(
                      ref.read(importHistoryNotifierProvider.notifier).load(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
              Flexible(
                child: state.when(
                  initial: () => const _HistoryMessage('Loading…'),
                  loadInProgress: () => const Padding(
                    padding: EdgeInsets.all(DesignTokens.s24),
                    child: const SmPageLoader(),
                  ),
                  loadFailure: (failure) =>
                      _HistoryMessage(NetworkExceptions.getMessage(failure)),
                  loadSuccess: (reels) => reels.isEmpty
                      ? const _HistoryMessage(
                          "You haven't imported any reels yet.",
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: reels.length,
                          separatorBuilder: (_, _i) =>
                              const SizedBox(height: DesignTokens.s8),
                          itemBuilder: (_, i) => _HistoryTile(reel: reels[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s24),
    child: Text(
      text,
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.textMuted,
      ),
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.reel});

  final ImportedReel reel;

  @override
  Widget build(BuildContext context) {
    final caption = reel.caption.trim();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          child: reel.thumbnailUrl.isEmpty
              ? const SizedBox(width: 48, height: 64)
              : Image.network(
                  reel.thumbnailUrl,
                  width: 48,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _e, _s) =>
                      const SizedBox(width: 48, height: 64),
                ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption.isEmpty ? 'Untitled reel' : caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${reel.status.name} · ${reel.tags.length} tagged',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
