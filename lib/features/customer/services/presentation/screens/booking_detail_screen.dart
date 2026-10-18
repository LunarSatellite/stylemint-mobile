import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// One booking: dates, guests, what was paid and what is due at the venue,
/// the cancellation policy, and Cancel — which first shows the server's
/// refund preview (fee and refund) and only cancels once the buyer agrees.
/// Where every buyer `booking.*` notification lands.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  static const Key cancelKey = Key('booking-cancel');
  static const Key payKey = Key('booking-pay');
  static const Key confirmCancelKey = Key('booking-cancel-confirm');
  static const Key keepKey = Key('booking-cancel-keep');
  static const Key previewFeeKey = Key('booking-cancel-fee');
  static const Key previewRefundKey = Key('booking-cancel-refund');
  static const Key errorKey = Key('booking-detail-error');

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;
  String? _error;

  /// One key per cancellation the buyer confirms; a retry reuses it.
  String _cancelKey = const Uuid().v4();
  String _payKey = const Uuid().v4();

  Future<void> _cancel(Booking booking) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(bookingsRepositoryProvider);
    final preview = await repo.cancellationQuote(booking.id);
    if (!mounted) return;
    final CancellationQuote? quote = preview.fold((failure) {
      setState(() {
        _busy = false;
        _error = serviceFailureMessage(failure, what: 'the refund');
      });
      return null;
    }, (q) => q);
    if (quote == null) return;
    setState(() => _busy = false);
    if (!quote.cancellable) {
      setState(
        () => _error = quote.reason == 'started'
            ? 'This booking has already started and can no longer be '
                  'cancelled here.'
            : 'This booking can no longer be cancelled.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServiceRow(
              label: 'Cancellation fee',
              value: serviceMoney(quote.fee),
              valueKey: BookingDetailScreen.previewFeeKey,
            ),
            ServiceRow(
              label: 'Refund to you',
              value: serviceMoney(quote.refundAmount),
              valueKey: BookingDetailScreen.previewRefundKey,
              emphasised: true,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              quote.fee.amount <= 0
                  ? 'You cancel for free.'
                  : quote.freeUntilDate == null
                  ? 'The free cancellation period has passed.'
                  : 'Free cancellation ended on '
                        '${serviceDate(quote.freeUntilDate!)}.',
              style: DesignTokens.tiny,
            ),
            if (quote.refundAmount.amount > 0)
              Text(
                'The refund goes back to how you paid.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            key: BookingDetailScreen.keepKey,
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep booking'),
          ),
          TextButton(
            key: BookingDetailScreen.confirmCancelKey,
            onPressed: () => Navigator.of(dialog).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
            ),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await repo.cancel(
      bookingId: booking.id,
      idempotencyKey: _cancelKey,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _busy = false;
        _error = serviceFailureMessage(failure, what: 'this booking');
      }),
      (_) {
        setState(() {
          _busy = false;
          _cancelKey = const Uuid().v4();
        });
        refreshBookings(ref, bookingId: booking.id);
      },
    );
  }

  Future<void> _pay(Booking booking) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(bookingsRepositoryProvider)
        .pay(
          bookingId: booking.id,
          rail: BookingPaymentRail.eSewa,
          idempotencyKey: _payKey,
        );
    if (!mounted) return;
    await result.fold(
      (failure) async => setState(() {
        _busy = false;
        _error = serviceFailureMessage(failure, what: 'the payment');
      }),
      (start) async {
        final uri = start.redirectUrl == null
            ? null
            : Uri.tryParse(start.redirectUrl!);
        if (uri != null) await ref.read(servicePaymentLauncherProvider)(uri);
        if (!mounted) return;
        setState(() => _busy = false);
        refreshBookings(ref, bookingId: booking.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(myBookingProvider(widget.bookingId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(booking.asData?.value.number ?? 'Booking'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            refreshBookings(ref, bookingId: widget.bookingId);
          },
          child: booking.when(
            loading: () => const SmPageLoader(),
            error: (error, _) => ListView(
              children: [
                ServiceFailureView(
                  error: error,
                  what: 'this booking',
                  onRetry: () =>
                      ref.invalidate(myBookingProvider(widget.bookingId)),
                ),
              ],
            ),
            data: _body,
          ),
        ),
      ),
    );
  }

  Widget _body(Booking b) {
    final stay = b.kind == ListingKind.stay;
    final refund = b.refundAmount;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            Expanded(child: Text(b.listingTitle, style: DesignTokens.h3)),
            BookingStateChip(state: b.state),
          ],
        ),
        if (b.roomTypeName != null)
          Text(
            b.roomTypeName!,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        if (b.vendor != null)
          Text(
            b.vendor!.name,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        const ServiceSectionTitle('Details'),
        ServiceCard(
          child: Column(
            children: [
              ServiceRow(label: 'Booking', value: b.number),
              ServiceRow(
                label: stay ? 'Dates' : 'Departure',
                value: bookingDates(b),
                valueKey: const Key('booking-detail-dates'),
              ),
              if (stay && b.nights != null)
                ServiceRow(
                  label: 'Nights',
                  value: '${b.nights}',
                ),
              ServiceRow(
                label: stay ? 'Guests' : 'Travellers',
                value: bookingGuests(b),
                valueKey: const Key('booking-detail-guests'),
              ),
              if (b.guestName != null)
                ServiceRow(label: 'Under the name', value: b.guestName!),
              if (stay && b.checkInTime != null)
                ServiceRow(label: 'Check-in from', value: b.checkInTime!),
              if (stay && b.checkOutTime != null)
                ServiceRow(label: 'Check-out by', value: b.checkOutTime!),
              if (b.meetingPoint != null)
                ServiceRow(label: 'Meeting point', value: b.meetingPoint!),
              if (b.addressLine != null || b.city != null)
                ServiceRow(
                  label: 'Address',
                  value: [?b.addressLine, ?b.city].join(', '),
                ),
            ],
          ),
        ),
        if (b.travellers.isNotEmpty) ...[
          const ServiceSectionTitle('Travellers'),
          ServiceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in b.travellers)
                  ServiceBullet(
                    '${t.fullName} · ${t.type.label}'
                    '${t.age == null ? '' : ' · ${t.age}'}',
                    icon: Icons.person_outline,
                    color: DesignTokens.textLight,
                  ),
              ],
            ),
          ),
        ],
        const ServiceSectionTitle('Payment'),
        ServiceCard(
          child: Column(
            children: [
              ServiceRow(label: 'Total', value: serviceMoney(b.totalPrice)),
              ServiceRow(label: 'How you pay', value: b.paymentMode.label),
              ServiceRow(
                label: 'Paid online',
                value: serviceMoney(b.paidOnline),
                valueKey: const Key('booking-detail-paid'),
              ),
              ServiceRow(
                label: 'Balance due at the venue',
                value: serviceMoney(b.balanceDue),
                valueKey: const Key('booking-detail-balance'),
                emphasised: b.balanceDue.amount > 0,
              ),
              if (b.cancellationFee != null && b.cancellationFee!.amount > 0)
                ServiceRow(
                  label: 'Cancellation fee',
                  value: serviceMoney(b.cancellationFee!),
                ),
              if (refund != null && refund.amount > 0)
                ServiceRow(
                  label: switch (b.refundState) {
                    RefundState.completed => 'Refunded',
                    RefundState.failed => 'Refund (being retried)',
                    _ => 'Refund on its way',
                  },
                  value: serviceMoney(refund),
                  valueKey: const Key('booking-detail-refund'),
                ),
            ],
          ),
        ),
        if (b.state == BookingState.pendingPayment && b.holdExpiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              'Pay by ${serviceInstant(b.holdExpiresAt!)} or the booking '
              'is released.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorWarning),
            ),
          ),
        const ServiceSectionTitle('Cancellation policy'),
        Text(
          b.cancellationPolicy.describe(),
          key: const Key('booking-detail-policy'),
          style: DesignTokens.smallRegular,
        ),
        if (b.state == BookingState.cancelled && b.cancelReason != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Cancelled${b.cancelledByBuyer ? ' by you' : ''}: ${b.cancelReason}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
        if (b.specialRequests != null) ...[
          const ServiceSectionTitle('Your requests'),
          Text(b.specialRequests!, style: DesignTokens.smallRegular),
        ],
        if (_error != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(
            _error!,
            key: BookingDetailScreen.errorKey,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s20),
        if (b.canPay) ...[
          ServicePrimaryButton(
            key: BookingDetailScreen.payKey,
            label: 'Pay ${serviceMoney(b.payNowAmount)} with eSewa',
            busy: _busy,
            onPressed: () => unawaited(_pay(b)),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        if (b.canCancel)
          OutlinedButton(
            key: BookingDetailScreen.cancelKey,
            onPressed: _busy ? null : () => unawaited(_cancel(b)),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
              side: const BorderSide(color: DesignTokens.colorError),
              minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
            ),
            child: const Text('Cancel booking'),
          ),
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}
