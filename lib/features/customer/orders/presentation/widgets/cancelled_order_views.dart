import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
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
// NOTE: the history events and their stamps below are derived from the order's
// `placedAt`, not sent by the API. That predates this work and is unchanged
// here; only how it is drawn has changed.

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
class CancellationDetailsCard extends StatelessWidget {
  const CancellationDetailsCard({
    required this.order,
    required this.cancelledAt,
    super.key,
  });

  final OrderDetail? order;
  final DateTime cancelledAt;

  @override
  Widget build(BuildContext context) {
    final cancelledStr = DateFormat('HH:mm MMM d, yyyy').format(cancelledAt);
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

/// The three stages a cancelled order got through, with the stop marked as a
/// stop: `failed`, not "current", so a cross ends the rail.
class CancelledTrackingStepper extends StatelessWidget {
  const CancelledTrackingStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tracking Timeline',
            style: DesignTokens.sectionInnerTitle,
          ),
          SizedBox(height: DesignTokens.s16),
          MallStatusStepper(
            semanticLabel: 'Tracking timeline',
            steps: [
              MallTimelineStep(
                title: 'Shipped',
                state: MallStepState.done,
                markKey: ValueKey('delivery-stage-icon-0'),
              ),
              MallTimelineStep(
                title: 'In transit',
                state: MallStepState.done,
                markKey: ValueKey('delivery-stage-icon-1'),
              ),
              MallTimelineStep(
                title: 'Order cancelled',
                state: MallStepState.failed,
                markKey: ValueKey('delivery-stage-icon-2'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The order's event history, newest first, on the kit's vertical rail.
class CancelledOrderHistory extends StatelessWidget {
  const CancelledOrderHistory({
    required this.order,
    required this.cancelledAt,
    super.key,
    this.note,
  });

  final OrderDetail? order;
  final DateTime cancelledAt;

  /// The buyer's own reason, when they gave one.
  final String? note;

  List<_OrderEvent> _buildEvents() {
    final fmt = DateFormat('dd MMM, HH:mm');
    final placed =
        order?.placedAt ?? cancelledAt.subtract(const Duration(days: 3));
    final reason = note;
    return [
      _OrderEvent(
        icon: Icons.cancel_outlined,
        state: MallStepState.failed,
        title: 'Order cancelled',
        subItems: [
          _SubItem(
            text: (reason != null && reason.isNotEmpty)
                ? reason
                : 'The customer cancelled the order',
            time: fmt.format(cancelledAt),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.local_shipping_outlined,
        state: MallStepState.done,
        title: 'In transit',
        subItems: [
          _SubItem(
            text:
                'The package has crossed the transit and is on its way to be '
                'delivered',
            time: fmt.format(
              placed.add(const Duration(days: 2, hours: 2, minutes: 15)),
            ),
          ),
          _SubItem(
            text: 'The package is being checked in the transit',
            time: fmt.format(placed.add(const Duration(days: 2))),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.inventory_2_outlined,
        state: MallStepState.done,
        title: 'Shipped',
        subItems: [
          _SubItem(
            text: 'The package has been shipped',
            time: fmt.format(placed.add(const Duration(hours: 23, minutes: 5))),
          ),
          _SubItem(
            text: 'The package is in the shipping lane',
            time: fmt.format(
              placed.add(const Duration(hours: 22, minutes: 30)),
            ),
          ),
          _SubItem(
            text:
                'The package is being tagged with the shipping address details',
            time: fmt.format(
              placed.add(const Duration(hours: 22, minutes: 20)),
            ),
          ),
          _SubItem(
            text: 'Order items are being gathered & packaged for shipping',
            time: fmt.format(placed.add(const Duration(hours: 21))),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.assignment_turned_in_outlined,
        state: MallStepState.done,
        title: 'Order confirmed',
        subItems: [
          _SubItem(
            text: 'Order was confirmed',
            time: fmt.format(placed.add(const Duration(minutes: 1))),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.shopping_bag_outlined,
        state: MallStepState.done,
        title: 'Order placed',
        subItems: [
          _SubItem(text: 'Order was placed', time: fmt.format(placed)),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: MallTimeline(
        semanticLabel: 'Order history',
        steps: [
          for (final event in events)
            MallTimelineStep(
              title: event.title,
              state: event.state,
              icon: event.icon,
              trailing: Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final item in event.subItems) _SubItemRow(item: item),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubItemRow extends StatelessWidget {
  const _SubItemRow({required this.item});

  final _SubItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${item.text}. ${item.time}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: SizedBox.square(
                dimension: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: DesignTokens.dotSeparator,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            // The stamp sits under the line rather than beside it: inside a
            // timeline's indented column there is no room for both at 1.3x,
            // and a truncated timestamp is worse than a second line.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                  Text(
                    item.time,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontFeatures: mallTabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderEvent {
  const _OrderEvent({
    required this.icon,
    required this.state,
    required this.title,
    required this.subItems,
  });

  final IconData icon;
  final MallStepState state;
  final String title;
  final List<_SubItem> subItems;
}

class _SubItem {
  const _SubItem({required this.text, required this.time});

  final String text;
  final String time;
}
