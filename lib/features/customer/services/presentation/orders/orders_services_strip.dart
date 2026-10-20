import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The top of My orders for stays, trips and banks — there is no Services
/// tab (2026-10-19): the next upcoming booking with its dates and booking
/// reference, and the way to every booking and to bank enquiries and
/// appointments.
///
/// Quiet when there is nothing to say: no bookings (or the bookings service
/// not deployed yet) shows only the two links.
class OrdersServicesStrip extends ConsumerWidget {
  const OrdersServicesStrip({super.key});

  static const Key bookingsKey = Key('orders-bookings-link');
  static const Key bankRequestsKey = Key('orders-bank-requests-link');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = kathmanduDay(ref.watch(servicesClockProvider)());
    final upcoming =
        ref
            .watch(myBookingsProvider)
            .asData
            ?.value
            .where((b) => b.isUpcoming(today))
            .toList() ??
        [];
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    final next = upcoming.firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (next != null) ...[
            BookingTile(
              booking: next,
              onTap: () => unawaited(
                context.push(RouteNames.bookingDetailPath(next.id)),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              ActionChip(
                key: bookingsKey,
                avatar: const Icon(Icons.event_available_outlined, size: 18),
                label: Text(
                  upcoming.length > 1
                      ? 'Bookings · ${upcoming.length} upcoming'
                      : 'Bookings',
                ),
                onPressed: () =>
                    unawaited(context.push(RouteNames.myBookings)),
              ),
              ActionChip(
                key: bankRequestsKey,
                avatar: const Icon(Icons.account_balance_outlined, size: 18),
                label: const Text('Bank enquiries & appointments'),
                onPressed: () =>
                    unawaited(context.push(RouteNames.myBankRequests)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
