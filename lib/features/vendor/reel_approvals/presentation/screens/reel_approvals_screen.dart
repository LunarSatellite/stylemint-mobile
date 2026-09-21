import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/presentation/notifiers/reel_approvals_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Campaign reels waiting on this vendor's answer.
///
/// Approving publishes the reel. Rejecting returns it to the creator as a
/// draft they may revise and resubmit. Doing nothing is also an answer the
/// system understands: after the configured window the sweep returns the reel
/// to draft on its own, which is why silence never counts as consent.
class ReelApprovalsScreen extends ConsumerWidget {
  const ReelApprovalsScreen({super.key});

  static const emptyMessage =
      'No creator is waiting on you. When someone submits a campaign reel '
      'for approval, it appears here.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reelApprovalsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Reel approvals'),
      ),
      body: state.when(
        initial: () => const Center(child: CircularProgressIndicator()),
        loadInProgress: () => const Center(child: CircularProgressIndicator()),
        loadFailure: (_) => SmErrorView(
          title: 'Could not load approvals',
          onRetry: () =>
              ref.read(reelApprovalsNotifierProvider.notifier).load(),
        ),
        loadSuccess: (requests, deciding) {
          if (requests.isEmpty) {
            return const SmEmptyState(
              title: 'Nothing to review',
              message: emptyMessage,
              icon: Icons.inbox_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(reelApprovalsNotifierProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: requests.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _RequestCard(
                request: requests[i],
                isDeciding: deciding.contains(requests[i].id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, required this.isDeciding});

  final ReelApprovalRequest request;
  final bool isDeciding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // A resubmission is labelled as one. A vendor looking at round 3
              // has seen this reel twice already, and the count is the only
              // thing on screen that says so.
              if (!request.isFirstRound)
                _Pill(
                  label: 'Round ${request.round}',
                  colour: DesignTokens.secondaryYellow,
                ),
              const Spacer(),
              Text(
                'Brief v${request.brandBriefVersion}',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (!request.isFirstRound) const SizedBox(height: 12),

          if (request.creatorNote != null) ...[
            const Text(
              'What the creator said',
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              request.creatorNote!,
              style: const TextStyle(
                color: DesignTokens.textLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isDeciding ? null : () => _reject(context, ref),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isDeciding ? null : () => _approve(context, ref),
                  child: isDeciding
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        title: const Text('Approve this reel?'),
        content: const Text(
          'Approving publishes it. It becomes visible to shoppers and can be '
          'tagged for commission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final outcome = await ref
        .read(reelApprovalsNotifierProvider.notifier)
        .approve(request.id);
    if (context.mounted) _report(context, outcome);
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final reason = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceRaised,
      builder: (_) => const _RejectSheet(),
    );
    // Dismissing the sheet returns null and rejects nothing. An empty reason
    // is a deliberate choice and does reject, so the sheet returns ''.
    if (reason == null || !context.mounted) return;

    final outcome = await ref
        .read(reelApprovalsNotifierProvider.notifier)
        .reject(requestId: request.id, reason: reason);
    if (context.mounted) _report(context, outcome);
  }

  static void _report(BuildContext context, DecisionOutcome outcome) {
    final text = switch (outcome) {
      DecisionOutcome.approved => 'Approved. The reel is published.',
      DecisionOutcome.rejected =>
        'Rejected. The creator can revise it and submit again.',
      DecisionOutcome.alreadySettled =>
        'This one was already settled — the list has been refreshed.',
      DecisionOutcome.failed => 'That did not go through. Try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet();

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
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
          'Send it back',
          style: TextStyle(
            color: DesignTokens.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The reel returns to the creator as a draft. Saying what needs to '
          'change is optional, but it is the only thing they will have to go '
          'on.',
          style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 4,
          maxLength: 1000,
          style: const TextStyle(color: DesignTokens.textWhite),
          decoration: const InputDecoration(
            hintText: 'What needs to change (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Reject'),
          ),
        ),
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: colour.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: colour,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
