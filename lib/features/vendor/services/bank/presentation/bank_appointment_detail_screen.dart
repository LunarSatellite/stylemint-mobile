import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/shared/bank_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One branch appointment: when, where, what about, the consented contact,
/// and the bank's actions — completed / no-show once it has started, cancel
/// (with a reason the buyer is told) while it is booked.
class BankAppointmentDetailScreen extends ConsumerStatefulWidget {
  const BankAppointmentDetailScreen({required this.appointmentId, super.key});

  final String appointmentId;

  static const Key completeKey = Key('bank-appointment-complete');
  static const Key noShowKey = Key('bank-appointment-no-show');
  static const Key cancelKey = Key('bank-appointment-cancel');
  static const Key leadLinkKey = Key('bank-appointment-lead-link');

  @override
  ConsumerState<BankAppointmentDetailScreen> createState() =>
      _BankAppointmentDetailScreenState();
}

class _BankAppointmentDetailScreenState
    extends ConsumerState<BankAppointmentDetailScreen> {
  bool _busy = false;

  /// The appointment as the last action returned it, ahead of a reload.
  BankAppointment? _updated;

  Future<void> _run(
    Future<Either<ServiceFailure, BankAppointment>> Function(
      BankLeadsRepository repo,
    )
    action,
    String done,
  ) async {
    setState(() => _busy = true);
    final result = await action(ref.read(bankLeadsRepositoryProvider));
    if (!mounted) return;
    setState(() => _busy = false);
    final message = result.fold(
      (f) => serviceFailureMessage(f, specific: bankErrorMessage),
      (a) {
        setState(() => _updated = a);
        final day = a.date;
        if (day != null) ref.invalidate(bankAppointmentsForDayProvider(day));
        return done;
      },
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancel(BankAppointment a) async {
    final reason = await askServiceReason(
      context,
      title: 'Cancel this appointment?',
      message:
          'The buyer is told the bank cancelled, with your reason. The '
          'slot opens up again.',
      confirmLabel: 'Cancel appointment',
    );
    if (reason == null) return;
    await _run(
      (repo) => repo.cancelAppointment(a.id, reason),
      'Appointment cancelled.',
    );
  }

  Future<void> _noShow(BankAppointment a) async {
    final ok = await confirmServiceAction(
      context,
      title: 'Mark as no-show?',
      message: 'The buyer did not come to the branch.',
      confirmLabel: 'Mark no-show',
    );
    if (!ok) return;
    await _run(
      (repo) => repo.markAppointmentNoShow(a.id),
      'Marked as no-show.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = ref.watch(
      bankAppointmentProvider(widget.appointmentId),
    );
    final value = _updated ?? appointment.value;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(value?.reference ?? 'Appointment'),
      ),
      body: SafeArea(
        child: switch ((value, appointment.error)) {
          (final BankAppointment a, _) => _body(a),
          (_, final Object error) => ListView(
            children: [
              ServiceLoadFailureView(
                error: error,
                settingUpTitle: 'Branch appointments are being set up',
                fallback: 'We could not load this appointment.',
                specific: bankErrorMessage,
                onRetry: () => ref.invalidate(
                  bankAppointmentProvider(widget.appointmentId),
                ),
              ),
            ],
          ),
          _ => const SmPageLoader(),
        },
      ),
    );
  }

  Widget _body(BankAppointment a) {
    final now = ref.watch(serviceNowProvider);
    final today = ref.watch(serviceTodayProvider);
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    final started = a.hasStarted(now);
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            Expanded(child: Text(a.topic, style: DesignTokens.h3)),
            ServicePill(a.status.label, tone: bankAppointmentTone(a.status)),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (a.date != null)
                ServiceRow(
                  label: 'Date',
                  value:
                      '${serviceRelativeDay(a.date!, today)} · ${serviceDateText(a.date!)}',
                ),
              if (a.timeText.isNotEmpty)
                ServiceRow(label: 'Time', value: a.timeText, emphasised: true),
              if (a.branchName != null)
                ServiceRow(label: 'Branch', value: a.branchName!),
              if (a.branchAddress != null)
                ServiceRow(label: 'Address', value: a.branchAddress!),
              if (a.purpose != null)
                ServiceRow(label: 'Purpose', value: a.purpose!),
              if (a.reference.isNotEmpty)
                ServiceRow(label: 'Reference', value: a.reference),
            ],
          ),
        ),
        if (a.status == BankAppointmentStatus.cancelled) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Cancelled by ${a.cancelledByBank ? 'the bank' : 'the buyer'}'
            '${a.cancelReason == null ? '' : ': ${a.cancelReason}'}',
            style: muted,
          ),
        ],
        const ServiceSectionTitle('Contact'),
        BankConsentedContactCard(
          contact: a.contact,
          withdrawn: a.contact == null,
        ),
        if (a.leadId != null) ...[
          const SizedBox(height: DesignTokens.s8),
          TextButton.icon(
            key: BankAppointmentDetailScreen.leadLinkKey,
            onPressed: () =>
                context.push(ServiceRoutes.bankLeadPath(a.leadId!)),
            icon: const Icon(Icons.sticky_note_2_outlined),
            label: const Text('Lead status and notes'),
          ),
        ],
        if (a.isBooked) ...[
          const ServiceSectionTitle('Actions'),
          if (started) ...[
            ServiceActionButton(
              key: BankAppointmentDetailScreen.completeKey,
              label: 'Mark completed',
              icon: Icons.check_circle_outline,
              busy: _busy,
              onPressed: () => _run(
                (repo) => repo.completeAppointment(a.id),
                'Marked as completed.',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            ServiceActionButton(
              key: BankAppointmentDetailScreen.noShowKey,
              label: 'Mark no-show',
              icon: Icons.person_off_outlined,
              outlined: true,
              onPressed: _busy ? null : () => _noShow(a),
            ),
          ] else
            Text(
              'You can mark it completed or a no-show once it has started.',
              style: muted,
            ),
          const SizedBox(height: DesignTokens.s12),
          ServiceActionButton(
            key: BankAppointmentDetailScreen.cancelKey,
            label: 'Cancel appointment',
            icon: Icons.event_busy_outlined,
            outlined: true,
            destructive: true,
            onPressed: _busy ? null : () => _cancel(a),
          ),
        ],
        const SizedBox(height: DesignTokens.s32),
      ],
    );
  }
}
