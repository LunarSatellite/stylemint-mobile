import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_proposal_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/widgets/brand_direction_section.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One campaign in full, and the place a creator applies to it.
class CampaignProposalDetailScreen extends ConsumerWidget {
  const CampaignProposalDetailScreen({required this.briefId, super.key});

  final String briefId;

  /// The server answers 404 for draft, unpublished, retired, out-of-window and
  /// absent alike, so that it cannot be used to enumerate campaigns that were
  /// never published. This copy therefore names no cause — saying "it closed"
  /// would be a guess, and saying "it does not exist" would leak the opposite.
  static const unavailableMessage =
      'This campaign is not open to you right now.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(campaignProposalDetailProvider(briefId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Campaign'),
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loadInProgress: () => const Center(child: CircularProgressIndicator()),
        loadFailure: (failure) {
          // A 404 here is settled: the brief is retired, unpublished, or its
          // window closed, and retrying cannot change that. Every other
          // failure is worth another go.
          final isUnavailable = failure.maybeWhen<bool>(
            notFound: () => true,
            orElse: () => false,
          );
          return SmErrorView(
            title: 'Could not load this campaign',
            message: isUnavailable ? unavailableMessage : null,
            onRetry: isUnavailable
                ? null
                : () => ref
                      .read(campaignProposalDetailProvider(briefId).notifier)
                      .load(),
          );
        },
        loadSuccess: (proposal, isApplying) =>
            _Body(proposal: proposal, isApplying: isApplying, briefId: briefId),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.proposal,
    required this.isApplying,
    required this.briefId,
  });

  final CampaignProposal proposal;
  final bool isApplying;
  final String briefId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                proposal.title ?? 'Untitled campaign',
                style: TextStyle(
                  color: proposal.title == null
                      ? DesignTokens.textMuted
                      : DesignTokens.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _CommissionCard(proposal: proposal),
              const SizedBox(height: 20),

              // Brand direction — story, presentation rules, reference assets.
              // Renders nothing at all when the vendor specified nothing,
              // rather than drawing empty headings.
              BrandDirectionSection(direction: proposal.brandDirection),

              _Points(
                title: 'Suggested hooks',
                icon: Icons.bolt_outlined,
                children: [
                  for (final h in proposal.suggestedHooks)
                    _HookTile(hook: h),
                ],
              ),
              _Bullets(
                title: 'Do say',
                icon: Icons.check_circle_outline,
                colour: DesignTokens.primaryGreen,
                points: proposal.doSayPoints,
              ),
              _Bullets(
                title: "Don't say",
                icon: Icons.block_outlined,
                colour: DesignTokens.secondaryYellow,
                points: proposal.dontSayPoints,
              ),
              _Bullets(
                title: 'Audio themes',
                icon: Icons.music_note_outlined,
                colour: DesignTokens.textLight,
                points: proposal.audioThemes,
              ),

              if (proposal.hasProductRestriction) ...[
                const SizedBox(height: 8),
                _ProductRestrictionNotice(
                  count: proposal.productVariantIds.length,
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isApplying
                    ? null
                    : () => _openApplySheet(context, ref),
                child: isApplying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Apply to this campaign'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openApplySheet(BuildContext context, WidgetRef ref) async {
    final message = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceRaised,
      builder: (_) => const _ApplySheet(),
    );
    // A dismissed sheet returns null and must not apply. An empty pitch is a
    // deliberate choice and does apply, so the sheet returns '' for that.
    if (message == null) return;
    if (!context.mounted) return;

    final (outcome, _) = await ref
        .read(campaignProposalDetailProvider(briefId).notifier)
        .apply(message: message);

    if (!context.mounted) return;
    final text = switch (outcome) {
      ApplyOutcome.applied =>
        'Applied. The brand will review your application.',
      ApplyOutcome.alreadyApplied =>
        'You already have an application open on this campaign.',
      ApplyOutcome.unavailable =>
        CampaignProposalDetailScreen.unavailableMessage,
      ApplyOutcome.failed => 'Could not send your application. Try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _ApplySheet extends StatefulWidget {
  const _ApplySheet();

  @override
  State<_ApplySheet> createState() => _ApplySheetState();
}

class _ApplySheetState extends State<_ApplySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 20,
      bottom: MediaQuery.of(context).viewInsets.bottom + 20,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Apply to this campaign',
          style: TextStyle(
            color: DesignTokens.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell the brand why you are a fit. This is optional.',
          style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 5,
          maxLength: 1000,
          style: const TextStyle(color: DesignTokens.textWhite),
          decoration: const InputDecoration(
            hintText: 'Your pitch (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            // Returns '' rather than null for an empty box: null is what a
            // dismissal means, and the two must not be confused.
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Send application'),
          ),
        ),
      ],
    ),
  );
}

class _CommissionCard extends StatelessWidget {
  const _CommissionCard({required this.proposal});

  final CampaignProposal proposal;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreenDark,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.percent, color: DesignTokens.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Commission range',
                style: TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                proposal.commission.label,
                style: const TextStyle(
                  color: DesignTokens.textWhite,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Explains that accepting narrows what the creator may tag.
///
/// The restriction is enforced server-side in `ReelService` at tag time; this
/// only states it so the creator is not surprised later.
class _ProductRestrictionNotice extends StatelessWidget {
  const _ProductRestrictionNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 18,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'If the brand accepts you, reels for this campaign can tag only '
            'its $count product${count == 1 ? '' : 's'}.',
            style: const TextStyle(
              color: DesignTokens.textLight,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

/// A titled block that disappears entirely when it has nothing to show.
class _Points extends StatelessWidget {
  const _Points({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: DesignTokens.textMuted),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: DesignTokens.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _HookTile extends StatelessWidget {
  const _HookTile({required this.hook});

  final BriefHook hook;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hook.text,
          style: const TextStyle(
            color: DesignTokens.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (hook.rationale.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            hook.rationale,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ],
    ),
  );
}

class _Bullets extends StatelessWidget {
  const _Bullets({
    required this.title,
    required this.icon,
    required this.colour,
    required this.points,
  });

  final String title;
  final IconData icon;
  final Color colour;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colour),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: DesignTokens.textWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 24),
              child: Text(
                '• $p',
                style: const TextStyle(
                  color: DesignTokens.textLight,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
