import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One stay: photos, amenities, room types with their nightly price,
/// policies and cancellation rules. Pick a room and dates, and Reserve asks
/// the server for a price (a quote) before the booking screen.
class StayDetailScreen extends ConsumerStatefulWidget {
  const StayDetailScreen({required this.listingId, this.search, super.key});

  final String listingId;

  /// The search the buyer came from; tomorrow for a night when null.
  final StaySearch? search;

  static const Key reserveKey = Key('stay-reserve');
  static const Key quoteErrorKey = Key('stay-quote-error');
  static const Key datesKey = Key('stay-detail-dates');
  static Key roomKey(String id) => Key('stay-room-$id');

  @override
  ConsumerState<StayDetailScreen> createState() => _StayDetailScreenState();
}

class _StayDetailScreenState extends ConsumerState<StayDetailScreen> {
  late StaySearch _search =
      widget.search ??
      StaySearch.initial(kathmanduDay(ref.read(servicesClockProvider)()));
  String? _roomId;
  bool _quoting = false;
  String? _quoteError;

  StayKey get _key => (listingId: widget.listingId, search: _search);

  Future<void> _pickDates() async {
    final today = kathmanduDay(ref.read(servicesClockProvider)());
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _search.checkIn,
        end: _search.checkOut,
      ),
      helpText: 'Check-in and check-out',
    );
    if (range == null || !mounted) return;
    var end = range.end;
    if (!end.isAfter(range.start)) end = range.start.add(const Duration(days: 1));
    setState(() {
      _search = _search.copyWith(checkIn: range.start, checkOut: end);
      _quoteError = null;
    });
  }

  Future<void> _reserve(StayDetail stay) async {
    final roomId = _roomId;
    if (roomId == null) return;
    if (!await servicesEnsureAuth(context, ref) || !mounted) return;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    final result = await ref
        .read(bookingsRepositoryProvider)
        .quoteStay(
          listingId: stay.listingId,
          roomTypeId: roomId,
          checkIn: _search.checkIn,
          checkOut: _search.checkOut,
          rooms: _search.rooms,
          adults: _search.guests,
        );
    if (!mounted) return;
    setState(() => _quoting = false);
    result.fold(
      (failure) => setState(
        () => _quoteError = serviceFailureMessage(failure, what: 'a price'),
      ),
      (quote) {
        if (!quote.available) {
          setState(
            () => _quoteError = quoteUnavailableMessage(quote.unavailableReason),
          );
          return;
        }
        final room = stay.roomTypes.where((r) => r.id == roomId).firstOrNull;
        unawaited(
          context.push(
            RouteNames.bookingCheckout,
            extra: BookingCheckoutArgs(
              quote: quote,
              listingTitle: stay.title,
              itemName: room?.name ?? 'Room',
              photoUrl: stay.photoUrls.firstOrNull,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stay = ref.watch(stayDetailProvider(_key));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(stay.asData?.value.title ?? 'Stay'),
      ),
      body: SafeArea(
        child: stay.when(
          // Keeps the page while new dates are priced.
          skipLoadingOnReload: true,
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this stay',
                onRetry: () => ref.invalidate(stayDetailProvider(_key)),
              ),
            ],
          ),
          data: _body,
        ),
      ),
      bottomNavigationBar: stay.asData == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s8,
                  DesignTokens.s16,
                  DesignTokens.s12,
                ),
                child: ServicePrimaryButton(
                  key: StayDetailScreen.reserveKey,
                  label: _roomId == null ? 'Choose a room' : 'Reserve',
                  busy: _quoting,
                  onPressed: _roomId == null
                      ? null
                      : () => unawaited(_reserve(stay.asData!.value)),
                ),
              ),
            ),
    );
  }

  Widget _body(StayDetail stay) {
    final nights = _search.nights;
    final policy = stay.cancellationPolicy;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        _Photos(urls: stay.photoUrls),
        const SizedBox(height: DesignTokens.s12),
        Text(stay.title, style: DesignTokens.h2),
        if (stay.place.isNotEmpty || stay.addressLine != null)
          Text(
            stay.addressLine ?? stay.place,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        if (stay.starRating != null)
          Text(
            '★' * stay.starRating!.clamp(0, 5),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.secondaryYellow,
            ),
          ),
        if (stay.description != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(stay.description!, style: DesignTokens.smallRegular),
        ],
        if (stay.amenities.isNotEmpty) ...[
          const ServiceSectionTitle('Amenities'),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final a in stay.amenities) ServiceChip(label: _amenity(a)),
            ],
          ),
        ],
        const ServiceSectionTitle('Your stay'),
        ServiceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                key: StayDetailScreen.datesKey,
                onTap: () => unawaited(_pickDates()),
                leading: const Icon(Icons.date_range_outlined),
                title: Text(
                  '${serviceShortDate(_search.checkIn)} → '
                  '${serviceShortDate(_search.checkOut)}',
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
                      label: 'Guests',
                      keyPrefix: 'stay-detail-guests',
                      value: _search.guests,
                      min: 1,
                      max: 30,
                      onChanged: (v) => setState(() {
                        _search = _search.copyWith(guests: v);
                        _quoteError = null;
                      }),
                    ),
                    ServiceCounter(
                      label: 'Rooms',
                      keyPrefix: 'stay-detail-rooms',
                      value: _search.rooms,
                      min: 1,
                      max: 10,
                      onChanged: (v) => setState(() {
                        _search = _search.copyWith(rooms: v);
                        _quoteError = null;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (nights < stay.minNights ||
            (stay.maxNights != null && nights > stay.maxNights!))
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              stay.maxNights == null
                  ? 'Stays here are at least ${stay.minNights} nights.'
                  : 'Stays here are ${stay.minNights}–${stay.maxNights} '
                        'nights.',
              key: const Key('stay-nights-rule'),
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorWarning),
            ),
          ),
        const ServiceSectionTitle('Rooms'),
        if (stay.roomTypes.isEmpty)
          Text(
            'No rooms are listed yet.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          RadioGroup<String>(
            groupValue: _roomId,
            onChanged: (id) => setState(() {
              _roomId = id;
              _quoteError = null;
            }),
            child: Column(
              children: [
                for (final room in stay.roomTypes) ...[
                  _RoomCard(room: room, search: _search),
                  const SizedBox(height: DesignTokens.s8),
                ],
              ],
            ),
          ),
        if (_quoteError != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              _quoteError!,
              key: StayDetailScreen.quoteErrorKey,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        const ServiceSectionTitle('Policies'),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stay.checkInTime != null)
                ServiceRow(label: 'Check-in from', value: stay.checkInTime!),
              if (stay.checkOutTime != null)
                ServiceRow(label: 'Check-out by', value: stay.checkOutTime!),
              ServiceRow(
                label: 'Ways to pay',
                value: paymentModesLine(stay.paymentModes, stay.depositPercent),
              ),
              const SizedBox(height: DesignTokens.s8),
              Text('Cancellation', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              Text(
                policy.describe(),
                key: const Key('stay-cancellation-policy'),
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
        if (stay.latitude != null && stay.longitude != null) ...[
          const ServiceSectionTitle('Location'),
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
        if (stay.vendor != null) ...[
          const SizedBox(height: DesignTokens.s16),
          Text(
            'Listed by ${stay.vendor!.name}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}

String _amenity(String raw) {
  final s = raw.replaceAll(RegExp(r'[_\-]'), ' ').trim();
  if (s.isEmpty) return raw;
  return s[0].toUpperCase() + s.substring(1);
}

class _Photos extends StatelessWidget {
  const _Photos({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const ServicePhoto(url: null, height: 200, icon: Icons.hotel_outlined);
    }
    return SizedBox(
      height: 200,
      child: PageView.builder(
        key: const Key('service-photos'),
        itemCount: urls.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(right: DesignTokens.s4),
          child: ServicePhoto(url: urls[i], height: 200),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.search});

  final RoomType room;
  final StaySearch search;

  @override
  Widget build(BuildContext context) {
    final fits = room.fits(guests: search.guests, rooms: search.rooms);
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
    // A room that is sold out or too small cannot be picked; it stays on the
    // page, dimmed, so the buyer sees why.
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: _tile(fits, perNight, units),
      ),
    );
  }

  Widget _tile(bool fits, Money perNight, int? units) {
    return ServiceCard(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s4,
        vertical: DesignTokens.s8,
      ),
      child: RadioListTile<String>(
        key: StayDetailScreen.roomKey(room.id),
        value: room.id,
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
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
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              '${serviceMoney(perNight)} / night',
              key: Key('stay-room-price-${room.id}'),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (room.totalPrice != null)
              Text(
                '${serviceMoney(room.totalPrice!)} total',
                style: DesignTokens.tiny,
              ),
            if (room.soldOut)
              Text(
                'Sold out for these dates',
                style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
              )
            else if (!fits)
              Text(
                'Too small for ${search.guests} guests in '
                '${search.rooms == 1 ? '1 room' : '${search.rooms} rooms'}',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.colorWarning,
                ),
              )
            else if (units != null && units <= 3)
              Text(
                units == 1 ? 'Only 1 left' : 'Only $units left',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.colorWarning,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

