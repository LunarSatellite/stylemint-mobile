import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

Color bookingStateColor(BookingState s) => switch (s) {
  BookingState.pendingPayment => DesignTokens.colorWarning,
  BookingState.confirmed => DesignTokens.primaryGreen,
  BookingState.checkedIn => DesignTokens.colorInfo,
  BookingState.completed => DesignTokens.colorSuccess,
  BookingState.cancelled => DesignTokens.textMuted,
  BookingState.noShow => DesignTokens.colorError,
  BookingState.expired => DesignTokens.textMuted,
};

class BookingStateChip extends StatelessWidget {
  const BookingStateChip({required this.state, super.key});

  final BookingState state;

  @override
  Widget build(BuildContext context) =>
      ServiceChip(label: state.label, color: bookingStateColor(state));
}

/// "Sat, 24 Oct → Mon, 26 Oct" for a stay, "Departs 2 Nov 2026" for a trip.
String bookingDates(Booking b) {
  final end = b.endDate;
  if (b.kind == ListingKind.stay && end != null) {
    return '${serviceShortDate(b.startDate)} → ${serviceShortDate(end)}';
  }
  return 'Departs ${serviceDate(b.startDate)}';
}

String bookingGuests(Booking b) {
  final who = b.kind == ListingKind.stay ? 'guest' : 'traveller';
  final n = b.guests;
  final base = n == 1 ? '1 $who' : '$n ${who}s';
  final rooms = b.rooms;
  return b.kind == ListingKind.stay && rooms != null && rooms > 1
      ? '$base · $rooms rooms'
      : base;
}

/// One booking in a list: title, booking reference, dates, state.
class BookingTile extends StatelessWidget {
  const BookingTile({required this.booking, required this.onTap, super.key});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return InkWell(
      key: Key('booking-tile-${b.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: onTap,
      child: ServiceCard(
        child: Row(
          children: [
            Icon(
              b.kind == ListingKind.stay
                  ? Icons.hotel_outlined
                  : Icons.terrain_outlined,
              color: DesignTokens.textLight,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.listingTitle,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Booking ${b.number}',
                    key: Key('booking-tile-ref-${b.id}'),
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                  Text(
                    '${bookingDates(b)} · ${bookingGuests(b)}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  if (b.balanceDue.amount > 0 && b.state.isLive)
                    Text(
                      '${serviceMoney(b.balanceDue)} to pay at the venue',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            BookingStateChip(state: b.state),
          ],
        ),
      ),
    );
  }
}

/// The ways to pay a listing allows, as short labels.
String paymentModesLine(List<PaymentMode> modes, double depositPercent) {
  String pct(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}%' : '${v.toStringAsFixed(1)}%';
  return [
    for (final m in modes)
      switch (m) {
        PaymentMode.fullPrepay => 'Pay online',
        PaymentMode.deposit => '${pct(depositPercent)} deposit',
        PaymentMode.payAtVenue => 'Pay at venue',
      },
  ].join(' · ');
}
