import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_event_history.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// The cancelled-order view, once.
//
// Order Detail and Cancel Order had each grown their own copy of these four
// blocks — same layout, same copy, and three different reds between them. One
// implementation now serves both, built on the Mall kit: the state is a
// summary with a glyph, the money is a ledger, and the stages are the kit's
// stepper and timeline, so "cancelled" is a cross on a rail rather than a
// slightly redder square.
//
// The history and the stage rail are now read from
// `GET /v1/orders/{orderNumber}/events`, which is a log of what was recorded
// rather than a ladder of what usually happens. Both blocks render exactly
// the events the endpoint returns, in the order it returns them, using its
// own `statement` sentences — nothing is rephrased, inferred, padded or
// timed by arithmetic. An order that never shipped therefore shows no
// shipping event, and that is the point.
//
// `sources` tells the two kinds of silence apart: `empty` means the source
// was read and had nothing to say, `unavailable` means the read failed. The
// second one is said out loud, because a customer reads an unexplained gap
// as fact.

/// Headline for a cancelled order: the state, then where the money went.
class CancelledOrderSummary extends StatelessWidget {
  const CancelledOrderSummary({required this.order, super.key});

  final OrderDetail? order;

  @override
  Widget build(BuildContext context) {
    final detail = order;
    final placed = detail == null
        ? null
        : DateFormat('HH:mm MMM d, yyyy').format(detail.placedAt);
    final tracking = detail?.trackingNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MallStatusSummary(
          eyebrow: 'Order #${detail?.orderNumber ?? '—'}',
          title: 'Cancelled',
          tone: MallStatusTone.danger,
          detail: 'Nothing is on its way. Your money is coming back.',
          footnote: placed == null ? null : 'Placed $placed',
        ),
        if (detail != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            // A cancelled order leaves exactly one question. It gets the
            // ledger, not a line of grey body copy.
            child: MallMoneyLedger(
              semanticLabel: 'Refund',
              amounts: [
                MallAmount(
                  label: 'Order total',
                  value: formatMoney(detail.total),
                ),
                MallAmount(
                  label: 'Refund',
                  value: formatMoney(detail.total),
                  kind: MallAmountKind.refund,
                  note: 'Back to ${detail.paymentMethod}',
                ),
              ],
            ),
          ),
        ],
        if (tracking != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Tracking ID $tracking',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontFeatures: mallTabularFigures,
            ),
          ),
        ],
      ],
    );
  }
}

/// When it was cancelled, how the money comes back, and where that stands.
///
/// [cancelledAt] is passed only by the screen that just performed the cancel
/// and therefore knows the moment first-hand. Everywhere else it is left null
/// and the time comes off the recorded `cancelled` event; when no such record
/// exists the row says so rather than offering an arithmetic guess.
class CancellationDetailsCard extends ConsumerWidget {
  const CancellationDetailsCard({
    required this.order,
    super.key,
    this.cancelledAt,
  });

  final OrderDetail? order;
  final DateTime? cancelledAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var resolved = cancelledAt;
    final number = order?.orderNumber.trim();
    if (resolved == null && number != null && number.isNotEmpty) {
      resolved = ref
          .watch(orderEventHistoryProvider(number))
          .maybeWhen(
            data: (history) => history.events
                .where((e) => e.code == 'cancelled')
                .map((e) => e.occurredUtc)
                .nonNulls
                .firstOrNull,
            orElse: () => null,
          );
    }
    final cancelledStr = resolved == null
        ? 'Not recorded'
        : DateFormat('HH:mm MMM d, yyyy').format(resolved.toLocal());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancellation Details',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s12),
          _CancDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Cancelled on',
            value: cancelledStr,
          ),
          _CancDetailRow(
            icon: Icons.credit_card_outlined,
            label: 'Refund method',
            value: order?.paymentMethod ?? '—',
          ),
          const _CancDetailRow(
            icon: Icons.mail_outline,
            label: 'Confirmation',
            value: 'Check your email',
          ),
          const _CancDetailRow(
            icon: Icons.label_outline,
            label: 'Refund status',
            badge: 'Pending',
          ),
        ],
      ),
    );
  }
}

class _CancDetailRow extends StatelessWidget {
  const _CancDetailRow({
    required this.icon,
    required this.label,
    this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final valueText = value;
    final badgeText = badge;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 2, end: 8),
            child: Icon(icon, size: 14, color: DesignTokens.textMuted),
          ),
          Expanded(
            child: Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          if (valueText != null)
            Flexible(
              child: Text(
                valueText,
                textAlign: TextAlign.end,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                  fontWeight: FontWeight.w500,
                  fontFeatures: mallTabularFigures,
                ),
              ),
            ),
          if (badgeText != null)
            MallStatusPill(
              label: badgeText,
              tone: MallStatusTone.caution,
              icon: Icons.schedule_rounded,
              dense: true,
            ),
        ],
      ),
    );
  }
}

/// One card that reads the order's recorded events once, and hands them to
/// its [builder]. Both the stage rail and the history use it, so the two
/// blocks never disagree and the endpoint is read once per screen.
///
/// A failed read is contained here: the card says the history could not be
/// loaded and the rest of the order detail carries on untouched.
class _OrderEventsCard extends ConsumerWidget {
  const _OrderEventsCard({
    required this.orderNumber,
    required this.title,
    required this.builder,
    this.emptyChild,
    this.speaksForFailure = true,
  });

  final String? orderNumber;
  final String title;
  final Widget Function(BuildContext, OrderEventHistory) builder;

  /// Rendered instead of the card when there is nothing to draw.
  final Widget? emptyChild;

  /// Whether this card is the one that reports a failed read. Only one block
  /// per screen should: two cards both saying "history unavailable" reads as
  /// two things being broken.
  final bool speaksForFailure;

  Widget _shell(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: DesignTokens.cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s16),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final number = orderNumber?.trim();
    // No order number is the same situation as a failed read: we cannot ask,
    // so we say we do not know rather than drawing a plausible history.
    if (number == null || number.isEmpty) {
      return speaksForFailure
          ? _shell(const _HistoryUnreadable())
          : (emptyChild ?? const SizedBox.shrink());
    }
    final quiet = emptyChild ?? const SizedBox.shrink();
    return ref
        .watch(orderEventHistoryProvider(number))
        .when(
          loading: () =>
              speaksForFailure ? _shell(const _HistoryLoading()) : quiet,
          error: (_, _) =>
              speaksForFailure ? _shell(const _HistoryUnreadable()) : quiet,
          data: (history) {
            final child = builder(context, history);
            if (child is SizedBox && child.child == null) {
              return emptyChild ?? const SizedBox.shrink();
            }
            return _shell(child);
          },
        );
  }
}

class _HistoryLoading extends StatelessWidget {
  const _HistoryLoading();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading this order’s history',
    excludeSemantics: true,
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            'Reading this order’s history…',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The read failed. This deliberately claims nothing about the order: it is
/// the same wording as an `unavailable` source, because it is the same fact.
class _HistoryUnreadable extends StatelessWidget {
  const _HistoryUnreadable();

  @override
  Widget build(BuildContext context) => const _SourceNotice(
    label: 'History unavailable',
    note:
        'We could not read this order’s history. Nothing here is missing '
        'from the order itself — try again in a moment.',
  );
}

/// A source that could not be read, or a whole history that could not be
/// read. Caution tone and a question mark: the customer is being told we do
/// not know, which is not the same as being told nothing happened.
class _SourceNotice extends StatelessWidget {
  const _SourceNotice({required this.label, required this.note});

  final String label;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MallStatusPill(
            label: label,
            tone: MallStatusTone.caution,
            icon: Icons.help_outline_rounded,
            dense: true,
          ),
          const SizedBox(height: DesignTokens.s6),
          Text(
            note,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Every source was read and had nothing to add. Neutral, and stated as a
/// fact, because here it *is* one.
class _NothingRecorded extends StatelessWidget {
  const _NothingRecorded();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const MallStatusPill(
        label: 'Nothing recorded',
        tone: MallStatusTone.neutral,
        icon: Icons.remove_rounded,
        dense: true,
      ),
      const SizedBox(height: DesignTokens.s6),
      Text(
        'Nothing has been recorded against this order.',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
    ],
  );
}

/// The notices for whichever sources could not be trusted at face value.
/// `ok` and `empty` sources say nothing at all — there is nothing to say.
class _SourceNotices extends StatelessWidget {
  const _SourceNotices({required this.history});

  final OrderEventHistory history;

  @override
  Widget build(BuildContext context) {
    final unavailable = history.unavailableSources;
    final unverified = history.unverifiedSources;
    if (unavailable.isEmpty && unverified.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final source in unavailable)
          _SourceNotice(
            label: 'History may be incomplete',
            note:
                source.note ??
                'One of the records behind this order could not be read, so '
                    'some events may be missing.',
          ),
        for (final source in unverified)
          _SourceNotice(
            label: 'Could not be verified',
            note:
                source.note ??
                'One of the records behind this order failed its integrity '
                    'check. Its entries are shown below, flagged.',
          ),
      ],
    );
  }
}

/// Short rail labels, keyed off the event's stable `code`. These are an index
/// of which milestones have a record — the customer-facing sentence is the
/// event's own `statement`, rendered verbatim in the history below. Codes
/// without a label here are not milestones and stay out of the rail; they are
/// still in the history.
const Map<String, String> _railLabels = {
  'order_placed': 'Placed',
  'payment_confirmed': 'Paid',
  'packed': 'Packed',
  'handed_to_courier': 'Shipped',
  'in_transit': 'In transit',
  'out_for_delivery': 'Out for delivery',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'returned': 'Returned',
};

IconData? _iconFor(String code) => switch (code) {
  'order_placed' => Icons.shopping_bag_outlined,
  'payment_confirmed' => Icons.payments_outlined,
  'seller_accepted' => Icons.assignment_turned_in_outlined,
  'packed' => Icons.inventory_2_outlined,
  'handed_to_courier' => Icons.local_shipping_outlined,
  'in_transit' => Icons.local_shipping_outlined,
  'out_for_delivery' => Icons.moving_outlined,
  'delivered' => Icons.check_circle_outline_rounded,
  'refund_started' || 'refund_completed' => Icons.south_west_rounded,
  _ => null,
};

/// The milestones this order actually reached, as a rail.
///
/// Every rung is an event with a record behind it. An order that was never
/// handed to a courier has no "Shipped" rung — there is no such thing here as
/// a stage that is drawn because it usually comes next.
class CancelledTrackingStepper extends StatelessWidget {
  const CancelledTrackingStepper({required this.orderNumber, super.key});

  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    return _OrderEventsCard(
      orderNumber: orderNumber,
      title: 'Tracking Timeline',
      // A rail with no milestones is not worth a card of its own; the history
      // card below already carries the notices and the full log.
      emptyChild: const SizedBox.shrink(),
      speaksForFailure: false,
      builder: (context, history) {
        final milestones = history.events
            .where((e) => _railLabels.containsKey(e.code))
            .toList(growable: false);
        if (milestones.isEmpty) return const SizedBox.shrink();
        return MallStatusStepper(
          semanticLabel: 'Tracking timeline',
          steps: [
            for (var i = 0; i < milestones.length; i++)
              MallTimelineStep(
                title: _railLabels[milestones[i].code]!,
                state: milestones[i].isStop
                    ? MallStepState.failed
                    : MallStepState.done,
                markKey: ValueKey('delivery-stage-icon-$i'),
              ),
          ],
        );
      },
    );
  }
}

/// The order's recorded events, in the order the endpoint returned them.
///
/// Each row is one `statement`, verbatim, with the stamp that came off the
/// record that proves it. No row is inferred from a neighbour, no stamp is
/// computed from another, and a sparse history renders sparsely.
class CancelledOrderHistory extends StatelessWidget {
  const CancelledOrderHistory({required this.orderNumber, super.key});

  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM, HH:mm');
    return _OrderEventsCard(
      orderNumber: orderNumber,
      title: 'Order History',
      builder: (context, history) {
        if (history.events.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Only a fully-read history may claim that nothing happened.
              if (history.isComplete) const _NothingRecorded(),
              _SourceNotices(history: history),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MallTimeline(
              semanticLabel: 'Order history',
              steps: [
                for (final event in history.events)
                  MallTimelineStep(
                    title: event.statement,
                    state: event.isStop
                        ? MallStepState.failed
                        : MallStepState.done,
                    icon: _iconFor(event.code),
                    // A stamp we did not receive is left off rather than
                    // stood in for.
                    timestamp: event.occurredUtc == null
                        ? null
                        : fmt.format(event.occurredUtc!.toLocal()),
                    detail: event.detail,
                    trailing: history.isSourceUnverified(event.source)
                        ? const Padding(
                            padding: EdgeInsets.only(top: DesignTokens.s6),
                            child: MallStatusPill(
                              label: 'Unverified',
                              tone: MallStatusTone.caution,
                              icon: Icons.gpp_maybe_outlined,
                              dense: true,
                            ),
                          )
                        : null,
                  ),
              ],
            ),
            _SourceNotices(history: history),
          ],
        );
      },
    );
  }
}
