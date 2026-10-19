import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Kathmandu · Sat, 24 Oct → Mon, 26 Oct · 2 guests · 1 room".
String staySearchSummary(StaySearch s) => [
  if (s.location.isNotEmpty) s.location,
  '${serviceShortDate(s.checkIn)} → ${serviceShortDate(s.checkOut)}',
  s.guests == 1 ? '1 guest' : '${s.guests} guests',
  s.rooms == 1 ? '1 room' : '${s.rooms} rooms',
].join(' · ');

/// Stays for a search, with their pins on a map when the server sends
/// coordinates.
class StayResultsScreen extends ConsumerWidget {
  const StayResultsScreen({required this.search, super.key});

  /// Null when the route's query could not be read.
  final StaySearch? search;

  String _detailLocation(String listingId, StaySearch s) => Uri(
    path: RouteNames.serviceStayDetailPath(listingId),
    queryParameters: s.toQuery(),
  ).toString();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = search;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Stays'),
      ),
      body: SafeArea(
        child: s == null
            ? const SmEmptyState(
                title: 'Search again',
                message: 'Pick your dates to see stays.',
                icon: Icons.hotel_outlined,
              )
            : ref
                  .watch(staySearchProvider(s))
                  .when(
                    loading: () => const SmPageLoader(),
                    error: (error, _) => ListView(
                      children: [
                        ServiceFailureView(
                          error: error,
                          what: 'stays',
                          onRetry: () => ref.invalidate(staySearchProvider(s)),
                        ),
                      ],
                    ),
                    data: (items) {
                      final pins = [
                        for (final i in items)
                          if (i.latitude != null && i.longitude != null)
                            ServiceMapPin(
                              id: i.listingId,
                              latitude: i.latitude!,
                              longitude: i.longitude!,
                              label: i.title,
                            ),
                      ];
                      return ListView(
                        padding: const EdgeInsets.all(DesignTokens.s16),
                        children: [
                          Text(
                            staySearchSummary(s),
                            key: const Key('stay-results-summary'),
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.s12),
                          if (pins.isNotEmpty) ...[
                            ServiceMapBox(
                              pins: pins,
                              onPinTap: (id) =>
                                  context.push(_detailLocation(id, s)),
                            ),
                            const SizedBox(height: DesignTokens.s12),
                          ],
                          if (items.isEmpty)
                            const SmEmptyState(
                              key: Key('stay-results-empty'),
                              title: 'No stays found',
                              message:
                                  'Nothing is free for these dates. Try other '
                                  'dates or a nearby area.',
                              icon: Icons.hotel_outlined,
                            )
                          else
                            for (final item in items) ...[
                              StayResultTile(
                                item: item,
                                onTap: () => context.push(
                                  _detailLocation(item.listingId, s),
                                ),
                              ),
                              const SizedBox(height: DesignTokens.s12),
                            ],
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}

/// The ways to pay a listing allows, as short labels.
String paymentModesLine(List<PaymentMode> modes, double depositPercent) {
  String pct(double v) =>
      v == v.roundToDouble() ? '${v.toInt()}%' : '${v.toStringAsFixed(1)}%';
  return [
    for (final m in modes)
      switch (m) {
        PaymentMode.fullPrepay => 'Pay online',
        PaymentMode.deposit => '${pct(depositPercent)} deposit',
        PaymentMode.payAtVenue => 'Pay at venue',
      },
  ].join(' · ');
}

class StayResultTile extends StatelessWidget {
  const StayResultTile({required this.item, required this.onTap, super.key});

  final StaySearchItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nights = item.nights;
    final total = item.totalPrice;
    final from = item.fromPricePerNight;
    return InkWell(
      key: Key('stay-result-${item.listingId}'),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: onTap,
      child: ServiceCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ServicePhoto(
              url: item.coverPhotoUrl,
              height: 150,
              radius: 0,
              icon: Icons.hotel_outlined,
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: DesignTokens.mediumSemibold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.starRating != null)
                        Text(
                          '★' * item.starRating!.clamp(0, 5),
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.secondaryYellow,
                          ),
                        ),
                    ],
                  ),
                  if (item.place.isNotEmpty)
                    Text(
                      item.place,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  const SizedBox(height: DesignTokens.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          paymentModesLine(
                            item.paymentModes,
                            item.depositPercent,
                          ),
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (total != null && nights != null)
                            Text(
                              serviceMoney(total),
                              key: Key('stay-result-total-${item.listingId}'),
                              style: DesignTokens.mediumSemibold.copyWith(
                                color: DesignTokens.primaryGreen,
                              ),
                            ),
                          Text(
                            total != null && nights != null
                                ? nights == 1
                                      ? 'for 1 night'
                                      : 'for $nights nights'
                                : from == null
                                ? ''
                                : 'from ${serviceMoney(from)} / night',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
