import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/shared/booking_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One booking: who is coming (names only), when, what they booked, the
/// money (paid online, still to collect), and the day's actions — check in,
/// mark completed, no-show, mark balance received, cancel with the refund
/// shown first.
class VendorBookingDetailScreen extends ConsumerStatefulWidget {
  const VendorBookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  static const Key checkInKey = Key('vendor-booking-check-in');
  static const Key completeKey = Key('vendor-booking-complete');
  static const Key noShowKey = Key('vendor-booking-no-show');
  static const Key balanceKey = Key('vendor-booking-balance');
  static const Key cancelKey = Key('vendor-booking-cancel');
  static const Key balanceAmountKey = Key('vendor-booking-balance-amount');
  static const Key balanceConfirmKey = Key('vendor-booking-balance-confirm');
  static const Key cancelRefundKey = Key('vendor-booking-cancel-refund');
  static const Key cancelReasonKey = Key('vendor-booking-cancel-reason');
  static const Key cancelConfirmKey = Key('vendor-booking-cancel-confirm');

  @override
  ConsumerState<VendorBookingDetailScreen> createState() =>
      _VendorBookingDetailScreenState();
}

class _VendorBookingDetailScreenState
    extends ConsumerState<VendorBookingDetailScreen> {
  bool _busy = false;
  ServiceBooking? _updated;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(
    Future<Either<ServiceFailure, ServiceBooking>> Function(
      VendorBookingsRepository repo,
    )
    action,
    String done,
  ) async {
    setState(() => _busy = true);
    final result = await action(ref.read(vendorBookingsRepositoryProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (f) => _toast(serviceFailureMessage(f, specific: bookingErrorMessage)),
      (b) {
        setState(() => _updated = b);
        ref.invalidate(vendorBookingsTodayProvider);
        ref.invalidate(vendorBookingsUpcomingProvider);
        ref.invalidate(vendorBookingsSummaryProvider);
        _toast(done);
      },
    );
  }

  Future<void> _noShow(ServiceBooking b) async {
    final ok = await confirmServiceAction(
      context,
      title: 'Mark as no-show?',
      message:
          '${b.guestName} did not arrive. Anything paid online is kept '
          'under the booking\'s terms.',
      confirmLabel: 'Mark no-show',
    );
    if (!ok) return;
    await _run((repo) => repo.markNoShow(b.id), 'Marked as no-show.');
  }

  Future<void> _balance(ServiceBooking b) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _BalanceDialog(booking: b),
    );
    if (amount == null) return;
    await _run(
      (repo) => repo.markBalanceReceived(
        b.id,
        amount: amount >= b.balanceDue.amount ? null : amount,
      ),
      'Balance recorded.',
    );
  }

  Future<void> _cancel(ServiceBooking b) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelDialog(booking: b),
    );
    if (reason == null) return;
    await _run(
      (repo) => repo.cancel(b.id, reason),
      'Booking cancelled. The guest has been told.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(vendorBookingProvider(widget.bookingId));
    final value = _updated ?? booking.value;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(value?.number ?? 'Booking'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _updated = null);
            ref.invalidate(vendorBookingProvider(widget.bookingId));
            await ref.read(vendorBookingProvider(widget.bookingId).future);
          },
          child: switch ((value, booking.error)) {
            (final ServiceBooking b, _) => _body(b),
            (_, final Object error) => ListView(
              children: [
                ServiceLoadFailureView(
                  error: error,
                  settingUpTitle: 'Bookings are being set up',
                  fallback: 'We could not load this booking.',
                  specific: bookingErrorMessage,
                  onRetry: () =>
                      ref.invalidate(vendorBookingProvider(widget.bookingId)),
                ),
              ],
            ),
            _ => const SmPageLoader(),
          },
        ),
      ),
    );
  }

  Widget _body(ServiceBooking b) {
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    final start = b.startDate, end = b.endDate;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            Expanded(child: Text(b.guestName, style: DesignTokens.h3)),
            ServicePill(b.state.labelFor(b.kind), tone: bookingTone(b.state)),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(b.listingTitle, style: DesignTokens.smallRegular),

        ServiceSectionTitle(b.isStay ? 'Stay details' : 'Trip details'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b.isStay) ...[
                ServiceRow(
                  label: 'Room',
                  value: b.rooms > 1 ? '${b.rooms} × ${b.itemName}' : b.itemName,
                ),
                if (start != null)
                  ServiceRow(
                    label: 'Check-in',
                    value:
                        '${serviceDateText(start)}${b.checkInTime == null ? '' : ', from ${b.checkInTime}'}',
                  ),
                if (end != null)
                  ServiceRow(
                    label: 'Check-out',
                    value:
                        '${serviceDateText(end)}${b.checkOutTime == null ? '' : ', by ${b.checkOutTime}'}',
                  ),
                if (b.nights > 0)
                  ServiceRow(
                    label: 'Nights',
                    value: '${b.nights}',
                  ),
              ] else ...[
                if (start != null)
                  ServiceRow(label: 'Departure', value: serviceDateText(start)),
                if (end != null)
                  ServiceRow(label: 'Returns', value: serviceDateText(end)),
                if (b.meetingPoint != null)
                  ServiceRow(label: 'Meeting point', value: b.meetingPoint!),
              ],
              if (b.guestsText.isNotEmpty)
                ServiceRow(
                  label: b.isStay ? 'Guests' : 'Travellers',
                  value: b.guestsText,
                ),
              ServiceRow(label: 'Booking', value: b.number),
            ],
          ),
        ),
        if (b.travellers.isNotEmpty) ...[
          ServiceSectionTitle(b.isStay ? 'Guests' : 'Travellers'),
          ServiceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in b.travellers)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      [
                        t.fullName,
                        if (t.isChild)
                          t.age == null ? 'child' : 'child, ${t.age}',
                      ].join(' · '),
                      style: DesignTokens.smallRegular,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (b.specialRequests != null) ...[
          const ServiceSectionTitle('Special requests'),
          ServiceCard(
            child: Text(b.specialRequests!, style: DesignTokens.smallRegular),
          ),
        ],

        const ServiceSectionTitle('Payment'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b.paymentMode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                  child: Text(
                    b.paymentMode == BookingPaymentMode.deposit &&
                            b.depositPercent != null
                        ? '${b.depositPercent}% deposit online, rest at venue'
                        : b.paymentMode!.label,
                    style: muted,
                  ),
                ),
              for (final l in b.lines)
                ServiceRow(label: l.label, value: serviceMoney(l.amount)),
              ServiceRow(
                label: 'Total',
                value: serviceMoney(b.total),
                emphasised: true,
              ),
              ServiceRow(
                label: 'Paid online',
                value: serviceMoney(b.paidOnline),
              ),
              if (b.balanceReceivedAmount != null)
                ServiceRow(
                  label: 'Received at venue',
                  value: serviceMoney(b.balanceReceivedAmount!),
                ),
              ServiceRow(
                key: const Key('vendor-booking-balance-due'),
                label: 'To collect at venue',
                value: serviceMoney(b.balanceDue),
                emphasised: b.hasBalanceToCollect,
                valueColor: b.hasBalanceToCollect
                    ? DesignTokens.colorWarning
                    : null,
              ),
              if (b.state == BookingState.pendingPayment &&
                  b.holdExpiresUtc != null)
                Text(
                  'Waiting for the guest to pay until '
                  '${serviceInstantText(b.holdExpiresUtc!)}.',
                  style: muted,
                ),
            ],
          ),
        ),

        if (b.state == BookingState.cancelled) ...[
          const ServiceSectionTitle('Cancellation'),
          ServiceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelled by ${_cancelledBy(b)}'
                  '${b.cancelReason == null ? '' : ': ${b.cancelReason}'}',
                  style: DesignTokens.smallRegular,
                ),
                if (b.cancellationFee != null)
                  ServiceRow(
                    label: 'Cancellation fee kept',
                    value: serviceMoney(b.cancellationFee!),
                  ),
                if (b.refundAmount != null)
                  ServiceRow(
                    label: b.refundState.label.isEmpty
                        ? 'Refund'
                        : b.refundState.label,
                    value: serviceMoney(b.refundAmount!),
                  ),
              ],
            ),
          ),
        ] else if (b.cancellationSummary != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(b.cancellationSummary!, style: muted),
        ],

        if (b.settledUtc != null) ...[
          const ServiceSectionTitle('Your earnings'),
          ServiceCard(
            child: Column(
              children: [
                if (b.commissionAmount != null)
                  ServiceRow(
                    label:
                        'StyleMint commission${b.commissionPercent == null ? '' : ' (${_percent(b.commissionPercent!)}%)'}',
                    value: serviceMoney(b.commissionAmount!),
                  ),
                if (b.vendorNetAmount != null)
                  ServiceRow(
                    label: 'Net to you',
                    value: serviceMoney(b.vendorNetAmount!),
                    emphasised: true,
                  ),
              ],
            ),
          ),
        ],

        const ServiceSectionTitle('Actions'),
        ..._actions(b),
        const SizedBox(height: DesignTokens.s32),
      ],
    );
  }

  static String _cancelledBy(ServiceBooking b) {
    if (b.cancelledByVendor) return 'you';
    if (b.cancelledByBuyer) return 'the guest';
    return 'StyleMint';
  }

  static String _percent(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toString();

  List<Widget> _actions(ServiceBooking b) {
    final buttons = <Widget>[
      if (b.canCheckIn)
        ServiceActionButton(
          key: VendorBookingDetailScreen.checkInKey,
          label: b.isStay ? 'Check in' : 'Start trip',
          icon: Icons.login_rounded,
          busy: _busy,
          onPressed: () => _run(
            (repo) => repo.checkIn(b.id),
            b.isStay ? 'Checked in.' : 'Trip started.',
          ),
        ),
      if (b.canComplete)
        ServiceActionButton(
          key: VendorBookingDetailScreen.completeKey,
          label: 'Mark completed',
          icon: Icons.check_circle_outline,
          outlined: b.canCheckIn,
          busy: _busy && !b.canCheckIn,
          onPressed: _busy
              ? null
              : () => _run((repo) => repo.complete(b.id), 'Marked completed.'),
        ),
      if (b.canMarkBalanceReceived && b.hasBalanceToCollect)
        ServiceActionButton(
          key: VendorBookingDetailScreen.balanceKey,
          label: 'Mark balance received (${serviceMoney(b.balanceDue)})',
          icon: Icons.payments_outlined,
          outlined: true,
          onPressed: _busy ? null : () => _balance(b),
        ),
      if (b.canMarkNoShow)
        ServiceActionButton(
          key: VendorBookingDetailScreen.noShowKey,
          label: 'Mark no-show',
          icon: Icons.person_off_outlined,
          outlined: true,
          onPressed: _busy ? null : () => _noShow(b),
        ),
      if (b.canCancel)
        ServiceActionButton(
          key: VendorBookingDetailScreen.cancelKey,
          label: 'Cancel booking',
          icon: Icons.event_busy_outlined,
          outlined: true,
          destructive: true,
          onPressed: _busy ? null : () => _cancel(b),
        ),
    ];
    if (buttons.isEmpty) {
      return [
        Text(
          'Nothing to do on this booking right now.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ];
    }
    return [
      for (final w in buttons) ...[
        w,
        const SizedBox(height: DesignTokens.s12),
      ],
    ];
  }
}

/// How much was received at the venue: the whole balance by default.
class _BalanceDialog extends StatefulWidget {
  const _BalanceDialog({required this.booking});

  final ServiceBooking booking;

  @override
  State<_BalanceDialog> createState() => _BalanceDialogState();
}

class _BalanceDialogState extends State<_BalanceDialog> {
  late final _controller = TextEditingController(
    text: _plain(widget.booking.balanceDue.amount),
  );

  static String _plain(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _amount {
    final v = double.tryParse(_controller.text.trim());
    final due = widget.booking.balanceDue.amount;
    if (v == null || v <= 0 || v > due) return null;
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final due = widget.booking.balanceDue;
    return AlertDialog(
      title: const Text('Balance received'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.booking.guestName} still owes ${serviceMoney(due)} at '
            'the venue. How much did you receive?',
          ),
          const SizedBox(height: DesignTokens.s12),
          TextField(
            key: VendorBookingDetailScreen.balanceAmountKey,
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              prefixText: '${due.currency == 'NPR' ? 'Rs' : due.currency} ',
              errorText: _controller.text.isNotEmpty && _amount == null
                  ? 'Between 1 and ${serviceMoney(due)}'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        TextButton(
          key: VendorBookingDetailScreen.balanceConfirmKey,
          onPressed: _amount == null
              ? null
              : () => Navigator.of(context).pop(_amount),
          child: const Text('Record'),
        ),
      ],
    );
  }
}

/// Cancelling as the vendor: the refund first (everything paid online, no
/// fee — contract §2), then the reason the guest will be told.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.booking});

  final ServiceBooking booking;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final refund = b.vendorCancelRefund;
    final reason = _controller.text.trim();
    return AlertDialog(
      title: const Text('Cancel this booking?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            refund.amount > 0
                ? '${b.guestName} gets a full refund of ${serviceMoney(refund)} '
                      '— everything paid online. No cancellation fee applies '
                      'when you cancel.'
                : 'Nothing was paid online, so there is nothing to refund.',
            key: VendorBookingDetailScreen.cancelRefundKey,
          ),
          if (b.hasBalanceToCollect && b.paidOnline.amount > 0) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'The ${serviceMoney(b.balanceDue)} due at the venue is no '
              'longer owed.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          TextField(
            key: VendorBookingDetailScreen.cancelReasonKey,
            controller: _controller,
            maxLength: 300,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Reason (the guest sees this)',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep booking'),
        ),
        TextButton(
          key: VendorBookingDetailScreen.cancelConfirmKey,
          onPressed: reason.isEmpty
              ? null
              : () => Navigator.of(context).pop(reason),
          style: TextButton.styleFrom(foregroundColor: DesignTokens.colorError),
          child: const Text('Cancel booking'),
        ),
      ],
    );
  }
}
