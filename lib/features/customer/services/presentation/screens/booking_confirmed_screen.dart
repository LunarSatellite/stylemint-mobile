import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// After booking: confirmed, or — for an online payment the provider has
/// not reported yet — waiting for it. The provider tells the server, not
/// this app, so the page reads the booking and can be refreshed.
class BookingConfirmedScreen extends ConsumerWidget {
  const BookingConfirmedScreen({required this.bookingId, super.key});

  final String bookingId;

  static const Key headlineKey = Key('booking-confirmed-headline');
  static const Key viewKey = Key('booking-confirmed-view');
  static const Key refreshKey = Key('booking-confirmed-refresh');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(myBookingProvider(bookingId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close),
            onPressed: () => context.go(RouteNames.services),
          ),
        ],
      ),
      body: SafeArea(
        child: booking.when(
          skipLoadingOnRefresh: false,
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this booking',
                onRetry: () => ref.invalidate(myBookingProvider(bookingId)),
              ),
            ],
          ),
          data: (b) => _body(context, ref, b),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Booking b) {
    final pending = b.state == BookingState.pendingPayment;
    final confirmed = b.state == BookingState.confirmed ||
        b.state == BookingState.checkedIn ||
        b.state == BookingState.completed;
    final (icon, colour, headline, line) = switch (b.state) {
      _ when confirmed => (
        Icons.check_circle_rounded,
        DesignTokens.primaryGreen,
        'Booking confirmed',
        b.balanceDue.amount > 0
            ? 'Pay ${serviceMoney(b.balanceDue)} at the venue.'
            : 'You have paid in full.',
      ),
      BookingState.pendingPayment => (
        Icons.hourglass_top_rounded,
        DesignTokens.colorWarning,
        'Waiting for your payment',
        'Finish paying on the payment page. We confirm the booking as soon '
            'as the payment arrives.',
      ),
      _ => (
        Icons.info_outline_rounded,
        DesignTokens.textMuted,
        b.state.label,
        'This booking is not active.',
      ),
    };
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s20),
      children: [
        Icon(icon, size: 64, color: colour),
        const SizedBox(height: DesignTokens.s12),
        Text(
          headline,
          key: headlineKey,
          textAlign: TextAlign.center,
          style: DesignTokens.h2,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          line,
          textAlign: TextAlign.center,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.s20),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(b.listingTitle, style: DesignTokens.mediumSemibold),
              if (b.roomTypeName != null)
                Text(
                  b.roomTypeName!,
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              const SizedBox(height: DesignTokens.s8),
              ServiceRow(label: 'Booking', value: b.number),
              ServiceRow(label: 'When', value: bookingDates(b)),
              ServiceRow(label: 'Who', value: bookingGuests(b)),
              ServiceRow(label: 'Total', value: serviceMoney(b.totalPrice)),
              ServiceRow(
                label: 'Paid online',
                value: serviceMoney(b.paidOnline),
                valueKey: const Key('booking-confirmed-paid'),
              ),
              ServiceRow(
                label: 'To pay at the venue',
                value: serviceMoney(b.balanceDue),
                valueKey: const Key('booking-confirmed-balance'),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s20),
        if (pending) ...[
          OutlinedButton(
            key: refreshKey,
            onPressed: () => refreshBookings(ref, bookingId: b.id),
            child: const Text('I have paid — check again'),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        ServicePrimaryButton(
          key: viewKey,
          label: 'View booking',
          onPressed: () =>
              context.pushReplacement(RouteNames.bookingDetailPath(b.id)),
        ),
      ],
    );
  }
}
