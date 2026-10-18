import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One travel package: itinerary, inclusions and exclusions, departures
/// with seats left. Choose a departure and who is coming, and Book asks the
/// server for a price before the booking screen.
class PackageDetailScreen extends ConsumerStatefulWidget {
  const PackageDetailScreen({
    required this.listingId,
    this.travellers = 2,
    super.key,
  });

  final String listingId;

  /// From the search, as the starting number of adults.
  final int travellers;

  static const Key bookKey = Key('package-book');
  static const Key quoteErrorKey = Key('package-quote-error');
  static Key departureKey(String id) => Key('package-departure-$id');

  @override
  ConsumerState<PackageDetailScreen> createState() =>
      _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<PackageDetailScreen> {
  String? _departureId;
  late int _adults = widget.travellers.clamp(1, 50);
  int _children = 0;
  bool _quoting = false;
  String? _quoteError;

  Future<void> _book(PackageDetail pkg) async {
    final departure = pkg.departures
        .where((d) => d.id == _departureId)
        .firstOrNull;
    if (departure == null) return;
    if (_adults + _children > departure.seatsAvailable) {
      setState(
        () => _quoteError = departure.seatsAvailable == 1
            ? 'This departure has 1 seat left. Choose fewer travellers.'
            : 'This departure has ${departure.seatsAvailable} seats left. Choose '
                  'fewer travellers.',
      );
      return;
    }
    if (!await servicesEnsureAuth(context, ref) || !mounted) return;
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    final result = await ref
        .read(bookingsRepositoryProvider)
        .quotePackage(
          listingId: pkg.listingId,
          departureId: departure.id,
          adults: _adults,
          children: _children,
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
        unawaited(
          context.push(
            RouteNames.bookingCheckout,
            extra: BookingCheckoutArgs(
              quote: quote,
              listingTitle: pkg.title,
              itemName: 'Departs ${serviceDate(departure.date)}',
              photoUrl: pkg.photoUrls.firstOrNull,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pkg = ref.watch(packageDetailProvider(widget.listingId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(pkg.asData?.value.title ?? 'Trip'),
      ),
      body: SafeArea(
        child: pkg.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this trip',
                onRetry: () =>
                    ref.invalidate(packageDetailProvider(widget.listingId)),
              ),
            ],
          ),
          data: _body,
        ),
      ),
      bottomNavigationBar: pkg.asData == null
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
                  key: PackageDetailScreen.bookKey,
                  label: _departureId == null ? 'Choose a departure' : 'Book',
                  busy: _quoting,
                  onPressed: _departureId == null
                      ? null
                      : () => unawaited(_book(pkg.asData!.value)),
                ),
              ),
            ),
    );
  }

  Widget _body(PackageDetail pkg) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s16),
    children: [
      if (pkg.photoUrls.isEmpty)
        const ServicePhoto(url: null, height: 200, icon: Icons.terrain_outlined)
      else
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: pkg.photoUrls.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: DesignTokens.s4),
              child: ServicePhoto(url: pkg.photoUrls[i], height: 200),
            ),
          ),
        ),
      const SizedBox(height: DesignTokens.s12),
      Text(pkg.title, style: DesignTokens.h2),
      Text(
        [
          ?pkg.destination,
          ?pkg.durationLabel,
          if (pkg.vendor != null) pkg.vendor!.name,
        ].join(' · '),
        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
      ),
      if (pkg.description != null) ...[
        const SizedBox(height: DesignTokens.s12),
        Text(pkg.description!, style: DesignTokens.smallRegular),
      ],
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
                    key: Key('package-day-${day.day}'),
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
        for (final i in pkg.inclusions) ServiceBullet(i),
      ],
      if (pkg.exclusions.isNotEmpty) ...[
        const ServiceSectionTitle('Not included'),
        for (final e in pkg.exclusions)
          ServiceBullet(
            e,
            icon: Icons.close_rounded,
            color: DesignTokens.colorError,
          ),
      ],
      const ServiceSectionTitle('Departures'),
      if (pkg.departures.isEmpty)
        Text(
          'No dates yet. Check back soon.',
          key: const Key('package-no-departures'),
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        )
      else
        RadioGroup<String>(
          groupValue: _departureId,
          onChanged: (id) => setState(() {
            _departureId = id;
            _quoteError = null;
          }),
          child: Column(
            children: [
              for (final d in pkg.departures) ...[
                _DepartureCard(departure: d),
                const SizedBox(height: DesignTokens.s8),
              ],
            ],
          ),
        ),
      const ServiceSectionTitle('Who is coming'),
      ServiceCard(
        child: Column(
          children: [
            ServiceCounter(
              label: 'Adults',
              keyPrefix: 'package-adults',
              value: _adults,
              min: 1,
              max: 50,
              onChanged: (v) => setState(() {
                _adults = v;
                _quoteError = null;
              }),
            ),
            ServiceCounter(
              label: 'Children',
              keyPrefix: 'package-children',
              value: _children,
              max: 50,
              caption: 'Under 12',
              onChanged: (v) => setState(() {
                _children = v;
                _quoteError = null;
              }),
            ),
          ],
        ),
      ),
      if (_quoteError != null)
        Padding(
          padding: const EdgeInsets.only(top: DesignTokens.s8),
          child: Text(
            _quoteError!,
            key: PackageDetailScreen.quoteErrorKey,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ),
      const ServiceSectionTitle('Good to know'),
      ServiceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pkg.meetingPoint != null)
              ServiceRow(label: 'Meeting point', value: pkg.meetingPoint!),
            if (pkg.maxGroupSize != null)
              ServiceRow(label: 'Group size', value: 'Up to ${pkg.maxGroupSize}'),
            ServiceRow(
              label: 'Ways to pay',
              value: paymentModesLine(pkg.paymentModes, pkg.depositPercent),
            ),
            const SizedBox(height: DesignTokens.s8),
            const Text('Cancellation', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s4),
            Text(
              pkg.cancellationPolicy.describe(),
              key: const Key('package-cancellation-policy'),
              style: DesignTokens.smallRegular,
            ),
          ],
        ),
      ),
      if (pkg.latitude != null && pkg.longitude != null) ...[
        const ServiceSectionTitle('Meeting point'),
        ServiceMapBox(
          pins: [
            ServiceMapPin(
              id: pkg.listingId,
              latitude: pkg.latitude!,
              longitude: pkg.longitude!,
              label: pkg.meetingPoint,
            ),
          ],
        ),
      ],
      const SizedBox(height: DesignTokens.s24),
    ],
  );
}

class _DepartureCard extends StatelessWidget {
  const _DepartureCard({required this.departure});

  final Departure departure;

  @override
  Widget build(BuildContext context) {
    final d = departure;
    final seats = d.seatsAvailable;
    final end = d.endDate;
    return IgnorePointer(
      ignoring: !d.bookable,
      child: Opacity(
        opacity: d.bookable ? 1 : 0.5,
        child: ServiceCard(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s4),
          child: RadioListTile<String>(
            key: PackageDetailScreen.departureKey(d.id),
            value: d.id,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s8,
            ),
            title: Text(
              end == null
                  ? serviceDate(d.date)
                  : '${serviceShortDate(d.date)} → ${serviceShortDate(end)}',
              style: DesignTokens.mediumSemibold,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.childPrice == null
                      ? '${serviceMoney(d.adultPrice)} per person'
                      : '${serviceMoney(d.adultPrice)} adult · '
                            '${serviceMoney(d.childPrice!)} child',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
                Text(
                  !d.open
                      ? 'Not taking bookings'
                      : seats <= 0
                      ? 'Full'
                      : seats == 1
                      ? '1 seat left'
                      : '$seats seats left',
                  key: Key('package-seats-${d.id}'),
                  style: DesignTokens.tiny.copyWith(
                    color: seats <= 3
                        ? DesignTokens.colorWarning
                        : DesignTokens.textMuted,
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
