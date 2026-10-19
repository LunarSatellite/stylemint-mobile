import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// What the booking screen is opened with: the server's quote, and the
/// names to show beside it.
class BookingCheckoutArgs {
  const BookingCheckoutArgs({
    required this.quote,
    required this.listingTitle,
    required this.itemName,
    this.photoUrl,
  });

  final BookingQuote quote;
  final String listingTitle;

  /// The room type's name, or the departure ("Departs 2 Nov").
  final String itemName;
  final String? photoUrl;
}

/// Booking a quoted stay or trip: how to pay (only the modes the listing
/// allows, each with the server's own amounts), who is coming, then pay
/// through the same hand-off checkout uses (the provider's page in the
/// in-app browser), and the confirmation.
///
/// No amount is ever sent: the booking names the quote's room or departure
/// and the payment names the booking; the server works out every figure.
class BookingCheckoutScreen extends ConsumerStatefulWidget {
  const BookingCheckoutScreen({required this.args, super.key});

  /// Null when the screen was opened without a quote (a stale link).
  final BookingCheckoutArgs? args;

  static const Key submitKey = Key('booking-submit');
  static const Key errorKey = Key('booking-error');
  static const Key guestNameKey = Key('booking-guest-name');
  static const Key requestsKey = Key('booking-special-requests');
  static const Key totalKey = Key('booking-total');
  static const Key payNowKey = Key('booking-pay-now');
  static const Key payAtVenueKey = Key('booking-pay-at-venue');
  static Key modeKey(PaymentMode m) => Key('booking-mode-${m.name}');
  static Key railKey(BookingPaymentRail r) => Key('booking-rail-${r.name}');
  static Key travellerKey(int i) => Key('booking-traveller-$i');
  static Key travellerAgeKey(int i) => Key('booking-traveller-age-$i');

  @override
  ConsumerState<BookingCheckoutScreen> createState() =>
      _BookingCheckoutScreenState();
}

class _BookingCheckoutScreenState extends ConsumerState<BookingCheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _guestName = TextEditingController();
  final _requests = TextEditingController();
  late final List<TextEditingController> _travellerNames;
  late final List<TextEditingController> _travellerAges;

  PaymentMode? _mode;
  BookingPaymentRail _rail = BookingPaymentRail.eSewa;
  bool _busy = false;
  String? _error;

  /// The booking made on this screen, once it exists. A failed payment is
  /// retried on it, never by booking twice.
  Booking? _booking;

  /// One key per booking the buyer means to make; a retry after a timeout
  /// reuses it. Changing how to pay is a different booking.
  String _bookingKey = const Uuid().v4();

  /// One key per payment attempt; changing the rail is a new payment.
  String _payKey = const Uuid().v4();

  BookingQuote? get _quote => widget.args?.quote;

  bool get _isPackage => _quote?.kind == ListingKind.package;

  @override
  void initState() {
    super.initState();
    final q = _quote;
    final count = q == null || q.kind != ListingKind.package ? 0 : q.travellers;
    _travellerNames = [for (var i = 0; i < count; i++) TextEditingController()];
    _travellerAges = [for (var i = 0; i < count; i++) TextEditingController()];
    final name = ref.read(servicesBuyerNameProvider);
    if (name != null) {
      _guestName.text = name;
      if (_travellerNames.isNotEmpty) _travellerNames.first.text = name;
    }
    final options = q?.paymentOptions ?? const [];
    if (options.length == 1) _mode = options.single.mode;
  }

  @override
  void dispose() {
    _guestName.dispose();
    _requests.dispose();
    for (final c in [..._travellerNames, ..._travellerAges]) {
      c.dispose();
    }
    super.dispose();
  }

  TravellerType _typeAt(int i) =>
      i < (_quote?.adults ?? 0) ? TravellerType.adult : TravellerType.child;

  List<Traveller> get _travellers => [
    for (var i = 0; i < _travellerNames.length; i++)
      Traveller(
        fullName: _travellerNames[i].text.trim(),
        type: _typeAt(i),
        age: int.tryParse(_travellerAges[i].text.trim()),
      ),
  ];

  Future<void> _submit() async {
    final quote = _quote;
    final mode = _mode;
    if (quote == null) return;
    if (mode == null) {
      setState(() => _error = 'Choose how you want to pay.');
      return;
    }
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    var booking = _booking;
    if (booking == null) {
      final guestName = _isPackage
          ? _travellerNames.first.text.trim()
          : _guestName.text.trim();
      final created = await ref
          .read(bookingsRepositoryProvider)
          .createBooking(
            quote: quote,
            paymentMode: mode,
            guestName: guestName,
            travellers: _isPackage ? _travellers : const [],
            idempotencyKey: _bookingKey,
            specialRequests: _requests.text,
          );
      if (!mounted) return;
      booking = created.fold((failure) {
        setState(() {
          _busy = false;
          _error = serviceFailureMessage(failure, what: 'this booking');
        });
        return null;
      }, (b) => b);
      if (booking == null) return;
      _booking = booking;
      refreshBookings(ref);
    }

    if (booking.state == BookingState.pendingPayment && mode.paysOnline) {
      final started = await ref
          .read(bookingsRepositoryProvider)
          .pay(bookingId: booking.id, rail: _rail, idempotencyKey: _payKey);
      if (!mounted) return;
      final ok = await started.fold(
        (failure) async {
          setState(() {
            _busy = false;
            _error = serviceFailureMessage(failure, what: 'the payment');
          });
          return false;
        },
        (start) async {
          final url = start.redirectUrl;
          final uri = url == null ? null : Uri.tryParse(url);
          if (uri != null) await ref.read(servicePaymentLauncherProvider)(uri);
          return true;
        },
      );
      if (!ok || !mounted) return;
    }

    refreshBookings(ref, bookingId: booking.id);
    if (!mounted) return;
    context.pushReplacement(RouteNames.bookingConfirmedPath(booking.id));
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final quote = _quote;
    if (args == null || quote == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(backgroundColor: DesignTokens.bgAppFoundation),
        body: const SmEmptyState(
          title: 'Start again',
          message: 'Pick your dates and get a price to book.',
          icon: Icons.event_busy_outlined,
        ),
      );
    }
    final mode = _mode;
    final option = mode == null ? null : quote.optionFor(mode);
    final paysOnline = option != null && option.payNow.amount > 0;
    final String label;
    if (option == null) {
      label = 'Choose how to pay';
    } else if (option.payNow.amount > 0) {
      label = 'Pay ${serviceMoney(option.payNow)}';
    } else {
      label = 'Confirm booking';
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Book'),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ServiceFormScroll(
            children: [
              _Summary(args: args),
              const ServiceSectionTitle('How do you want to pay?'),
              _PaymentModes(
                quote: quote,
                selected: _mode,
                locked: _booking != null,
                onChanged: (m) => setState(() {
                  _mode = m;
                  _error = null;
                  _bookingKey = const Uuid().v4();
                }),
              ),
              if (paysOnline) ...[
                const ServiceSectionTitle('Pay with'),
                RadioGroup<BookingPaymentRail>(
                  groupValue: _rail,
                  onChanged: (rail) {
                    if (rail == null || _busy) return;
                    setState(() {
                      _rail = rail;
                      _payKey = const Uuid().v4();
                    });
                  },
                  child: Column(
                    children: [
                      for (final rail in BookingPaymentRail.values)
                        RadioListTile<BookingPaymentRail>(
                          key: BookingCheckoutScreen.railKey(rail),
                          value: rail,
                          title: Text(
                            rail.label,
                            style: DesignTokens.smallRegular,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
              ],
              ServiceSectionTitle(_isPackage ? 'Travellers' : 'Guest'),
              if (_isPackage) ...[
                for (var i = 0; i < _travellerNames.length; i++)
                  _TravellerFields(
                    index: i,
                    type: _typeAt(i),
                    name: _travellerNames[i],
                    age: _travellerAges[i],
                    enabled: _booking == null,
                  ),
              ] else
                TextFormField(
                  key: BookingCheckoutScreen.guestNameKey,
                  controller: _guestName,
                  enabled: _booking == null,
                  textCapitalization: TextCapitalization.words,
                  style: DesignTokens.smallRegular,
                  decoration: serviceInputDecoration(
                    'Name the booking is under',
                    hint: 'As on your ID',
                  ),
                  validator: _validName,
                ),
              const SizedBox(height: DesignTokens.s12),
              TextFormField(
                key: BookingCheckoutScreen.requestsKey,
                controller: _requests,
                enabled: _booking == null,
                maxLines: 3,
                maxLength: 1000,
                style: DesignTokens.smallRegular,
                decoration: serviceInputDecoration(
                  'Special requests (optional)',
                  hint: 'Late arrival, dietary needs…',
                ),
              ),
              if (paysOnline && quote.holdMinutes != null)
                Text(
                  'We hold this for ${quote.holdMinutes} minutes while you pay.',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  _error!,
                  key: BookingCheckoutScreen.errorKey,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s12,
          ),
          child: ServicePrimaryButton(
            key: BookingCheckoutScreen.submitKey,
            label: label,
            busy: _busy,
            onPressed: option == null ? null : () => unawaited(_submit()),
          ),
        ),
      ),
    );
  }
}

String? _validName(String? v) {
  final s = v?.trim() ?? '';
  if (s.length < 2) return 'Enter a full name';
  if (s.length > 100) return 'Keep it under 100 characters';
  return null;
}

class _Summary extends StatelessWidget {
  const _Summary({required this.args});

  final BookingCheckoutArgs args;

  @override
  Widget build(BuildContext context) {
    final q = args.quote;
    final stay = q.kind == ListingKind.stay;
    final end = q.endDate;
    final nights = q.nights;
    return ServiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(args.listingTitle, style: DesignTokens.mediumSemibold),
          Text(
            args.itemName,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          ServiceRow(
            label: stay ? 'Dates' : 'Departs',
            value: end == null || !stay
                ? serviceDate(q.startDate)
                : '${serviceShortDate(q.startDate)} → ${serviceShortDate(end)}',
          ),
          if (stay && nights != null)
            ServiceRow(
              label: 'Nights',
              value: '$nights${q.rooms != null && q.rooms! > 1 ? ' · ${q.rooms} rooms' : ''}',
            ),
          ServiceRow(
            label: stay ? 'Guests' : 'Travellers',
            value: q.children > 0
                ? '${q.adults} adults · ${q.children} children'
                : '${q.adults}',
          ),
          const Divider(color: DesignTokens.borderDefault),
          for (final line in q.lines)
            ServiceRow(
              label: line.quantity > 1
                  ? '${line.label} × ${line.quantity}'
                  : line.label,
              value: serviceMoney(line.amount),
            ),
          ServiceRow(
            label: 'Total',
            value: serviceMoney(q.totalPrice),
            emphasised: true,
            valueKey: BookingCheckoutScreen.totalKey,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            q.cancellationPolicy.describe(),
            key: const Key('booking-cancellation-policy'),
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
          ),
        ],
      ),
    );
  }
}

class _PaymentModes extends StatelessWidget {
  const _PaymentModes({
    required this.quote,
    required this.selected,
    required this.locked,
    required this.onChanged,
  });

  final BookingQuote quote;
  final PaymentMode? selected;

  /// The booking exists: its mode can no longer change here.
  final bool locked;
  final ValueChanged<PaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = quote.paymentOptions;
    if (options.isEmpty) {
      return Text(
        'This listing has no way to pay set up yet.',
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
      );
    }
    final picked = selected == null ? null : quote.optionFor(selected!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<PaymentMode>(
          groupValue: selected,
          onChanged: (m) {
            if (m == null || locked) return;
            onChanged(m);
          },
          child: Column(
            children: [
              for (final o in options)
                ServiceCard(
                  borderColor: selected == o.mode
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s4,
                  ),
                  child: RadioListTile<PaymentMode>(
                    key: BookingCheckoutScreen.modeKey(o.mode),
                    value: o.mode,
                    title: Text(o.mode.label, style: DesignTokens.smallRegular),
                    subtitle: Text(
                      switch (o.mode) {
                        PaymentMode.fullPrepay =>
                          '${serviceMoney(o.payNow)} online now',
                        PaymentMode.deposit =>
                          '${serviceMoney(o.payNow)} now · '
                              '${serviceMoney(o.payAtVenue)} at the venue',
                        PaymentMode.payAtVenue =>
                          'Nothing now · ${serviceMoney(o.payAtVenue)} at the '
                              'venue',
                      },
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
                ),
            ].expand((w) => [w, const SizedBox(height: DesignTokens.s8)]).toList(),
          ),
        ),
        if (picked != null)
          ServiceCard(
            child: Column(
              children: [
                ServiceRow(
                  label: 'Pay now',
                  value: serviceMoney(picked.payNow),
                  valueKey: BookingCheckoutScreen.payNowKey,
                  emphasised: true,
                ),
                ServiceRow(
                  label: 'Pay at the venue',
                  value: serviceMoney(picked.payAtVenue),
                  valueKey: BookingCheckoutScreen.payAtVenueKey,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TravellerFields extends StatelessWidget {
  const _TravellerFields({
    required this.index,
    required this.type,
    required this.name,
    required this.age,
    required this.enabled,
  });

  final int index;
  final TravellerType type;
  final TextEditingController name;
  final TextEditingController age;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            key: BookingCheckoutScreen.travellerKey(index),
            controller: name,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            style: DesignTokens.smallRegular,
            decoration: serviceInputDecoration(
              index == 0
                  ? 'Lead traveller (${type.label.toLowerCase()})'
                  : 'Traveller ${index + 1} (${type.label.toLowerCase()})',
            ),
            validator: _validName,
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: TextFormField(
            key: BookingCheckoutScreen.travellerAgeKey(index),
            controller: age,
            enabled: enabled,
            keyboardType: TextInputType.number,
            style: DesignTokens.smallRegular,
            decoration: serviceInputDecoration(
              type == TravellerType.child ? 'Age' : 'Age (opt.)',
            ),
            validator: (v) {
              final s = v?.trim() ?? '';
              if (s.isEmpty) return null;
              final n = int.tryParse(s);
              if (n == null || n < 0 || n > 120) return 'Age?';
              return null;
            },
          ),
        ),
      ],
    ),
  );
}
