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
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportReelScreen extends ConsumerStatefulWidget {
  const ImportReelScreen({super.key});

  @override
  ConsumerState<ImportReelScreen> createState() => _ImportReelScreenState();
}

class _ImportReelScreenState extends ConsumerState<ImportReelScreen> {
  SocialPlatform _selectedPlatform = SocialPlatform.instagram;
  bool _selectMode = false;
  final Set<String> _selectedIds = {};

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
    setState(() {
      _selectedPlatform = platform;
      _selectedIds.clear();
      _selectMode = false;
    });
    unawaited(
      ref.read(reelImportNotifierProvider.notifier).load(platform),
    );
  }

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleReel(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _onReelTapped(ImportableReel reel) {
    if (_selectMode) {
      _toggleReel(reel.platformPostId);
      return;
    }
    final route = RouteNames.reelImportTagProducts
        .replaceFirst(':postId', reel.platformPostId);
    unawaited(context.push(route, extra: reel));
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
      unawaited(context.push(
        RouteNames.reelImportPreview,
        extra: {'url': url, 'platform': _selectedPlatform},
      ));
    }).ignore();
  }

  Future<void> _submitBulk(List<ImportableReel> all) async {
    final selected =
        all.where((r) => _selectedIds.contains(r.platformPostId)).toList();
    if (selected.isEmpty) return;
    await ref.read(bulkImportNotifierProvider.notifier).submit(selected);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BulkImportState>(bulkImportNotifierProvider, (_, next) {
      if (next is BulkImportSuccess) {
        final r = next.result;
        final msg = r.allSucceeded
            ? '${r.successCount} reel${r.successCount == 1 ? '' : 's'} imported'
            : '${r.successCount} imported, ${r.failureCount} failed';
        SmSnackbar.info(context, msg);
        setState(() {
          _selectMode = false;
          _selectedIds.clear();
        });
        ref.read(bulkImportNotifierProvider.notifier).reset();
      } else if (next is BulkImportFailure) {
        SmSnackbar.error(context, next.message);
        ref.read(bulkImportNotifierProvider.notifier).reset();
      }
    });

    final state = ref.watch(reelImportNotifierProvider);
    final bulkState = ref.watch(bulkImportNotifierProvider);
    final isBulkSubmitting = bulkState is BulkImportInProgress;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _selectMode
              ? '${_selectedIds.length} selected'
              : 'Import Reel',
          style: DesignTokens.titleMedium,
        ),
        actions: [
          state.maybeWhen(
            loadSuccess: (_) => TextButton(
              onPressed: _toggleSelectMode,
              child: Text(
                _selectMode ? 'Cancel' : 'Select',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _selectMode
                      ? DesignTokens.textMuted
                      : DesignTokens.primaryGreen,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
                    onPasteUrl: _showUrlPasteSheet,
                  );
                }
                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s12,
                    DesignTokens.s16,
                    _selectMode
                        ? DesignTokens.s16 + 72
                        : DesignTokens.s32,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
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
                      isSelectMode: _selectMode,
                      isSelected: _selectedIds
                          .contains(reel.platformPostId),
                      onTap: () => _onReelTapped(reel),
                    );
                  },
                );
              },
              loadFailure: (failure) => failure.isNotFound
                  ? _NotConnectedState(
                      platform: _selectedPlatform,
                      onConnect: () =>
                          context.push(RouteNames.socialConnect),
                    )
                  : _ErrorState(
                      onRetry: () => unawaited(
                        ref
                            .read(reelImportNotifierProvider.notifier)
                            .load(_selectedPlatform),
                      ),
                    ),
            ),
          ),

          // ── Bulk import bar (select mode) ────────────────────────────────
          if (_selectMode)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s8,
                  DesignTokens.s16,
                  DesignTokens.s16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    style: DesignTokens.primaryButtonStyle(),
                    onPressed: _selectedIds.isEmpty || isBulkSubmitting
                        ? null
                        : () {
                            final reels = state.maybeWhen(
                              loadSuccess: (r) => r,
                              orElse: () => <ImportableReel>[],
                            );
                            unawaited(_submitBulk(reels));
                          },
                    child: isBulkSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            _selectedIds.isEmpty
                                ? 'Select reels to import'
                                : 'Import ${_selectedIds.length} '
                                    'Reel${_selectedIds.length == 1 ? '' : 's'}',
                          ),
                  ),
                ),
              ),
            )
          // ── Paste URL fallback (normal mode) ─────────────────────────────
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s8,
                  DesignTokens.s16,
                  DesignTokens.s16,
                ),
                child: GestureDetector(
                  onTap: _showUrlPasteSheet,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

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
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s24,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + DesignTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paste a Reel URL', style: DesignTokens.titleMedium),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Paste the link to your ${widget.platform.displayName} reel.',
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
    );
  }
}
