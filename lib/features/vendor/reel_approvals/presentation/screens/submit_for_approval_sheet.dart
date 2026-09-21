import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/presentation/notifiers/approval_rounds_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Send a campaign reel to the brand, and read what they said last time.
///
/// Campaign reels do not publish on the creator's own authority — the brand
/// approves first. This sheet is that gate's creator-facing half.
class SubmitForApprovalSheet extends ConsumerStatefulWidget {
  const SubmitForApprovalSheet({required this.reelId, super.key});

  final String reelId;

  /// Shown when the reel is not one the brand reviews. Deliberately does not
  /// say "you are not allowed" — the same 404 covers a reel outside any
  /// campaign, which is not a permission problem.
  static const notAllowedMessage =
      'This reel is not part of a campaign, so there is nobody to approve it.';

  @override
  ConsumerState<SubmitForApprovalSheet> createState() =>
      _SubmitForApprovalSheetState();
}

class _SubmitForApprovalSheetState
    extends ConsumerState<SubmitForApprovalSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalRoundsProvider(widget.reelId));

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send to the brand',
              style: TextStyle(
                color: DesignTokens.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Campaign reels publish once the brand approves them.',
              style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            state.maybeWhen(
              loadSuccess: (rounds, _) => _History(rounds: rounds),
              orElse: () => const SizedBox.shrink(),
            ),

            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 1000,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: const InputDecoration(
                hintText: 'Anything the brand should know (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: state.maybeWhen(
                  loadSuccess: (_, isSubmitting) =>
                      isSubmitting ? null : _submit,
                  orElse: () => _submit,
                ),
                child: const Text('Submit for approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final outcome = await ref
        .read(approvalRoundsProvider(widget.reelId).notifier)
        .submit(note: _controller.text);

    if (!mounted) return;
    final text = switch (outcome) {
      SubmitOutcome.submitted => 'Sent. The brand will review it.',
      SubmitOutcome.alreadyPending =>
        'This reel is already waiting on the brand.',
      SubmitOutcome.notAllowed => SubmitForApprovalSheet.notAllowedMessage,
      SubmitOutcome.failed => 'Could not send it. Try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    if (outcome == SubmitOutcome.submitted) Navigator.of(context).pop();
  }
}

/// Previous rounds, newest first.
class _History extends StatelessWidget {
  const _History({required this.rounds});

  final List<ReelApprovalRequest> rounds;

  @override
  Widget build(BuildContext context) {
    // No history is the normal state for a first submission, and there is
    // nothing honest to say about it, so nothing is drawn.
    if (rounds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previous rounds',
          style: TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        for (final r in rounds) _RoundTile(round: r),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _RoundTile extends StatelessWidget {
  const _RoundTile({required this.round});

  final ReelApprovalRequest round;

  /// Shown for a state this build does not recognise. Never falls back to a
  /// known state — a creator must not read "Approved" off an unknown value.
  static const unknownLabel = 'Unknown outcome';

  /// What the sweep did, in words that do not imply a decision. A brand that
  /// said nothing did not say no, and this label must not suggest otherwise.
  static const expiredLabel = 'The brand did not answer in time';

  @override
  Widget build(BuildContext context) {
    final (label, colour) = switch (round.state) {
      ReelApprovalState.pending => (
        'Waiting on the brand',
        DesignTokens.secondaryYellow,
      ),
      ReelApprovalState.approved => ('Approved', DesignTokens.primaryGreen),
      ReelApprovalState.rejected => ('Sent back', DesignTokens.textLight),
      ReelApprovalState.expired => (expiredLabel, DesignTokens.textMuted),
      null => (unknownLabel, DesignTokens.textMuted),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Round ${round.round}',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: colour,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          // A rejection with no reason stays one. "No reason given" would put
          // words in the brand's mouth, so the line simply does not appear.
          if (round.rejectionReason != null) ...[
            const SizedBox(height: 6),
            Text(
              round.rejectionReason!,
              style: const TextStyle(
                color: DesignTokens.textLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
