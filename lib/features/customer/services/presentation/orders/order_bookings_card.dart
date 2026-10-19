import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_line_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// An order's stays and trips (service cart contract v1 §4.1): each booking's
/// reference and state, its dates and guests, what was paid now and what is
/// due at the venue. "View booking" opens the booking, where it is cancelled
/// under its own policy with the refund shown first (§4.2) — the order's
/// cancel never touches a booking.
///
/// Draws nothing for an order with no bookings.
class OrderBookingsCard extends StatelessWidget {
  const OrderBookingsCard({required this.lines, this.payAtVenue, super.key});

  final List<ServiceLine> lines;

  /// The order's total still to pay at the venue.
  final Money? payAtVenue;

  static const Key cardKey = Key('order-bookings');
  static Key openKey(String bookingId) => Key('order-booking-open-$bookingId');
  static Key cancelKey(String bookingId) =>
      Key('order-booking-cancel-$bookingId');
  static Key referenceKey(String bookingId) =>
      Key('order-booking-ref-$bookingId');

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: cardKey,
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lines.length == 1 ? 'Your booking' : 'Your bookings',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          for (final l in lines) ...[
            _BookingLine(line: l),
            const SizedBox(height: DesignTokens.s8),
          ],
          if (payAtVenue case final due? when due.amount > 0)
            ServiceRow(
              label: 'Still to pay at the venue',
              value: serviceMoney(due),
              valueKey: const Key('order-pay-at-venue'),
              emphasised: true,
            ),
        ],
      ),
    );
  }
}

class _BookingLine extends StatelessWidget {
  const _BookingLine({required this.line});

  final ServiceLine line;

  @override
  Widget build(BuildContext context) {
    final l = line;
    final bookingId = l.bookingId;
    final state = l.bookingState;
    void open() {
      if (bookingId == null) return;
      unawaited(context.push(RouteNames.bookingDetailPath(bookingId)));
    }

    return ServiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                l.isStay ? Icons.hotel_outlined : Icons.terrain_outlined,
                color: DesignTokens.textLight,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(l.listingTitle, style: DesignTokens.mediumSemibold),
              ),
              if (state != null) BookingStateChip(state: state),
            ],
          ),
          if (l.bookingNumber != null)
            Text(
              'Booking ${l.bookingNumber}',
              key: OrderBookingsCard.referenceKey(bookingId ?? l.listingId),
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
            ),
          const SizedBox(height: DesignTokens.s4),
          ServiceLineSummary(line: l, paidLabel: 'Paid now'),
          if (l.guestName != null)
            Text(
              'Under the name ${l.guestName}',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          if (bookingId != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              children: [
                OutlinedButton(
                  key: OrderBookingsCard.openKey(bookingId),
                  onPressed: open,
                  child: const Text('View booking'),
                ),
                if (l.canCancel)
                  // The booking page shows the fee and refund first, and
                  // only cancels once the buyer agrees.
                  TextButton(
                    key: OrderBookingsCard.cancelKey(bookingId),
                    onPressed: open,
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.colorError,
                    ),
                    child: const Text('Cancel booking'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
