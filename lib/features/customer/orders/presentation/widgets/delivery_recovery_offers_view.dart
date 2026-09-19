import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_recovery_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_recovery_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Predictive Recovery" — the remedies for a delivery that is
/// predicted to slip, shown directly under the risk narration the customer
/// is already reading. Renders nothing at all when there is nothing to
/// offer, so a healthy delivery is never given a card or an "all good"
/// banner competing with the tracking view.
class DeliveryRecoveryOffersView extends ConsumerStatefulWidget {
  const DeliveryRecoveryOffersView({required this.trackingNumber, super.key});

  final String trackingNumber;

  @override
  ConsumerState<DeliveryRecoveryOffersView> createState() =>
      _DeliveryRecoveryOffersViewState();
}

class _DeliveryRecoveryOffersViewState
    extends ConsumerState<DeliveryRecoveryOffersView> {
  /// The offer and the acknowledgement the customer actually gave, kept so a
  /// retry after a transient failure repeats the *same* attempt (and so the
  /// notifier reuses the same Idempotency-Key) instead of re-asking.
  DeliveryRecoveryOffer? _lastOffer;
  bool _lastAcknowledgement = false;

  DeliveryRecoveryNotifier get _notifier => ref.read(
    deliveryRecoveryNotifierProvider(widget.trackingNumber).notifier,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      deliveryRecoveryNotifierProvider(widget.trackingNumber),
    );
    final now = _notifier.now();
    if (state.isSilentAt(now)) return const SizedBox.shrink();

    final live = state.liveOffers(now);
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Column(
        key: const Key('delivery-recovery-offers'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(
            height: 1,
            thickness: 1,
            color: DesignTokens.borderDefault,
          ),
          const SizedBox(height: DesignTokens.s12),
          if (state.notice != DeliveryRecoveryNotice.none) ...[
            _RecoveryNotice(
              state: state,
              onRefresh: () => _notifier.refresh(),
              onRetry: _retryLastAttempt,
            ),
            if (live.isNotEmpty) const SizedBox(height: DesignTokens.s12),
          ],
          if (state.notice != DeliveryRecoveryNotice.accepted &&
              live.isNotEmpty) ...[
            Semantics(
              header: true,
              child: const Text(
                'What we can do about it',
                style: DesignTokens.mediumSemibold,
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Choose one. Nothing happens to your order until you do.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            for (final offer in live) ...[
              _OfferTile(
                offer: offer,
                now: now,
                busy: state.acceptingOfferId == offer.offerId,
                enabled: !state.isAccepting,
                onChoose: () => _chooseOffer(offer),
              ),
              const SizedBox(height: DesignTokens.s8),
            ],
          ],
          if (state.refreshing && live.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s8),
              child: Text(
                'Checking what is open to you now…',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseOffer(DeliveryRecoveryOffer offer) async {
    // A known-harmless remedy (support picks it up) goes straight through.
    // Anything that moves money, and anything this build does not recognise,
    // has to be confirmed on its own screen first.
    final needsConfirmation =
        offer.remedy != DeliveryRemedyKind.prioritySupportReview;

    var acknowledged = false;
    if (needsConfirmation) {
      final result = await showModalBottomSheet<_ConfirmResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: DesignTokens.surfaceRaised,
        builder: (_) => _ConfirmRemedySheet(offer: offer),
      );
      if (result == null || !result.confirmed) return;
      acknowledged = result.acknowledged;
    }

    _lastOffer = offer;
    _lastAcknowledgement = acknowledged;
    await _notifier.accept(offer, acknowledgeRefundWindow: acknowledged);
  }

  Future<void> _retryLastAttempt() async {
    final offer = _lastOffer;
    if (offer == null) {
      await _notifier.refresh();
      return;
    }
    await _notifier.accept(
      offer,
      acknowledgeRefundWindow: _lastAcknowledgement,
    );
  }
}

/// One remedy: what it is, how long it stays open, and its single control.
class _OfferTile extends StatelessWidget {
  const _OfferTile({
    required this.offer,
    required this.now,
    required this.busy,
    required this.enabled,
    required this.onChoose,
  });

  final DeliveryRecoveryOffer offer;
  final DateTime now;
  final bool busy;
  final bool enabled;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final copy = DeliveryRemedyCopy.of(offer);
    final window = remainingWindowLabel(offer.remainingAt(now));
    return Container(
      key: ValueKey('recovery-offer-${offer.offerId}'),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.radioCardFill,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        border: Border.all(color: DesignTokens.radioCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.title, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s4),
          Text(
            copy.body,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: MallStatusPill(
              label: window,
              tone: MallStatusTone.caution,
              icon: Icons.schedule_rounded,
              dense: true,
              semanticLabel: 'This option is $window',
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Semantics(
            button: true,
            enabled: enabled && !busy,
            label: copy.ctaSemantics,
            excludeSemantics: true,
            child: FilledButton(
              key: ValueKey('recovery-cta-${offer.offerId}'),
              onPressed: enabled && !busy ? onChoose : null,
              style: FilledButton.styleFrom(
                backgroundColor: copy.destructive
                    ? DesignTokens.colorError
                    : DesignTokens.primaryGreen,
                foregroundColor: copy.destructive
                    ? DesignTokens.textWhite
                    : DesignTokens.baseBlack,
                disabledBackgroundColor: DesignTokens.bgAppBodyLight,
                disabledForegroundColor: DesignTokens.textMuted,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(copy.ctaLabel, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the customer is told on top of the list: the two 409s read
/// differently on purpose, and neither leaves them on a dead screen.
class _RecoveryNotice extends StatelessWidget {
  const _RecoveryNotice({
    required this.state,
    required this.onRefresh,
    required this.onRetry,
  });

  final DeliveryRecoveryState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.notice) {
      case DeliveryRecoveryNotice.none:
        return const SizedBox.shrink();

      case DeliveryRecoveryNotice.accepted:
        final offer = state.acceptedOffer;
        final copy = offer == null
            ? const DeliveryRemedyAcceptedCopy(
                'That is done',
                'We have put your choice through.',
              )
            : DeliveryRemedyCopy.acceptedFor(offer);
        final reference = offer?.outcomeReference;
        return MallStatusSummary(
          key: const Key('recovery-notice-accepted'),
          title: copy.title,
          tone: MallStatusTone.success,
          icon: Icons.check_circle_outline_rounded,
          detail: copy.detail,
          footnote: reference == null || reference.isEmpty
              ? null
              : 'Reference $reference',
        );

      case DeliveryRecoveryNotice.expired:
        // The window lapsed in flight. Nothing changed — ask again.
        return _NoticeCard(
          noticeKey: const Key('recovery-notice-expired'),
          tone: MallStatusTone.caution,
          icon: Icons.hourglass_disabled_rounded,
          title: 'That option ran out before we could confirm it',
          body:
              'Nothing about your order has changed. Its 30-minute window '
              'closed while we were putting it through — ask again and take '
              'whichever option is open now.',
          actionLabel: 'Show the current options',
          busy: state.refreshing,
          onAction: onRefresh,
        );

      case DeliveryRecoveryNotice.stale:
        // The delivery itself moved. Say so — this is news, not an error.
        return _NoticeCard(
          noticeKey: const Key('recovery-notice-stale'),
          tone: MallStatusTone.info,
          icon: Icons.local_shipping_outlined,
          title: 'Your delivery moved while you were deciding',
          body:
              'That option was worked out for where your parcel was a moment '
              'ago, so it no longer matches reality. Nothing about your order '
              'has changed — here is what is true now.',
          actionLabel: 'Show what is true now',
          busy: state.refreshing,
          onAction: onRefresh,
        );

      case DeliveryRecoveryNotice.lapsedOnScreen:
        return _NoticeCard(
          noticeKey: const Key('recovery-notice-lapsed'),
          tone: MallStatusTone.caution,
          icon: Icons.schedule_rounded,
          title: 'That option just timed out',
          body:
              'Its 30-minute window closed while this page was open, so we '
              'did not send it. Nothing about your order has changed.',
          actionLabel: 'Show the current options',
          busy: state.refreshing,
          onAction: onRefresh,
        );

      case DeliveryRecoveryNotice.acknowledgementRequired:
        return _NoticeCard(
          noticeKey: const Key('recovery-notice-acknowledgement'),
          tone: MallStatusTone.caution,
          icon: Icons.info_outline_rounded,
          title: 'We still need your confirmation',
          body:
              'Before we cancel anything you have to confirm you understand '
              'when your money comes back. Nothing has been sent.',
          actionLabel: null,
          busy: false,
          onAction: onRefresh,
        );

      case DeliveryRecoveryNotice.failed:
        return MallErrorState(
          key: const Key('recovery-notice-failed'),
          title: 'We could not put that through',
          body:
              'Nothing about your order has changed. Try again — we reuse the '
              'same request, so trying twice cannot cancel twice or open two '
              'support tickets.',
          onRetry: state.isAccepting ? null : onRetry,
        );
    }
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.noticeKey,
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
  });

  final Key noticeKey;
  final MallStatusTone tone;
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final bool busy;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    return Column(
      key: noticeKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MallStatusSummary(
          title: title,
          tone: tone,
          icon: icon,
          detail: body,
        ),
        if (label != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Semantics(
            button: true,
            enabled: !busy,
            label: label,
            excludeSemantics: true,
            child: OutlinedButton(
              key: const Key('recovery-notice-action'),
              onPressed: busy ? null : onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.textWhite,
                side: const BorderSide(color: DesignTokens.borderDefault),
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ],
      ],
    );
  }
}

/// Result of the confirmation step. [acknowledged] is only ever true because
/// the customer ticked the box themselves.
class _ConfirmResult {
  const _ConfirmResult({required this.confirmed, required this.acknowledged});

  final bool confirmed;
  final bool acknowledged;
}

/// The second, deliberate step in front of a remedy that moves money or that
/// this build does not recognise. Cancelling for a refund is irreversible,
/// so it cannot be reached by one unconsidered tap.
class _ConfirmRemedySheet extends StatefulWidget {
  const _ConfirmRemedySheet({required this.offer});

  final DeliveryRecoveryOffer offer;

  @override
  State<_ConfirmRemedySheet> createState() => _ConfirmRemedySheetState();
}

class _ConfirmRemedySheetState extends State<_ConfirmRemedySheet> {
  /// Never pre-ticked. The acknowledgement is the customer's, not ours.
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final copy = DeliveryRemedyCopy.of(offer);
    final needsAck = offer.requiresRefundWindowAcknowledgement;
    final canConfirm = !needsAck || _acknowledged;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  copy.confirmTitle,
                  style: DesignTokens.titleMedium,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              for (final line in copy.confirmBody) ...[
                Text(
                  line,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
              ],
              if (needsAck) ...[
                const SizedBox(height: DesignTokens.s4),
                Semantics(
                  checked: _acknowledged,
                  label: _refundWindowAcknowledgement,
                  excludeSemantics: true,
                  child: CheckboxListTile(
                    key: const Key('recovery-ack-checkbox'),
                    value: _acknowledged,
                    onChanged: (value) =>
                        setState(() => _acknowledged = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: DesignTokens.primaryGreen,
                    title: const Text(
                      _refundWindowAcknowledgement,
                      style: DesignTokens.smallRegular,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.s12),
              Semantics(
                button: true,
                enabled: canConfirm,
                label: copy.confirmCtaSemantics,
                excludeSemantics: true,
                child: FilledButton(
                  key: const Key('recovery-confirm-cta'),
                  onPressed: canConfirm
                      ? () => Navigator.of(context).pop(
                          _ConfirmResult(
                            confirmed: true,
                            acknowledged: _acknowledged,
                          ),
                        )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: copy.destructive
                        ? DesignTokens.colorError
                        : DesignTokens.primaryGreen,
                    foregroundColor: copy.destructive
                        ? DesignTokens.textWhite
                        : DesignTokens.baseBlack,
                    disabledBackgroundColor: DesignTokens.bgAppBodyLight,
                    disabledForegroundColor: DesignTokens.textMuted,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    copy.confirmCtaLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              Semantics(
                button: true,
                label: copy.dismissLabel,
                excludeSemantics: true,
                child: TextButton(
                  key: const Key('recovery-dismiss-cta'),
                  onPressed: () => Navigator.of(context).pop(
                    const _ConfirmResult(
                      confirmed: false,
                      acknowledged: false,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textLight,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(copy.dismissLabel, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The one sentence the customer actively confirms before a cancellation.
const String _refundWindowAcknowledgement =
    'I understand my refund takes 5 to 7 working days to reach me.';

/// What the customer is told once a remedy has actually been carried out.
class DeliveryRemedyAcceptedCopy {
  const DeliveryRemedyAcceptedCopy(this.title, this.detail);

  final String title;
  final String detail;
}

// Kept as named constants so the confirmation body reads as a list of
// sentences rather than adjacent string literals inside a list.
const String _cancelIrreversibleLine =
    'This cannot be undone. The delivery stops for good and the order '
    'cannot be restarted — you would have to buy the items again.';

const String _cancelMoneyLine =
    'You get the full amount back, to the way you paid. Refunds take 5 to '
    '7 working days to reach you once the cancellation is confirmed.';

const String _supportConfirmLine =
    'Someone will look at this delivery and come back to you. Your order '
    'and your money are untouched.';

/// Customer-facing wording per remedy. An unrecognised remedy falls back to
/// the backend's own `description`, so a value added after this build
/// shipped still renders a usable, honest card instead of a blank one.
class DeliveryRemedyCopy {
  const DeliveryRemedyCopy({
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.ctaSemantics,
    required this.confirmTitle,
    required this.confirmBody,
    required this.confirmCtaLabel,
    required this.confirmCtaSemantics,
    required this.dismissLabel,
    required this.destructive,
  });

  factory DeliveryRemedyCopy.of(DeliveryRecoveryOffer offer) {
    final description = offer.description.isEmpty
        ? 'We can act on this delivery for you.'
        : offer.description;

    switch (offer.remedy) {
      case DeliveryRemedyKind.cancelForRefund:
        return DeliveryRemedyCopy(
          title: 'Cancel this delivery and refund me',
          body: description,
          ctaLabel: 'Cancel and refund',
          ctaSemantics:
              'Cancel this delivery and start a refund. Opens a '
              'confirmation first.',
          confirmTitle: 'Cancel this delivery and refund you?',
          confirmBody: const [_cancelIrreversibleLine, _cancelMoneyLine],
          confirmCtaLabel: 'Yes, cancel and refund',
          confirmCtaSemantics:
              'Confirm. Cancel this delivery for good and start the refund.',
          dismissLabel: 'Keep waiting for my delivery',
          destructive: true,
        );

      case DeliveryRemedyKind.prioritySupportReview:
        return DeliveryRemedyCopy(
          title: 'Put a person on this',
          body: description,
          ctaLabel: 'Ask support to step in',
          ctaSemantics:
              'Ask a support person to take over this delivery. '
              'Nothing is cancelled.',
          confirmTitle: 'Ask support to step in?',
          confirmBody: const [_supportConfirmLine],
          confirmCtaLabel: 'Ask support to step in',
          confirmCtaSemantics: 'Confirm. Open a support review.',
          dismissLabel: 'Not now',
          destructive: false,
        );

      case DeliveryRemedyKind.unknown:
        // A remedy added after this build shipped: say only what the backend
        // said, and still make the customer confirm, because we cannot know
        // whether it moves money.
        return DeliveryRemedyCopy(
          title: 'Another option for this delivery',
          body: description,
          ctaLabel: 'Choose this option',
          ctaSemantics: 'Choose this option. Opens a confirmation first.',
          confirmTitle: 'Go ahead with this option?',
          confirmBody: [description],
          confirmCtaLabel: 'Yes, go ahead',
          confirmCtaSemantics: 'Confirm this option.',
          dismissLabel: 'Not now',
          destructive: false,
        );
    }
  }

  final String title;
  final String body;
  final String ctaLabel;
  final String ctaSemantics;
  final String confirmTitle;
  final List<String> confirmBody;
  final String confirmCtaLabel;
  final String confirmCtaSemantics;
  final String dismissLabel;
  final bool destructive;

  static DeliveryRemedyAcceptedCopy acceptedFor(DeliveryRecoveryOffer offer) {
    switch (offer.remedy) {
      case DeliveryRemedyKind.cancelForRefund:
        return const DeliveryRemedyAcceptedCopy(
          'Cancelled, and your refund is on its way',
          'The delivery has stopped. You get the full amount back, to the way '
              'you paid, within 5 to 7 working days.',
        );
      case DeliveryRemedyKind.prioritySupportReview:
        return const DeliveryRemedyAcceptedCopy(
          'Support has this delivery',
          'A person is looking at it now and will come back to you. Your '
              'order and your money are untouched.',
        );
      case DeliveryRemedyKind.unknown:
        return const DeliveryRemedyAcceptedCopy(
          'That is done',
          'We have put your choice through. Nothing else is needed from you.',
        );
    }
  }
}

/// "Open for another 12 minutes" — deliberately coarse. The moment the
/// window really closes the offer stops being tappable, so this line never
/// has to be second-accurate.
String remainingWindowLabel(Duration remaining) {
  if (remaining <= Duration.zero) return 'closed';
  if (remaining.inMinutes < 1) return 'open for under a minute';
  if (remaining.inMinutes == 1) return 'open for another minute';
  return 'open for another ${remaining.inMinutes} minutes';
}
