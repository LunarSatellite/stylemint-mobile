import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/importable_reel_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/widgets/imported_reel_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ImportReelScreen extends ConsumerStatefulWidget {
  const ImportReelScreen({super.key});

  @override
  ConsumerState<ImportReelScreen> createState() => _ImportReelScreenState();
}

class _ImportReelScreenState extends ConsumerState<ImportReelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  SocialPlatform _activePlatform = SocialPlatform.instagram;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reelImportNotifierProvider.notifier).load(_activePlatform);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reelImportNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Import Reel', style: DesignTokens.titleMedium),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.primaryGreen,
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          tabs: const [
            Tab(text: 'Import'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(state),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildPlatformChips() {
    final platforms = SocialPlatform.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s8,
      ),
      child: Row(
        children: platforms.map((platform) {
          final isActive = platform == _activePlatform;
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s8),
            child: ChoiceChip(
              label: Text(platform.displayName),
              selected: isActive,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _activePlatform = platform);
                  ref
                      .read(reelImportNotifierProvider.notifier)
                      .load(platform);
                }
              },
              selectedColor: DesignTokens.primaryGreen,
              backgroundColor: DesignTokens.bgAppBody,
              labelStyle: TextStyle(
                color: isActive
                    ? DesignTokens.textDark
                    : DesignTokens.textLight,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildImportTab(ReelImportState state) {
    return Column(
      children: [
        _buildPlatformChips(),
        Expanded(
          child: state.when(
            initial: _loader,
            loadInProgress: _loader,
            loadSuccess: (reels) {
              if (reels.isEmpty) {
                return const SmEmptyState(
                  message: 'No reels found on this platform.',
                  icon: Icons.videocam_off_outlined,
                );
              }
              return RefreshIndicator(
                color: DesignTokens.primaryGreen,
                onRefresh:
                    () =>
                        ref
                            .read(reelImportNotifierProvider.notifier)
                            .load(_activePlatform),
                child: GridView.builder(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: DesignTokens.s8,
                    mainAxisSpacing: DesignTokens.s8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: reels.length,
                  itemBuilder: (_, i) => ImportableReelCard(
                    reel: reels[i],
                    onTap: () => context.push(
                      '/creator/import/tag/${reels[i].platformPostId}',
                      extra: reels[i],
                    ),
                  ),
                ),
              );
            },
            loadFailure: (failure) => SmErrorView(
              message: 'Failed to load reels.',
              onRetry:
                  () =>
                      ref.read(reelImportNotifierProvider.notifier).load(
                        _activePlatform,
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    final historyState = ref.watch(importHistoryNotifierProvider);
    return historyState.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (reels) {
        if (reels.isEmpty) {
          return const SmEmptyState(
            message: 'No imported reels yet.',
            icon: Icons.history,
          );
        }
        return RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh:
              () =>
                  ref.read(importHistoryNotifierProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.s16),
            itemCount: reels.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => ctx.push('/creator/reels/${reels[i].id}'),
              child: ImportedReelTile(reel: reels[i]),
            ),
          ),
        );
      },
      loadFailure: (failure) => SmErrorView(
        message: 'Failed to load import history.',
        onRetry:
            () => ref.read(importHistoryNotifierProvider.notifier).load(),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
