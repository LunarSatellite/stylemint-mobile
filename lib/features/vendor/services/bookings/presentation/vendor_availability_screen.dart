import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/shared/booking_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const _settingUpTitle = 'Availability is being set up';

/// The quick view of what is still free: rooms per night for a hotel, seats
/// per departure for a travel agency — with a tap to close a night or a
/// departure to new bookings (or reopen it). Prices, room types and new
/// departures are edited in Seller Center on the web.
class VendorAvailabilityScreen extends ConsumerWidget {
  const VendorAvailabilityScreen({this.kind, super.key});

  /// Forces stays or packages; by default the vendor's category decides.
  final ServiceListingKind? kind;

  static Key nightKey(String roomTypeId, DateTime date) =>
      Key('availability-night-$roomTypeId-${wireDate(date)}');
  static Key departureSwitchKey(String departureId) =>
      Key('availability-departure-$departureId');
  static const Key tonightKey = Key('availability-tonight');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final k =
        kind ??
        (ref.watch(vendorServiceCategoryNowProvider) ==
                ServiceCategory.travelAgency
            ? ServiceListingKind.package
            : ServiceListingKind.stay);
    final listings = ref.watch(vendorListingsProvider(k));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(
          k == ServiceListingKind.stay ? 'Rooms available' : 'Seats available',
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(vendorListingsProvider(k));
            await ref.read(vendorListingsProvider(k).future);
          },
          child: switch ((listings.value, listings.error)) {
            (final List<VendorListing> items, _) when items.isEmpty =>
              ListView(
                children: [
                  SmEmptyState(
                    icon: Icons.hotel_outlined,
                    message: k == ServiceListingKind.stay
                        ? 'No stays yet. Add your property and room types in '
                              'Seller Center on the web.'
                        : 'No travel packages yet. Add them in Seller Center '
                              'on the web.',
                  ),
                ],
              ),
            (final List<VendorListing> items, _) =>
              k == ServiceListingKind.stay
                  ? _StaysView(listings: items)
                  : _PackagesView(listings: items),
            (_, final Object error) => ListView(
              children: [
                ServiceLoadFailureView(
                  error: error,
                  settingUpTitle: _settingUpTitle,
                  fallback: 'We could not load your listings.',
                  specific: bookingErrorMessage,
                  onRetry: () => ref.invalidate(vendorListingsProvider(k)),
                ),
              ],
            ),
            _ => const SmPageLoader(),
          },
        ),
      ),
    );
  }
}

class _StaysView extends ConsumerWidget {
  const _StaysView({required this.listings});

  final List<VendorListing> listings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(serviceTodayProvider);
    final roomTypes = [
      for (final l in listings)
        for (final r in l.roomTypes)
          if (!r.archived) r,
    ];
    var free = 0;
    var known = true;
    for (final r in roomTypes) {
      final nights = ref.watch(roomTypeNightsProvider(r.id)).value;
      if (nights == null) {
        known = false;
        continue;
      }
      for (final n in nights) {
        if (daysBetween(today, n.date) == 0 && !n.closed) free += n.available;
      }
    }
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        ServiceCard(
          key: VendorAvailabilityScreen.tonightKey,
          child: Text(
            known
                ? '$free ${free == 1 ? 'room' : 'rooms'} free tonight'
                : 'Counting rooms free tonight…',
            style: DesignTokens.mediumSemibold,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Tap a night to close it to new bookings, or to reopen it. '
          'Existing bookings are not affected.',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        for (final l in listings) ...[
          ServiceSectionTitle(
            l.status == ServiceListingStatus.published
                ? l.title
                : '${l.title} (${l.status.label})',
          ),
          if (l.roomTypes.where((r) => !r.archived).isEmpty)
            Text(
              'No room types yet.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          for (final r in l.roomTypes)
            if (!r.archived) ...[
              _RoomTypeStrip(roomType: r),
              const SizedBox(height: DesignTokens.s12),
            ],
        ],
      ],
    );
  }
}

class _RoomTypeStrip extends ConsumerStatefulWidget {
  const _RoomTypeStrip({required this.roomType});

  final VendorRoomType roomType;

  @override
  ConsumerState<_RoomTypeStrip> createState() => _RoomTypeStripState();
}

class _RoomTypeStripState extends ConsumerState<_RoomTypeStrip> {
  DateTime? _saving;

  Future<void> _toggle(RoomNight night) async {
    final closing = !night.closed;
    final ok = await confirmServiceAction(
      context,
      title: closing
          ? 'Close ${serviceDateText(night.date)}?'
          : 'Reopen ${serviceDateText(night.date)}?',
      message: closing
          ? 'No new bookings for ${widget.roomType.name} that night. '
                '${night.booked} existing ${night.booked == 1 ? 'booking stays' : 'bookings stay'}.'
          : '${widget.roomType.name} can be booked again that night.',
      confirmLabel: closing ? 'Close night' : 'Reopen',
    );
    if (!ok || !mounted) return;
    setState(() => _saving = night.date);
    final result = await ref
        .read(vendorBookingsRepositoryProvider)
        .setNightClosed(widget.roomType.id, night.date, closed: closing);
    if (!mounted) return;
    setState(() => _saving = null);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serviceFailureMessage(f, specific: bookingErrorMessage),
          ),
        ),
      ),
      (_) => ref.invalidate(roomTypeNightsProvider(widget.roomType.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.roomType;
    final nights = ref.watch(roomTypeNightsProvider(r.id));
    final today = ref.watch(serviceTodayProvider);
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    return ServiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.name, style: DesignTokens.mediumSemibold),
          Text('${r.totalUnits} ${r.totalUnits == 1 ? 'room' : 'rooms'}', style: muted),
          const SizedBox(height: DesignTokens.s8),
          switch ((nights.value, nights.error)) {
            (final List<RoomNight> list, _) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final n in list)
                    Padding(
                      padding: const EdgeInsets.only(right: DesignTokens.s8),
                      child: _NightChip(
                        key: VendorAvailabilityScreen.nightKey(r.id, n.date),
                        night: n,
                        today: today,
                        saving: _saving != null &&
                            daysBetween(_saving!, n.date) == 0,
                        onTap: _saving == null ? () => _toggle(n) : null,
                      ),
                    ),
                ],
              ),
            ),
            (_, final Object error) => Text(
              serviceUnavailable(error)
                  ? 'Availability is being set up.'
                  : 'Could not load this room type\'s nights.',
              style: muted,
            ),
            _ => const LinearProgressIndicator(),
          },
        ],
      ),
    );
  }
}

class _NightChip extends StatelessWidget {
  const _NightChip({
    required this.night,
    required this.today,
    required this.saving,
    required this.onTap,
    super.key,
  });

  final RoomNight night;
  final DateTime today;
  final bool saving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = night;
    final full = !n.closed && n.available <= 0;
    final color = n.closed
        ? DesignTokens.textMuted
        : full
        ? DesignTokens.colorError
        : DesignTokens.colorSuccess;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Column(
          children: [
            Text(
              daysBetween(today, n.date) == 0
                  ? 'Tonight'
                  : serviceShortDateText(n.date).split(' ').first,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            Text('${n.date.day}', style: DesignTokens.mediumSemibold),
            if (saving)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                n.closed ? 'Closed' : full ? 'Full' : '${n.available} free',
                style: DesignTokens.tiny.copyWith(color: color),
              ),
          ],
        ),
      ),
    );
  }
}

class _PackagesView extends StatelessWidget {
  const _PackagesView({required this.listings});

  final List<VendorListing> listings;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s16),
    children: [
      Text(
        'Switch a departure off to stop new bookings; switch it on to '
        'reopen it. Existing bookings are not affected.',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
      for (final l in listings) ...[
        ServiceSectionTitle(
          l.status == ServiceListingStatus.published
              ? l.title
              : '${l.title} (${l.status.label})',
        ),
        _Departures(listingId: l.id),
      ],
    ],
  );
}

class _Departures extends ConsumerStatefulWidget {
  const _Departures({required this.listingId});

  final String listingId;

  @override
  ConsumerState<_Departures> createState() => _DeparturesState();
}

class _DeparturesState extends ConsumerState<_Departures> {
  String? _saving;

  Future<void> _set(VendorDeparture d, {required bool open}) async {
    setState(() => _saving = d.id);
    final result = await ref
        .read(vendorBookingsRepositoryProvider)
        .setDepartureClosed(d.id, closed: !open);
    if (!mounted) return;
    setState(() => _saving = null);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            serviceFailureMessage(f, specific: bookingErrorMessage),
          ),
        ),
      ),
      (_) => ref.invalidate(listingDeparturesProvider(widget.listingId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final departures = ref.watch(listingDeparturesProvider(widget.listingId));
    final today = ref.watch(serviceTodayProvider);
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    return switch ((departures.value, departures.error)) {
      (final List<VendorDeparture> list, _) when list.isEmpty => Text(
        'No upcoming departures.',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
      (final List<VendorDeparture> list, _) => Column(
        children: [
          for (final d in list)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: ServiceCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.date == null
                                ? 'Date to be confirmed'
                                : '${serviceRelativeDay(d.date!, today)} · ${serviceDateText(d.date!)}',
                            style: DesignTokens.mediumSemibold,
                          ),
                          Text(
                            d.status == DepartureStatus.cancelled
                                ? 'Cancelled'
                                : d.seatsAvailable <= 0
                                ? 'Full · ${d.seatsTotal} seats'
                                : '${d.seatsAvailable} of ${d.seatsTotal} seats left',
                            style: muted,
                          ),
                        ],
                      ),
                    ),
                    if (d.status != DepartureStatus.cancelled)
                      _saving == d.id
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch(
                              key: VendorAvailabilityScreen.departureSwitchKey(
                                d.id,
                              ),
                              value: d.status == DepartureStatus.open,
                              onChanged: _saving != null
                                  ? null
                                  : (open) => _set(d, open: open),
                            ),
                  ],
                ),
              ),
            ),
        ],
      ),
      (_, final Object error) => Text(
        serviceUnavailable(error)
            ? 'Departures are being set up.'
            : 'Could not load the departures.',
        style: muted,
      ),
      _ => const LinearProgressIndicator(),
    };
  }
}
