import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/booking_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/banks_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Which list [MyBookingsScreen] opens on.
enum MyBookingsTab { upcoming, past, banks }

/// The buyer's stays and trips — upcoming and past — and their bank
/// enquiries and appointments with their status. Reached from Orders and
/// Profile (there is no Services tab since 2026-10-19).
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({this.initialTab = MyBookingsTab.upcoming, super.key});

  final MyBookingsTab initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DefaultTabController(
    length: 3,
    initialIndex: initialTab.index,
    child: Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Bookings & bank requests'),
        bottom: const TabBar(
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          indicatorColor: DesignTokens.primaryGreen,
          tabs: [
            Tab(key: Key('my-bookings-tab-upcoming'), text: 'Upcoming'),
            Tab(key: Key('my-bookings-tab-past'), text: 'Past'),
            Tab(key: Key('my-bookings-tab-banks'), text: 'Banks'),
          ],
        ),
      ),
      body: const SafeArea(
        child: TabBarView(
          children: [
            _BookingsList(upcoming: true),
            _BookingsList(upcoming: false),
            _BankRequestsList(),
          ],
        ),
      ),
    ),
  );
}

class _BookingsList extends ConsumerWidget {
  const _BookingsList({required this.upcoming});

  final bool upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = kathmanduDay(ref.watch(servicesClockProvider)());
    return RefreshIndicator(
      onRefresh: () async {
        refreshBookings(ref);
        try {
          await ref.read(myBookingsProvider.future);
        } on Object {
          // The list shows the failure itself.
        }
      },
      child: ref
          .watch(myBookingsProvider)
          .when(
            loading: () => const SmPageLoader(),
            error: (error, _) => ListView(
              children: [
                ServiceFailureView(
                  error: error,
                  what: 'your bookings',
                  onRetry: () => refreshBookings(ref),
                ),
              ],
            ),
            data: (all) {
              final list = [
                for (final b in all)
                  if (b.isUpcoming(today) == upcoming) b,
              ];
              if (upcoming) {
                list.sort((a, b) => a.startDate.compareTo(b.startDate));
              } else {
                list.sort((a, b) => b.startDate.compareTo(a.startDate));
              }
              if (list.isEmpty) {
                return ListView(
                  children: [
                    SmEmptyState(
                      key: Key(
                        upcoming
                            ? 'my-bookings-empty-upcoming'
                            : 'my-bookings-empty-past',
                      ),
                      title: upcoming ? 'Nothing coming up' : 'No past bookings',
                      message: upcoming
                          ? 'Stays and trips you book show here.'
                          : 'Finished and cancelled bookings show here.',
                      icon: Icons.event_note_outlined,
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s16),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (context, i) => BookingTile(
                  booking: list[i],
                  onTap: () =>
                      context.push(RouteNames.bookingDetailPath(list[i].id)),
                ),
              );
            },
          ),
    );
  }
}

/// Enquiries and appointments together, newest first. Either list failing
/// on its own still shows the other.
class _BankRequestsList extends ConsumerWidget {
  const _BankRequestsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enquiries = ref.watch(myEnquiriesProvider);
    final appointments = ref.watch(myAppointmentsProvider);
    if (enquiries.isLoading && appointments.isLoading) {
      return const SmPageLoader();
    }
    final e = enquiries.asData?.value;
    final a = appointments.asData?.value;
    if (e == null && a == null) {
      final error = enquiries.error ?? appointments.error;
      if (error != null) {
        return ListView(
          children: [
            ServiceFailureView(
              error: error,
              what: 'your bank requests',
              onRetry: () => ref
                ..invalidate(myEnquiriesProvider)
                ..invalidate(myAppointmentsProvider),
            ),
          ],
        );
      }
      return const SmPageLoader();
    }
    // Appointment leads appear as appointments, not twice.
    final enquiryRows = [
      for (final lead in e ?? const <BankLead>[])
        if (lead.kind != LeadKind.appointment) lead,
    ];
    final rows = <(DateTime, Widget)>[
      for (final lead in enquiryRows)
        (
          lead.createdAt ?? DateTime(0),
          _EnquiryTile(lead: lead),
        ),
      for (final appt in a ?? const <BankAppointment>[])
        (appt.createdAt ?? appt.date, _AppointmentTile(appointment: appt)),
    ]..sort((x, y) => y.$1.compareTo(x.$1));
    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myEnquiriesProvider)
          ..invalidate(myAppointmentsProvider);
      },
      child: rows.isEmpty
          ? ListView(
              children: const [
                SmEmptyState(
                  key: Key('my-bank-requests-empty'),
                  title: 'No bank requests',
                  message:
                      'Enquiries you send to banks and branch appointments '
                      'you book show here.',
                  icon: Icons.account_balance_outlined,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(DesignTokens.s16),
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.s12),
              itemBuilder: (_, i) => rows[i].$2,
            ),
    );
  }
}

class _EnquiryTile extends StatelessWidget {
  const _EnquiryTile({required this.lead});

  final BankLead lead;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('enquiry-tile-${lead.id}'),
    borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    onTap: () => context.push(RouteNames.bankEnquiryDetailPath(lead.id)),
    child: ServiceCard(
      child: Row(
        children: [
          const Icon(Icons.mail_outline, color: DesignTokens.textLight),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lead.title, style: DesignTokens.mediumSemibold),
                Text(
                  [lead.bankName, lead.reference]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          LeadStatusChip(lead: lead),
        ],
      ),
    ),
  );
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment});

  final BankAppointment appointment;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('appointment-tile-${appointment.id}'),
    borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    onTap: () =>
        context.push(RouteNames.bankAppointmentDetailPath(appointment.id)),
    child: ServiceCard(
      child: Row(
        children: [
          const Icon(Icons.event_available_outlined, color: DesignTokens.textLight),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${appointment.bankName} · ${appointment.branchName}',
                  style: DesignTokens.mediumSemibold,
                ),
                Text(
                  appointmentWhen(appointment),
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          AppointmentStatusChip(status: appointment.status),
        ],
      ),
    ),
  );
}

