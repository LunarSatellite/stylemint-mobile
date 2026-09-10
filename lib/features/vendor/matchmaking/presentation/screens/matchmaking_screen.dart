import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/notifiers/matchmaking_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/widgets/compatibility_score_widget.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/send_partnership_request_screen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  const MatchmakingScreen({super.key});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> {
  String? _invitingMatchId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchmakingNotifierProvider);
    final inviteState = ref.watch(inviteCreatorNotifierProvider);

    ref.listen<InviteState>(inviteCreatorNotifierProvider, (_, next) {
      next.maybeWhen(
        success: (prefill) {
          ref.read(inviteCreatorNotifierProvider.notifier).reset();
          unawaited(_openPartnershipRequest(prefill));
        },
        failure: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to invite creator')),
          );
          setState(() => _invitingMatchId = null);
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
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (recommendations, hasMore, loadMoreInProgress) {
          if (recommendations.isEmpty) {
            return const SmEmptyState(
              message: 'No match recommendations found.',
              icon: Icons.people_outline,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.s16),
            itemCount: recommendations.length + (hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= recommendations.length) {
                return _buildLoadMore(loadMoreInProgress);
              }
              return _buildMatchCard(
                recommendations[i],
                inviteState,
              );
            },
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load matchmaking.',
          onRetry: () => ref
              .read(matchmakingNotifierProvider.notifier)
              .loadRecommendations(),
        ),
      ),
    );
  }

  Widget _buildLoadMore(bool loadMoreInProgress) {
    if (loadMoreInProgress) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.s16),
        child: Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
      child: Center(
        child: TextButton(
          onPressed: () =>
              ref.read(matchmakingNotifierProvider.notifier).loadMore(),
          child: const Text('Load more'),
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    MatchRecommendation recommendation,
    InviteState inviteState,
  ) {
    final isInvitingThis = _invitingMatchId == recommendation.id;
    final isSubmitting =
        isInvitingThis &&
        inviteState.maybeWhen(submitting: () => true, orElse: () => false);

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
                backgroundColor: DesignTokens.bgAppBodyLight,
                child: Text(
                  recommendation.creatorInitial,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  recommendation.displayCreatorHandle,
                  style: DesignTokens.oneLinerSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CompatibilityScoreWidget(
                score: recommendation.compatibilityScore,
              ),
            ],
          ),
          if (recommendation.reasonSummary.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s6),
                Expanded(
                  child: Text(
                    recommendation.reasonSummary,
                    style: DesignTokens.smallRegular,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: DesignTokens.buttonHeight,
                  child: OutlinedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _dismiss(recommendation.id),
                    child: const Text(
                      'Dismiss',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _inviteCreator(recommendation),
                    style: DesignTokens.primaryButtonStyle(),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Invite to Partnership',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _inviteCreator(MatchRecommendation recommendation) {
    setState(() => _invitingMatchId = recommendation.id);
    unawaited(
      ref
          .read(inviteCreatorNotifierProvider.notifier)
          .invite(
            recommendation.id,
          ),
    );
  }

  Future<void> _openPartnershipRequest(PartnershipPrefill prefill) async {
    final matchId = _invitingMatchId;
    if (mounted) setState(() => _invitingMatchId = null);

    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SendPartnershipRequestScreen(
          initialCreator: CreatorInvite(
            creatorAccountId: prefill.creatorAccountId,
            handle: prefill.creatorHandle.replaceFirst(RegExp(r'^@+'), ''),
          ),
          initialCommissionPercent: prefill.proposedCommissionPercent,
          brandBriefId: prefill.brandBriefId,
        ),
      ),
    );

    if (sent == true && mounted && matchId != null) {
      ref.read(matchmakingNotifierProvider.notifier).removeMatch(matchId);
    }
  }

  Future<void> _dismiss(String matchId) async {
    final success = await ref
        .read(matchmakingNotifierProvider.notifier)
        .dismissMatch(matchId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to dismiss match')),
      );
    }
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
