import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

ServicePillTone bookingTone(BookingState s) => switch (s) {
  BookingState.pendingPayment => ServicePillTone.warning,
  BookingState.confirmed => ServicePillTone.info,
  BookingState.checkedIn => ServicePillTone.success,
  BookingState.completed => ServicePillTone.success,
  BookingState.cancelled => ServicePillTone.neutral,
  BookingState.noShow => ServicePillTone.error,
  BookingState.expired => ServicePillTone.neutral,
};

/// "21 Oct → 23 Oct · 2 nights" for a stay, "2 Nov → 8 Nov" for a package.
String bookingDatesText(ServiceBooking b) {
  final start = b.startDate, end = b.endDate;
  if (start == null) return '';
  final range = end == null || daysBetween(start, end) == 0
      ? serviceShortDateText(start)
      : '${serviceShortDateText(start)} → ${serviceShortDateText(end)}';
  if (b.isStay && b.nights > 0) {
    return '$range · ${b.nights} ${b.nights == 1 ? 'night' : 'nights'}';
  }
  return range;
}

/// One booking in a list.
class ServiceBookingTile extends StatelessWidget {
  const ServiceBookingTile({required this.booking, super.key});

  static Key keyFor(String id) => Key('service-booking-tile-$id');

  final ServiceBooking booking;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    final item = b.isStay
        ? [
            if (b.rooms > 1) '${b.rooms} ×',
            b.itemName,
          ].join(' ')
        : b.listingTitle;
    return InkWell(
      key: keyFor(b.id),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(ServiceRoutes.bookingPath(b.id)),
      child: ServiceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.guestName,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                ServicePill(
                  b.state.labelFor(b.kind),
                  tone: bookingTone(b.state),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              item,
              style: DesignTokens.smallRegular,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              [
                bookingDatesText(b),
                if (b.guestsText.isNotEmpty) b.guestsText,
              ].where((s) => s.isNotEmpty).join(' · '),
              style: muted,
            ),
            Row(
              children: [
                Expanded(child: Text(b.number, style: muted)),
                if (b.hasBalanceToCollect && b.state.isLive)
                  Text(
                    'Collect ${serviceMoney(b.balanceDue)}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.colorWarning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
