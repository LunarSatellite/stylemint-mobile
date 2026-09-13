import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_acceptance_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Verified Scan-to-Receive Handover" — a "Got your parcel?" card
/// on the order detail screen. Once a StyleMint parcel is out for delivery
/// or delivered, the buyer says what arrived (All good / Something's wrong /
/// Refuse it), whether the seal was intact when the seller sealed it, and
/// what was wrong for the issue choices. After that it shows the saved
/// answer read-only. Renders nothing while checking, before the parcel is
/// out for delivery, or when a check fails.
class DeliveryAcceptanceCard extends ConsumerStatefulWidget {
  const DeliveryAcceptanceCard({required this.trackingNumber, super.key});

  final String trackingNumber;

  @override
  ConsumerState<DeliveryAcceptanceCard> createState() =>
      _DeliveryAcceptanceCardState();
}

class _DeliveryAcceptanceCardState
    extends ConsumerState<DeliveryAcceptanceCard> {
  final _note = TextEditingController();
  DeliveryAcceptanceOutcome? _outcome;
  bool? _sealIntact;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = deliveryAcceptanceNotifierProvider(widget.trackingNumber);
    final state = ref.watch(provider);

    final content = switch (state) {
      DeliveryAcceptanceChecking() || DeliveryAcceptanceHidden() => null,
      final DeliveryAcceptanceAsking asking => _question(
        asking,
        ref.read(provider.notifier),
      ),
      final DeliveryAcceptanceRecorded recorded => _RecordedAnswer(
        recorded: recorded,
      ),
    };
    if (content == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Container(
        key: const ValueKey('delivery-acceptance-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: content,
      ),
    );
  }

  Widget _question(
    DeliveryAcceptanceAsking asking,
    DeliveryAcceptanceNotifier notifier,
  ) {
    final sending = asking.sending;
    final sealBroken = asking.hasSeal && _sealIntact == false;
    final outcome = _outcome;
    final problem = deliveryAcceptanceProblem(
      outcome: outcome,
      hasSeal: asking.hasSeal,
      sealIntact: _sealIntact,
      issueNote: _note.text,
    );

    void choose(DeliveryAcceptanceOutcome value) =>
        setState(() => _outcome = value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 18,
              color: DesignTokens.primaryGreen,
            ),
            SizedBox(width: DesignTokens.s8),
            Text('Got your parcel?', style: DesignTokens.sectionInnerTitle),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'Tell us what arrived so we can sort out any problem quickly.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (asking.hasSeal) ...[
          const SizedBox(height: DesignTokens.s16),
          Text('Was the seal intact?', style: _labelStyle),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              _ChoicePill(
                key: const ValueKey('acceptance-seal-yes'),
                label: 'Yes, it was intact',
                selected: _sealIntact == true,
                onTap: sending
                    ? null
                    : () => setState(() => _sealIntact = true),
              ),
              _ChoicePill(
                key: const ValueKey('acceptance-seal-no'),
                label: 'No, it was broken',
                selected: _sealIntact == false,
                onTap: sending
                    ? null
                    : () => setState(() {
                        _sealIntact = false;
                        // A broken seal can't be "all good".
                        if (_outcome == DeliveryAcceptanceOutcome.accepted) {
                          _outcome = null;
                        }
                      }),
              ),
            ],
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        Text('How did it go?', style: _labelStyle),
        const SizedBox(height: DesignTokens.s4),
        _OutcomeOption(
          key: const ValueKey('acceptance-outcome-accepted'),
          title: 'All good',
          description: sealBroken
              ? 'Not available when the seal was broken.'
              : 'Everything arrived as expected.',
          selected: outcome == DeliveryAcceptanceOutcome.accepted,
          onTap: sending || sealBroken
              ? null
              : () => choose(DeliveryAcceptanceOutcome.accepted),
        ),
        _OutcomeOption(
          key: const ValueKey('acceptance-outcome-issue'),
          title: "Something's wrong",
          description:
              'I kept it, but something is damaged, missing or not what I '
              'ordered.',
          selected: outcome == DeliveryAcceptanceOutcome.acceptedWithIssue,
          onTap: sending
              ? null
              : () => choose(DeliveryAcceptanceOutcome.acceptedWithIssue),
        ),
        _OutcomeOption(
          key: const ValueKey('acceptance-outcome-refused'),
          title: 'Refuse it',
          description: "I don't want to accept this parcel.",
          selected: outcome == DeliveryAcceptanceOutcome.refused,
          onTap: sending
              ? null
              : () => choose(DeliveryAcceptanceOutcome.refused),
        ),
        if (outcome?.needsNote ?? false) ...[
          const SizedBox(height: DesignTokens.s8),
          TextField(
            key: const ValueKey('acceptance-note'),
            controller: _note,
            enabled: !sending,
            minLines: 2,
            maxLines: 4,
            maxLength: deliveryAcceptanceMaxNoteLength,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              hintText: outcome == DeliveryAcceptanceOutcome.refused
                  ? 'Why are you refusing it?'
                  : 'What was wrong?',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (asking.errorMessage != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            asking.errorMessage!,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        if (sending)
          const Center(
            child: SmBrandLoader(
              size: 40,
              semanticLabel: 'Sending your answer',
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: problem == null && outcome != null
                  ? () => notifier.submit(
                      outcome: outcome,
                      sealIntact: _sealIntact,
                      issueNote: _note.text,
                    )
                  : null,
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Send answer'),
            ),
          ),
      ],
    );
  }

  static final TextStyle _labelStyle = DesignTokens.mediumSemibold.copyWith(
    color: DesignTokens.textWhite,
    fontSize: 14,
  );
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s12,
            vertical: DesignTokens.s8,
          ),
          decoration: selected
              ? DesignTokens.chipDecorationSelected()
              : DesignTokens.chipDecorationDefault(),
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: selected
                  ? DesignTokens.textWhite
                  : DesignTokens.chipsDefaultText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OutcomeOption extends StatelessWidget {
  const _OutcomeOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: Opacity(
          opacity: enabled || selected ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? DesignTokens.radioIconChecked
                      : DesignTokens.radioIconDefault,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        description,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordedAnswer extends StatelessWidget {
  const _RecordedAnswer({required this.recorded});

  final DeliveryAcceptanceRecorded recorded;

  @override
  Widget build(BuildContext context) {
    final acceptance = recorded.acceptance;
    final (icon, color) = switch (acceptance.outcome) {
      DeliveryAcceptanceOutcome.accepted => (
        Icons.check_circle_outline,
        DesignTokens.primaryGreen,
      ),
      DeliveryAcceptanceOutcome.acceptedWithIssue => (
        Icons.report_problem_outlined,
        DesignTokens.warning500,
      ),
      DeliveryAcceptanceOutcome.refused => (
        Icons.block_rounded,
        DesignTokens.colorError,
      ),
      DeliveryAcceptanceOutcome.unknown => (
        Icons.info_outline,
        DesignTokens.textMuted,
      ),
    };
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    final photoCount = acceptance.photoUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(
                deliveryAcceptanceSummary(acceptance),
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        if (acceptance.sealIntact != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            acceptance.sealIntact!
                ? 'The seal was intact.'
                : 'The seal was broken.',
            style: muted,
          ),
        ],
        if (acceptance.issueNote != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Your note: ${acceptance.issueNote}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
        if (photoCount > 0) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            photoCount == 1
                ? '1 photo attached'
                : '$photoCount photos attached',
            style: muted,
          ),
        ],
        if (recorded.notice != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(recorded.notice!, style: muted),
        ],
      ],
    );
  }
}

/// "You accepted this parcel on Sep 13, 2026." and friends, in local time.
String deliveryAcceptanceSummary(DeliveryAcceptance acceptance) {
  final recorded = acceptance.recordedUtc;
  final on = recorded == null
      ? ''
      : ' on ${DateFormat('MMM d, yyyy').format(recorded.toLocal())}';
  return switch (acceptance.outcome) {
    DeliveryAcceptanceOutcome.accepted => 'You accepted this parcel$on.',
    DeliveryAcceptanceOutcome.acceptedWithIssue =>
      'You kept this parcel and reported a problem$on.',
    DeliveryAcceptanceOutcome.refused => 'You refused this parcel$on.',
    DeliveryAcceptanceOutcome.unknown =>
      'Your answer for this parcel was saved$on.',
  };
}
