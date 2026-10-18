import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/shared/bank_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_bookings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/shared/booking_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The service vendor's "today" at the top of the seller dashboard: a
/// hotel's arrivals and check-outs, a travel agency's departures, a bank's
/// new leads and appointments — with one tap to each list. Draws nothing for
/// a product seller.
class ServiceVendorTodayCard extends ConsumerWidget {
  const ServiceVendorTodayCard({super.key});

  static const Key cardKey = Key('service-vendor-today-card');
  static const Key primaryKey = Key('service-vendor-today-primary');
  static const Key secondaryKey = Key('service-vendor-today-secondary');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(vendorServiceCategoryNowProvider);
    return switch (category) {
      ServiceCategory.none => const SizedBox.shrink(),
      ServiceCategory.bank => const _BankToday(),
      ServiceCategory.hotel ||
      ServiceCategory.travelAgency => _BookingsToday(category: category),
    };
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.title,
    required this.lines,
    required this.primaryLabel,
    required this.primaryRoute,
    required this.secondaryLabel,
    required this.secondaryRoute,
  });

  final String title;
  final List<String> lines;
  final String primaryLabel;
  final String primaryRoute;
  final String secondaryLabel;
  final String secondaryRoute;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
    child: ServiceCard(
      key: ServiceVendorTodayCard.cardKey,
      borderColor: DesignTokens.primaryGreen.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s4),
          for (final line in lines)
            Text(
              line,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: ServiceActionButton(
                  key: ServiceVendorTodayCard.primaryKey,
                  label: primaryLabel,
                  onPressed: () => context.push(primaryRoute),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: ServiceActionButton(
                  key: ServiceVendorTodayCard.secondaryKey,
                  label: secondaryLabel,
                  outlined: true,
                  onPressed: () => context.push(secondaryRoute),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BookingsToday extends ConsumerWidget {
  const _BookingsToday({required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(vendorBookingsTodayProvider);
    final summary = ref.watch(vendorBookingsSummaryProvider).value;
    final words = BookingDayWords.of(category);
    final lines = <String>[];
    final b = board.value;
    if (b != null) {
      lines.add(
        '${b.arrivals.length} ${words.arriving.toLowerCase()} · '
        '${b.leaving.length} ${words.leaving.toLowerCase()} · '
        '${b.inHouse.length} ${words.inHouse.toLowerCase()}',
      );
    } else if (serviceUnavailable(board.error)) {
      lines.add('Bookings are being set up.');
    } else if (board.hasError) {
      lines.add('Could not load today\'s bookings.');
    } else {
      lines.add('Loading today\'s bookings…');
    }
    if (summary != null) {
      if (summary.upcoming > 0) lines.add('${summary.upcoming} upcoming');
      if (summary.balanceToCollect.amount > 0) {
        lines.add(
          '${serviceMoney(summary.balanceToCollect)} to collect at the venue',
        );
      }
    }
    return _Frame(
      title: category == ServiceCategory.hotel
          ? 'Today at your property'
          : 'Today\'s trips',
      lines: lines,
      primaryLabel: 'Bookings',
      primaryRoute: ServiceRoutes.bookings,
      secondaryLabel: 'Availability',
      secondaryRoute: ServiceRoutes.availability,
    );
  }
}

class _BankToday extends ConsumerWidget {
  const _BankToday();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(bankVendorSummaryProvider);
    final today = ref.watch(serviceTodayProvider);
    final appointments = ref.watch(bankAppointmentsForDayProvider(today)).value;
    final s = summary.value;
    final lines = <String>[
      if (s != null)
        '${s.newLeads} new ${s.newLeads == 1 ? 'lead' : 'leads'} · '
            '${s.upcomingAppointments} upcoming '
            '${s.upcomingAppointments == 1 ? 'appointment' : 'appointments'}'
      else if (serviceUnavailable(summary.error))
        'Leads and appointments are being set up.'
      else if (summary.hasError)
        'Could not load your leads.'
      else
        'Loading your leads…',
      if (appointments != null)
        '${appointments.where((a) => a.isBooked).length} branch '
            '${appointments.where((a) => a.isBooked).length == 1 ? 'visit' : 'visits'} today',
    ];
    return _Frame(
      title: 'Today at your bank',
      lines: lines,
      primaryLabel: 'Leads',
      primaryRoute: ServiceRoutes.bankLeads,
      secondaryLabel: 'Appointments',
      secondaryRoute: ServiceRoutes.bankAppointments,
    );
  }
}


/// Reloads what [ServiceVendorTodayCard] shows (the dashboard's
/// pull-to-refresh). Harmless for a product seller: nothing is watching.
void refreshServiceVendorToday(WidgetRef ref) {
  ref
    ..invalidate(vendorBookingsTodayProvider)
    ..invalidate(vendorBookingsSummaryProvider)
    ..invalidate(bankVendorSummaryProvider)
    ..invalidate(bankAppointmentsForDayProvider);
}
