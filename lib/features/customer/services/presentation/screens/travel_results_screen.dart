import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

String travelSearchSummary(TravelSearch s) => [
  if (s.destination.isNotEmpty) s.destination else 'Anywhere',
  if (s.month != null) DateFormat('MMMM yyyy').format(s.month!) else 'Any time',
  s.travellers == 1 ? '1 traveller' : '${s.travellers} travellers',
].join(' · ');

/// Travel packages for a destination, month and party size.
class TravelResultsScreen extends ConsumerWidget {
  const TravelResultsScreen({required this.search, super.key});

  final TravelSearch search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(packageSearchProvider(search));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Trips'),
      ),
      body: SafeArea(
        child: results.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'trips',
                onRetry: () => ref.invalidate(packageSearchProvider(search)),
              ),
            ],
          ),
          data: (items) => ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              Text(
                travelSearchSummary(search),
                key: const Key('travel-results-summary'),
                style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
              ),
              const SizedBox(height: DesignTokens.s12),
              if (items.isEmpty)
                const SmEmptyState(
                  key: Key('travel-results-empty'),
                  title: 'No trips found',
                  message: 'Try another month or destination.',
                  icon: Icons.terrain_outlined,
                )
              else
                for (final item in items) ...[
                  PackageResultTile(
                    item: item,
                    onTap: () => context.push(
                      Uri(
                        path: RouteNames.serviceTravelDetailPath(item.listingId),
                        queryParameters: search.toQuery(),
                      ).toString(),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class PackageResultTile extends StatelessWidget {
  const PackageResultTile({required this.item, required this.onTap, super.key});

  final PackageSearchItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final days = item.durationDays;
    final next = item.nextDepartureDate;
    return InkWell(
      key: Key('package-result-${item.listingId}'),
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
              icon: Icons.terrain_outlined,
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: DesignTokens.mediumSemibold),
                  Text(
                    [
                      ?item.destination,
                      if (days != null) days == 1 ? '1 day' : '$days days',
                      if (item.vendor != null) item.vendor!.name,
                    ].join(' · '),
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
                          [
                            if (next != null) 'Next: ${serviceDate(next)}',
                            paymentModesLine(
                              item.paymentModes,
                              item.depositPercent,
                            ),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ),
                      if (item.fromPrice != null)
                        Text(
                          'from ${serviceMoney(item.fromPrice!)}',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
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
