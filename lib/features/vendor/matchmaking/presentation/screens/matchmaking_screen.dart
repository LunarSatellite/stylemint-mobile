import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/notifiers/matchmaking_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/widgets/compatibility_score_widget.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  String? _selectedCategory;
  int? _minFollowers;
  int? _maxFollowers;
  String? _selectedCampaignId;

  static const _categories = [
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Fitness',
    'Food',
    'Tech',
    'Travel',
    'Home',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchmakingNotifierProvider.notifier).loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchmakingNotifierProvider);
    final inviteState = ref.watch(inviteCreatorNotifierProvider);

    ref.listen<InviteState>(inviteCreatorNotifierProvider, (_, next) {
      next.maybeWhen(
        success: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Creator invited!')),
          );
          ref.read(inviteCreatorNotifierProvider.notifier).reset();
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to invite creator')),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Matchmaking', style: DesignTokens.titleMedium),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: state.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (recommendations) {
                if (recommendations.isEmpty) {
                  return const SmEmptyState(
                    message: 'No match recommendations found.',
                    icon: Icons.people_outline,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  itemCount: recommendations.length,
                  itemBuilder: (_, i) => _buildMatchCard(
                    recommendations[i],
                    inviteState,
                  ),
                );
              },
              loadFailure: (failure) => SmErrorView(
                message: 'Failed to load matchmaking.',
                onRetry: () => ref
                    .read(matchmakingNotifierProvider.notifier)
                    .loadRecommendations(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    _applyFilters();
                  },
                ),
                ..._categories.map(
                  (cat) => _FilterChip(
                    label: cat,
                    selected: _selectedCategory == cat,
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    );
  }

  void _applyFilters() {
    final filter = MatchmakingFilter(
      categories:
          _selectedCategory != null ? [_selectedCategory!] : null,
      minFollowers: _minFollowers,
      maxFollowers: _maxFollowers,
    );
    ref
        .read(matchmakingNotifierProvider.notifier)
        .loadRecommendations(filters: filter);
  }

  Widget _buildMatchCard(
    MatchRecommendation recommendation,
    InviteState inviteState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(recommendation.avatarUrl),
                backgroundColor: DesignTokens.bgAppBodyLight,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.creatorName,
                      style: DesignTokens.oneLinerSemibold,
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      '@${recommendation.handle}  ·  ${recommendation.category}',
                      style: DesignTokens.tiny,
                    ),
                  ],
                ),
              ),
              CompatibilityScoreWidget(
                score: recommendation.compatibilityScore,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          if (recommendation.reasons.isNotEmpty) ...[
            ...recommendation.reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: DesignTokens.primaryGreen),
                    const SizedBox(width: DesignTokens.s6),
                    Expanded(
                      child: Text(reason, style: DesignTokens.smallRegular),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
          if (recommendation.sampleReelThumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: Image.network(
                recommendation.sampleReelThumbnail!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: inviteState.maybeWhen(
                submitting: () => false,
                orElse: () => true,
              )
                  ? () => _inviteCreator(recommendation)
                  : null,
              style: DesignTokens.primaryButtonStyle(),
              child: inviteState.maybeWhen(
                submitting: () =>
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                orElse: () => const Text('Invite to Campaign'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _inviteCreator(MatchRecommendation recommendation) {
    ref
        .read(inviteCreatorNotifierProvider.notifier)
        .invite('', recommendation.creatorId);
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.s8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s6,
          ),
          decoration: selected
              ? DesignTokens.chipDecorationSelected()
              : DesignTokens.chipDecorationDefault(),
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
