import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_choice.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Keys the item page's service section exposes to tests.
abstract final class ServiceItemKeys {
  static const datesKey = Key('service-item-dates');
  static const nightsRuleKey = Key('service-item-nights-rule');
  static const quoteTotalKey = Key('service-item-quote-total');
  static const quoteErrorKey = Key('service-item-quote-error');
  static const policyKey = Key('service-item-policy');
  static const settingUpKey = Key('service-item-setting-up');
  static Key room(String id) => Key('service-item-room-$id');
  static Key roomPrice(String id) => Key('service-item-room-price-$id');
  static Key departure(String id) => Key('service-item-departure-$id');
  static Key payMode(PaymentMode m) => Key('service-item-pay-${m.name}');
  static Key payNow(PaymentMode m) => Key('service-item-pay-now-${m.name}');
  static const bankRateKey = Key('bank-item-rate');
  static const bankEligibilityKey = Key('bank-item-eligibility');
}

/// Prices [choice] with the Bookings quote for its room or departure
/// (service items contract v1 §4 links.quote). The words for a "no" are the
/// quote's own reason, or the failure's.
Future<({BookingQuote? quote, String? error})> quoteServiceChoice(
  WidgetRef ref,
  ServiceChoice choice,
) async {
  final repo = ref.read(bookingsRepositoryProvider);
  final result = choice.isStay
      ? await repo.quoteStay(
          listingId: choice.item.listingId,
          roomTypeId: choice.roomTypeId!,
          checkIn: choice.checkIn,
          checkOut: choice.checkOut,
          rooms: choice.rooms,
          adults: choice.adults,
          children: choice.children,
        )
      : await repo.quotePackage(
          listingId: choice.item.listingId,
          departureId: choice.departureId!,
          adults: choice.adults,
          children: choice.children,
        );
  return result.fold(
    (failure) => (
      quote: null,
      error: serviceFailureMessage(failure, what: 'a price'),
    ),
    (quote) => (
      quote: quote,
      error: quote.available
          ? null
          : quoteUnavailableMessage(quote.unavailableReason),
    ),
  );
}

/// The part of the item page a stay or trip has in place of size and
/// colour: dates or a departure, rooms and guests, the price for exactly
/// that, how to pay, and the policies. A bank product shows its rates,
/// eligibility and branches instead (its actions are in the page's bar).
///
/// [choice] is null for a bank. With no readable [item] the item is being
/// set up (the owning module did not answer): the page says so.
class ServiceItemSection extends ConsumerStatefulWidget {
  const ServiceItemSection({required this.item, this.choice, super.key});

  final ServiceItem? item;
  final ServiceChoice? choice;

  @override
  ConsumerState<ServiceItemSection> createState() =>
      _ServiceItemSectionState();
}

class _ServiceItemSectionState extends ConsumerState<ServiceItemSection> {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.choice?.addListener(_onChoice);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChoice());
  }

  @override
  void didUpdateWidget(covariant ServiceItemSection old) {
    super.didUpdateWidget(old);
    if (old.choice != widget.choice) {
      old.choice?.removeListener(_onChoice);
      widget.choice?.addListener(_onChoice);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.choice?.removeListener(_onChoice);
    super.dispose();
  }

  /// A complete, unpriced choice is priced shortly after the buyer stops
  /// changing it.
  void _onChoice() {
    if (!mounted) return;
    setState(() {});
    final choice = widget.choice;
    if (choice == null ||
        !choice.isComplete ||
        choice.quote != null ||
        choice.quoting ||
        choice.error != null) {
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(choice.price((c) => quoteServiceChoice(ref, c)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final choice = widget.choice;
    if (item == null) return const _SettingUp();
    return switch (item.type) {
      ServiceItemType.stay when item.stay != null && choice != null =>
        _StayOptions(item: item, stay: item.stay!, choice: choice),
      ServiceItemType.package when item.package != null && choice != null =>
        _PackageOptions(pkg: item.package!, choice: choice),
      ServiceItemType.bank when item.bank != null => BankItemSection(
        bank: item.bank!,
      ),
      _ => const _SettingUp(),
    };
  }
}

class _SettingUp extends StatelessWidget {
  const _SettingUp();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
    child: Text(
      'Booking for this is being set up. Check back shortly.',
      key: ServiceItemKeys.settingUpKey,
      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
    ),
  );
}

// ── Stay ─────────────────────────────────────────────────────────────────────

class _StayOptions extends ConsumerWidget {
  const _StayOptions({
    required this.item,
    required this.stay,
    required this.choice,
  });

  final ServiceItem item;
  final StayDetail stay;
  final ServiceChoice choice;

  Future<void> _pickDates(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: choice.today,
      lastDate: choice.today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: choice.checkIn,
        end: choice.checkOut,
      ),
      helpText: 'Check-in and check-out',
    );
    if (range != null) choice.setDates(range.start, range.end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The rooms priced for these dates and guests (links.detail with the
    // search); until that answers, or if it cannot, the item's own rooms at
    // their base rate.
    final priced = ref
        .watch(
          stayDetailProvider((
            listingId: item.listingId,
            search: choice.staySearch,
          )),
        )
        .asData
        ?.value;
    final rooms = priced?.roomTypes.isNotEmpty == true
        ? priced!.roomTypes
        : stay.roomTypes;
    final nights = choice.nights;
    final rule = choice.nightsProblem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ServiceSectionTitle('Your stay'),
        ServiceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                key: ServiceItemKeys.datesKey,
                onTap: () => unawaited(_pickDates(context)),
                leading: const Icon(Icons.date_range_outlined),
                title: Text(
                  '${serviceShortDate(choice.checkIn)} → '
                  '${serviceShortDate(choice.checkOut)}',
                  style: DesignTokens.smallRegular,
                ),
                subtitle: Text(
                  nights == 1 ? '1 night' : '$nights nights',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                child: Column(
                  children: [
                    ServiceCounter(
                      label: 'Adults',
                      keyPrefix: 'service-item-adults',
                      value: choice.adults,
                      min: 1,
                      max: 30,
                      onChanged: choice.setAdults,
                    ),
                    ServiceCounter(
                      label: 'Children',
                      keyPrefix: 'service-item-children',
                      value: choice.children,
                      max: 20,
                      onChanged: choice.setChildren,
                    ),
                    ServiceCounter(
                      label: 'Rooms',
                      keyPrefix: 'service-item-rooms',
                      value: choice.rooms,
                      min: 1,
                      max: 10,
                      onChanged: choice.setRooms,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (rule != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              rule,
              key: ServiceItemKeys.nightsRuleKey,
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.colorWarning,
              ),
            ),
          ),
        const ServiceSectionTitle('Room type'),
        if (rooms.isEmpty)
          Text(
            'No rooms are listed yet.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          RadioGroup<String>(
            groupValue: choice.roomTypeId,
            onChanged: choice.selectRoom,
            child: Column(
              children: [
                for (final room in rooms) ...[
                  _RoomCard(room: room, choice: choice),
                  const SizedBox(height: DesignTokens.s8),
                ],
              ],
            ),
          ),
        _QuoteSummary(choice: choice),
        const ServiceSectionTitle('Policies'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stay.checkInTime != null)
                ServiceRow(label: 'Check-in from', value: stay.checkInTime!),
              if (stay.checkOutTime != null)
                ServiceRow(label: 'Check-out by', value: stay.checkOutTime!),
              if (stay.paymentModes.isNotEmpty)
                ServiceRow(
                  label: 'Ways to pay',
                  value: paymentModesLine(
                    stay.paymentModes,
                    stay.depositPercent,
                  ),
                ),
              const SizedBox(height: DesignTokens.s8),
              Text('Cancellation', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              Text(
                stay.cancellationPolicy.describe(),
                key: ServiceItemKeys.policyKey,
                style: DesignTokens.smallRegular,
              ),
              if (stay.houseRules != null) ...[
                const SizedBox(height: DesignTokens.s12),
                Text('House rules', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(stay.houseRules!, style: DesignTokens.smallRegular),
              ],
            ],
          ),
        ),
        if (stay.amenities.isNotEmpty) ...[
          const ServiceSectionTitle('Amenities'),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final a in stay.amenities) ServiceChip(label: _words(a)),
            ],
          ),
        ],
        if (stay.latitude != null && stay.longitude != null) ...[
          const ServiceSectionTitle('Location'),
          if (stay.addressLine != null || stay.place.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Text(
                stay.addressLine ?? stay.place,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          ServiceMapBox(
            pins: [
              ServiceMapPin(
                id: stay.listingId,
                latitude: stay.latitude!,
                longitude: stay.longitude!,
                label: stay.title,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _words(String raw) {
  final s = raw.replaceAll(RegExp(r'[_\-]'), ' ').trim();
  if (s.isEmpty) return raw;
  return s[0].toUpperCase() + s.substring(1);
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.choice});

  final RoomType room;
  final ServiceChoice choice;

  @override
  Widget build(BuildContext context) {
    final fits = room.fits(guests: choice.guests, rooms: choice.rooms);
    final enabled = fits && !room.soldOut;
    final nightly = room.nightly;
    final perNight = nightly.isEmpty
        ? room.baseRate
        : Money(
            amount:
                nightly.fold<double>(0, (sum, n) => sum + n.price.amount) /
                nightly.length,
            currency: nightly.first.price.currency,
          );
    final units = room.availableUnits;
    // A room that is sold out or too small stays on the page, dimmed, so the
    // buyer sees why it cannot be picked.
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: ServiceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s4,
            vertical: DesignTokens.s8,
          ),
          child: RadioListTile<String>(
            key: ServiceItemKeys.room(room.id),
            value: room.id,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s8,
            ),
            title: Text(room.name, style: DesignTokens.mediumSemibold),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    if (room.beds != null) room.beds!,
                    'Up to ${room.maxGuests} guests',
                    if (room.sizeSqm != null) '${room.sizeSqm!.round()} m²',
                  ].join(' · '),
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${serviceMoney(perNight)} / night',
                  key: ServiceItemKeys.roomPrice(room.id),
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (room.soldOut)
                  Text(
                    'Sold out for these dates',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  )
                else if (!fits)
                  Text(
                    'Too small for ${choice.guests} guests in '
                    '${choice.rooms == 1 ? '1 room' : '${choice.rooms} rooms'}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.colorWarning,
                    ),
                  )
                else if (units != null && units <= 3)
                  Text(
                    'Few rooms left for these dates',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.colorWarning,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Package ──────────────────────────────────────────────────────────────────

class _PackageOptions extends StatelessWidget {
  const _PackageOptions({required this.pkg, required this.choice});

  final PackageDetail pkg;
  final ServiceChoice choice;

  @override
  Widget build(BuildContext context) {
    final departure = pkg.departures
        .where((d) => d.id == choice.departureId)
        .firstOrNull;
    final tooMany =
        departure != null && choice.guests > departure.seatsAvailable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pkg.durationLabel != null || pkg.destination != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              [?pkg.destination, ?pkg.durationLabel].join(' · '),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
        const ServiceSectionTitle('Departure'),
        if (pkg.departures.isEmpty)
          Text(
            'Dates coming soon.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          RadioGroup<String>(
            groupValue: choice.departureId,
            onChanged: choice.selectDeparture,
            child: Column(
              children: [
                for (final d in pkg.departures) ...[
                  _DepartureCard(departure: d),
                  const SizedBox(height: DesignTokens.s8),
                ],
              ],
            ),
          ),
        const ServiceSectionTitle('Travellers'),
        ServiceCard(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
          child: Column(
            children: [
              ServiceCounter(
                label: 'Adults',
                keyPrefix: 'service-item-adults',
                value: choice.adults,
                min: 1,
                max: 50,
                onChanged: choice.setAdults,
              ),
              ServiceCounter(
                label: 'Children',
                keyPrefix: 'service-item-children',
                value: choice.children,
                max: 50,
                onChanged: choice.setChildren,
              ),
            ],
          ),
        ),
        if (tooMany)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              departure.seatsAvailable == 1
                  ? 'This departure has 1 seat left.'
                  : 'This departure has ${departure.seatsAvailable} seats '
                        'left.',
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.colorWarning,
              ),
            ),
          ),
        _QuoteSummary(choice: choice),
        if (pkg.itinerary.isNotEmpty) ...[
          const ServiceSectionTitle('Itinerary'),
          for (final day in pkg.itinerary)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: ServiceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${day.day} · ${day.title}',
                      style: DesignTokens.mediumSemibold,
                    ),
                    if (day.description != null) ...[
                      const SizedBox(height: DesignTokens.s4),
                      Text(day.description!, style: DesignTokens.smallRegular),
                    ],
                  ],
                ),
              ),
            ),
        ],
        if (pkg.inclusions.isNotEmpty) ...[
          const ServiceSectionTitle('Included'),
          for (final i in pkg.inclusions)
            ServiceBullet(i, icon: Icons.check_circle_outline),
        ],
        if (pkg.exclusions.isNotEmpty) ...[
          const ServiceSectionTitle('Not included'),
          for (final e in pkg.exclusions)
            ServiceBullet(
              e,
              icon: Icons.remove_circle_outline,
              color: DesignTokens.textMuted,
            ),
        ],
        const ServiceSectionTitle('Policies'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pkg.meetingPoint != null)
                ServiceRow(label: 'Meeting point', value: pkg.meetingPoint!),
              if (pkg.paymentModes.isNotEmpty)
                ServiceRow(
                  label: 'Ways to pay',
                  value: paymentModesLine(pkg.paymentModes, pkg.depositPercent),
                ),
              const SizedBox(height: DesignTokens.s8),
              Text('Cancellation', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              Text(
                pkg.cancellationPolicy.describe(),
                key: ServiceItemKeys.policyKey,
                style: DesignTokens.smallRegular,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.departure});

  final Departure departure;

  @override
  Widget build(BuildContext context) {
    final d = departure;
    final child = d.childPrice;
    return IgnorePointer(
      ignoring: !d.bookable,
      child: Opacity(
        opacity: d.bookable ? 1 : 0.5,
        child: ServiceCard(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s4,
            vertical: DesignTokens.s8,
          ),
          child: RadioListTile<String>(
            key: ServiceItemKeys.departure(d.id),
            value: d.id,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s8,
            ),
            title: Text(
              d.endDate == null
                  ? serviceDate(d.date)
                  : '${serviceShortDate(d.date)} → '
                        '${serviceShortDate(d.endDate!)}',
              style: DesignTokens.mediumSemibold,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${serviceMoney(d.adultPrice)} per adult'
                  '${child == null ? '' : ' · ${serviceMoney(child)} per child'}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  !d.bookable
                      ? 'Full'
                      : d.seatsAvailable == 1
                      ? '1 seat left'
                      : '${d.seatsAvailable} seats left',
                  style: DesignTokens.tiny.copyWith(
                    color: d.bookable
                        ? DesignTokens.textMuted
                        : DesignTokens.colorError,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Price for the choice ─────────────────────────────────────────────────────

/// The server's price for exactly what is chosen, and how to pay it: each
/// way the listing allows, with what is paid now and at the venue.
class _QuoteSummary extends StatelessWidget {
  const _QuoteSummary({required this.choice});

  final ServiceChoice choice;

  @override
  Widget build(BuildContext context) {
    final quote = choice.quote;
    final error = choice.error;
    if (choice.quoting) {
      return const Padding(
        padding: EdgeInsets.only(top: DesignTokens.s12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s12),
        child: Text(
          error,
          key: ServiceItemKeys.quoteErrorKey,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.colorError,
          ),
        ),
      );
    }
    if (quote == null || !quote.available) return const SizedBox.shrink();
    final selected = choice.paymentMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ServiceSectionTitle('Price'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in quote.lines)
                ServiceRow(
                  label: line.quantity > 1
                      ? '${line.label} × ${line.quantity}'
                      : line.label,
                  value: serviceMoney(line.amount),
                ),
              ServiceRow(
                label: choice.isStay
                    ? 'Total for ${choice.nights == 1 ? '1 night' : '${choice.nights} nights'}'
                    : 'Total for ${choice.guests == 1 ? '1 traveller' : '${choice.guests} travellers'}',
                value: serviceMoney(quote.totalPrice),
                valueKey: ServiceItemKeys.quoteTotalKey,
                emphasised: true,
              ),
            ],
          ),
        ),
        if (quote.paymentOptions.isNotEmpty) ...[
          const ServiceSectionTitle('How to pay'),
          RadioGroup<PaymentMode>(
            groupValue: selected,
            onChanged: (m) {
              if (m != null) choice.selectPaymentMode(m);
            },
            child: Column(
              children: [
                for (final o in quote.paymentOptions)
                  RadioListTile<PaymentMode>(
                    key: ServiceItemKeys.payMode(o.mode),
                    value: o.mode,
                    contentPadding: EdgeInsets.zero,
                    title: Text(o.mode.label, style: DesignTokens.smallRegular),
                    subtitle: Text(
                      o.payAtVenue.amount > 0
                          ? '${serviceMoney(o.payNow)} now · '
                                '${serviceMoney(o.payAtVenue)} at the venue'
                          : '${serviceMoney(o.payNow)} now',
                      key: ServiceItemKeys.payNow(o.mode),
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bank ─────────────────────────────────────────────────────────────────────

/// A bank product on its item page: rates, amounts and term, fees, who can
/// apply, the documents to bring, and the bank's branches. Never added to
/// the cart; the page's bar has Enquire and Book appointment.
class BankItemSection extends StatelessWidget {
  const BankItemSection({required this.bank, super.key});

  final BankItem bank;

  @override
  Widget build(BuildContext context) {
    final p = bank.product;
    final rate = p?.rateLabel;
    final min = p?.minAmount;
    final max = p?.maxAmount;
    final lo = p?.minTenureMonths;
    final hi = p?.maxTenureMonths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: DesignTokens.s8),
          child: Wrap(
            spacing: DesignTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (p != null) ServiceChip(label: p.type.label),
              Text(
                bank.bankName,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (p != null) ...[
          const ServiceSectionTitle('Rates'),
          ServiceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceRow(
                  label: 'Interest',
                  value: rate ?? 'Ask the bank',
                  valueKey: ServiceItemKeys.bankRateKey,
                  emphasised: rate != null,
                ),
                if (p.rateNote != null)
                  Text(
                    p.rateNote!,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                if (min != null || max != null)
                  ServiceRow(
                    label: 'Amount',
                    value: [
                      if (min != null) 'from ${serviceMoney(min)}',
                      if (max != null) 'up to ${serviceMoney(max)}',
                    ].join(' '),
                  ),
                if (lo != null || hi != null)
                  ServiceRow(
                    label: 'Term',
                    value: lo != null && hi != null
                        ? '$lo–$hi months'
                        : '${lo ?? hi} months',
                  ),
              ],
            ),
          ),
          if (p.feesText != null) ...[
            const ServiceSectionTitle('Fees'),
            Text(p.feesText!, style: DesignTokens.smallRegular),
          ],
          if (p.eligibilityText != null) ...[
            const ServiceSectionTitle('Who can apply'),
            Text(
              p.eligibilityText!,
              key: ServiceItemKeys.bankEligibilityKey,
              style: DesignTokens.smallRegular,
            ),
          ],
          if (p.documentsRequired.isNotEmpty) ...[
            const ServiceSectionTitle('Documents you will need'),
            for (final d in p.documentsRequired)
              ServiceBullet(d, icon: Icons.description_outlined),
          ],
        ],
        if (bank.branches.isNotEmpty) ...[
          const ServiceSectionTitle('Branches'),
          for (final b in bank.branches) ...[
            BankBranchCard(branch: b),
            const SizedBox(height: DesignTokens.s8),
          ],
        ],
        const SizedBox(height: DesignTokens.s8),
        Text(
          'StyleMint shows what the bank publishes. Rates and terms are the '
          'bank\'s; the bank decides on any application.',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }
}

const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// A branch: address, phone (the branch's own), opening hours.
class BankBranchCard extends StatelessWidget {
  const BankBranchCard({required this.branch, super.key});

  final BankBranch branch;

  @override
  Widget build(BuildContext context) {
    final hours = {for (final h in branch.openingHours) h.dayOfWeek: h};
    return ServiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(branch.name, style: DesignTokens.mediumSemibold),
          if (branch.address.isNotEmpty)
            Text(
              branch.address,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          if (branch.phone != null)
            Text(
              branch.phone!,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
            ),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              [
                for (var d = 0; d < 7; d++)
                  switch (hours[d]) {
                    final h? when !h.closed && h.opens != null =>
                      '${_dayNames[d]} ${h.opens}–${h.closes ?? ''}',
                    _ => '${_dayNames[d]} closed',
                  },
              ].join(' · '),
              style: DesignTokens.tiny,
            ),
          ],
        ],
      ),
    );
  }
}
