import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Sat, 2 Nov → Mon, 4 Nov · 2 nights" for a stay, "Departs 2 Nov 2026"
/// for a trip.
String serviceLineDates(ServiceLine l) {
  final end = l.endDate;
  if (l.isStay && end != null) {
    final nights = l.nights ?? end.difference(l.startDate).inDays;
    return '${serviceShortDate(l.startDate)} → ${serviceShortDate(end)}'
        ' · ${nights == 1 ? '1 night' : '$nights nights'}';
  }
  return 'Departs ${serviceDate(l.startDate)}';
}

/// "1 room · 2 adults" for a stay, "2 adults, 1 child" for a trip.
String serviceLineGuests(ServiceLine l) {
  String count(int n, String one, String many) => n == 1 ? '1 $one' : '$n $many';
  final people = [
    count(l.adults, 'adult', 'adults'),
    if (l.children > 0) count(l.children, 'child', 'children'),
  ].join(', ');
  final rooms = l.rooms;
  return l.isStay && rooms != null
      ? '${count(rooms, 'room', 'rooms')} · $people'
      : people;
}

/// How the line is paid, in the buyer's words.
String serviceLinePaymentLabel(ServiceLine l) => switch (l.paymentMode) {
  PaymentMode.fullPrepay => 'Paid in full online',
  PaymentMode.deposit =>
    '${paymentModesLine(const [PaymentMode.deposit], l.depositPercent)} '
        'online, rest at the venue',
  PaymentMode.payAtVenue => 'Pay at the venue',
  null => 'Payment',
};

/// A service line's options and money, as the cart, checkout and an order
/// show it: the room or trip, the dates, who is coming, then what is paid
/// online now and what is paid at the venue. [compact] leaves out the
/// cancellation policy.
class ServiceLineSummary extends StatelessWidget {
  const ServiceLineSummary({
    required this.line,
    this.compact = false,
    this.paidLabel = 'Pay now',
    super.key,
  });

  final ServiceLine line;
  final bool compact;

  /// "Pay now" in the cart and checkout, "Paid now" on an order.
  final String paidLabel;

  static Key datesKey(String id) => Key('service-line-dates-$id');
  static Key payNowKey(String id) => Key('service-line-pay-now-$id');
  static Key payAtVenueKey(String id) => Key('service-line-at-venue-$id');

  @override
  Widget build(BuildContext context) {
    final l = line;
    final id = l.lineId ?? l.bookingId ?? l.listingId;
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (l.itemName != null && l.itemName!.isNotEmpty)
          Text(l.itemName!, style: DesignTokens.smallRegular),
        Text(
          serviceLineDates(l),
          key: datesKey(id),
          style: DesignTokens.smallRegular,
        ),
        Text(serviceLineGuests(l), style: muted),
        const SizedBox(height: DesignTokens.s4),
        Text(serviceLinePaymentLabel(l), style: muted),
        ServiceRow(
          label: paidLabel,
          value: serviceMoney(l.payNow),
          valueKey: payNowKey(id),
        ),
        if (l.payAtVenue.amount > 0)
          ServiceRow(
            label: 'Pay at the venue',
            value: serviceMoney(l.payAtVenue),
            valueKey: payAtVenueKey(id),
          ),
        if (!compact && l.cancellationPolicySummary != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: Text(l.cancellationPolicySummary!, style: muted),
          ),
      ],
    );
  }
}
