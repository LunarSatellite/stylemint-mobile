import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/shared/bank_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A day's branch appointments (today by default), by start time, with a
/// branch filter for banks with more than one branch.
class BankAppointmentsScreen extends ConsumerStatefulWidget {
  const BankAppointmentsScreen({super.key});

  static Key dayChipKey(int offset) => Key('bank-appointments-day-$offset');
  static Key branchChipKey(String? branch) =>
      Key('bank-appointments-branch-${branch ?? 'all'}');
  static Key tileKey(String id) => Key('bank-appointment-tile-$id');

  @override
  ConsumerState<BankAppointmentsScreen> createState() =>
      _BankAppointmentsScreenState();
}

class _BankAppointmentsScreenState
    extends ConsumerState<BankAppointmentsScreen> {
  int _offset = 0;
  String? _branch;

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(serviceTodayProvider);
    final day = today.add(Duration(days: _offset));
    final appointments = ref.watch(bankAppointmentsForDayProvider(day));
    final loaded = appointments.value;
    final branches = <String>{
      for (final a in loaded ?? const <BankAppointment>[])
        if (a.branchName != null) a.branchName!,
    }.toList()..sort();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Branch appointments'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: DesignTokens.s8),
                      child: ChoiceChip(
                        key: BankAppointmentsScreen.dayChipKey(i),
                        label: Text(
                          serviceRelativeDay(
                            today.add(Duration(days: i)),
                            today,
                          ),
                        ),
                        selected: _offset == i,
                        selectedColor: DesignTokens.chipsSelectedFill,
                        onSelected: (_) => setState(() {
                          _offset = i;
                          _branch = null;
                        }),
                      ),
                    ),
                ],
              ),
            ),
            if (branches.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s4,
                  DesignTokens.s16,
                  0,
                ),
                child: Row(
                  children: [
                    for (final b in <String?>[null, ...branches])
                      Padding(
                        padding: const EdgeInsets.only(
                          right: DesignTokens.s8,
                        ),
                        child: ChoiceChip(
                          key: BankAppointmentsScreen.branchChipKey(b),
                          label: Text(b ?? 'All branches'),
                          selected: _branch == b,
                          selectedColor: DesignTokens.chipsSelectedFill,
                          onSelected: (_) => setState(() => _branch = b),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(bankAppointmentsForDayProvider(day));
                  await ref.read(bankAppointmentsForDayProvider(day).future);
                },
                child: switch ((loaded, appointments.error)) {
                  (final List<BankAppointment> all, _) => _list(
                    [
                      for (final a in all)
                        if (_branch == null || a.branchName == _branch) a,
                    ],
                    day,
                    today,
                  ),
                  (_, final Object error) => ListView(
                    children: [
                      ServiceLoadFailureView(
                        error: error,
                        settingUpTitle:
                            'Branch appointments are being set up',
                        fallback: 'We could not load the appointments.',
                        specific: bankErrorMessage,
                        onRetry: () => ref.invalidate(
                          bankAppointmentsForDayProvider(day),
                        ),
                      ),
                    ],
                  ),
                  _ => const SmPageLoader(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<BankAppointment> items, DateTime day, DateTime today) {
    if (items.isEmpty) {
      return ListView(
        children: [
          SmEmptyState(
            icon: Icons.event_available_rounded,
            message: daysBetween(today, day) == 0
                ? 'No branch appointments today.'
                : 'No branch appointments on ${serviceShortDateText(day)}.',
          ),
        ],
      );
    }
    final booked = items.where((a) => a.isBooked).length;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Text(
          '$booked booked · ${items.length} in total',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        for (final a in items) ...[
          BankAppointmentTile(appointment: a),
          const SizedBox(height: DesignTokens.s12),
        ],
      ],
    );
  }
}

/// One appointment in the day's list.
class BankAppointmentTile extends StatelessWidget {
  const BankAppointmentTile({required this.appointment, super.key});

  final BankAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final muted = DesignTokens.tiny.copyWith(color: DesignTokens.textMuted);
    return InkWell(
      key: BankAppointmentsScreen.tileKey(a.id),
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: () => context.push(ServiceRoutes.bankAppointmentPath(a.id)),
      child: ServiceCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: Text(
                a.startTime ?? '--:--',
                style: DesignTokens.mediumSemibold,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.contact?.name ?? 'Buyer',
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(a.topic, style: DesignTokens.smallRegular),
                  Text(
                    [
                      if (a.branchName != null) a.branchName!,
                      if (a.reference.isNotEmpty) a.reference,
                    ].join(' · '),
                    style: muted,
                  ),
                ],
              ),
            ),
            ServicePill(a.status.label, tone: bankAppointmentTone(a.status)),
          ],
        ),
      ),
    );
  }
}
