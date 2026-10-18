import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/banks_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// The "sent" banner both request pages show right after the form.
class _SentBanner extends StatelessWidget {
  const _SentBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
    child: ServiceCard(
      key: const Key('bank-request-sent'),
      borderColor: DesignTokens.primaryGreen,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: DesignTokens.primaryGreen),
          const SizedBox(width: DesignTokens.s12),
          Expanded(child: Text(text, style: DesignTokens.smallRegular)),
        ],
      ),
    ),
  );
}

/// One enquiry: status, what was asked, the details the bank received and
/// the consent the buyer gave; Withdraw takes the details back.
class EnquiryDetailScreen extends ConsumerStatefulWidget {
  const EnquiryDetailScreen({
    required this.leadId,
    this.justSent = false,
    super.key,
  });

  final String leadId;
  final bool justSent;

  static const Key withdrawKey = Key('enquiry-withdraw');
  static const Key confirmWithdrawKey = Key('enquiry-withdraw-confirm');

  @override
  ConsumerState<EnquiryDetailScreen> createState() =>
      _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends ConsumerState<EnquiryDetailScreen> {
  bool _busy = false;
  String? _error;
  final String _key = const Uuid().v4();

  Future<void> _withdraw(BankLead lead) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Withdraw this enquiry?'),
        content: Text(
          '${lead.bankName} will no longer see your name, phone number or '
          'email for this enquiry.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: EnquiryDetailScreen.confirmWithdrawKey,
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(banksRepositoryProvider)
        .withdrawEnquiry(leadId: lead.id, idempotencyKey: _key);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _busy = false;
        _error = serviceFailureMessage(f, what: 'this enquiry');
      }),
      (_) {
        setState(() => _busy = false);
        ref
          ..invalidate(myEnquiryProvider(lead.id))
          ..invalidate(myEnquiriesProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = ref.watch(myEnquiryProvider(widget.leadId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(lead.asData?.value.reference ?? 'Enquiry'),
      ),
      body: SafeArea(
        child: lead.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this enquiry',
                onRetry: () => ref.invalidate(myEnquiryProvider(widget.leadId)),
              ),
            ],
          ),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(BankLead l) {
    final contact = l.contact;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        if (widget.justSent)
          _SentBanner(
            text: 'Enquiry sent to ${l.bankName}. They will contact you the '
                'way you chose.',
          ),
        Row(
          children: [
            Expanded(child: Text(l.title, style: DesignTokens.h3)),
            LeadStatusChip(lead: l),
          ],
        ),
        Text(
          [l.bankName, l.reference].where((s) => s.isNotEmpty).join(' · '),
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (l.createdAt != null)
          Text(
            'Sent ${serviceInstant(l.createdAt!)}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        if (l.answers.isNotEmpty || l.message != null) ...[
          const ServiceSectionTitle('What you asked'),
          ServiceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in l.answers)
                  ServiceRow(label: a.label, value: a.value),
                if (l.message != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(l.message!, style: DesignTokens.smallRegular),
                ],
              ],
            ),
          ),
        ],
        const ServiceSectionTitle('What the bank received'),
        if (l.isWithdrawn)
          Text(
            'You withdrew this enquiry on ${serviceInstant(l.withdrawnAt!)}. '
            'The bank no longer has your contact details for it.',
            key: const Key('enquiry-withdrawn'),
            style: DesignTokens.smallRegular,
          )
        else if (contact != null)
          ServiceCard(
            child: Column(
              children: [
                ServiceRow(label: 'Name', value: contact.name),
                ServiceRow(label: 'Phone', value: contact.phone),
                if (contact.email != null)
                  ServiceRow(label: 'Email', value: contact.email!),
                ServiceRow(
                  label: 'Contact by',
                  value: contact.preferredMethod.label,
                ),
              ],
            ),
          ),
        if (l.consentText != null && !l.isWithdrawn) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'You agreed${l.consentAcceptedAt == null ? '' : ' on ${serviceInstant(l.consentAcceptedAt!)}'}: '
            '"${l.consentText}"',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
        if (l.status == LeadStatus.closed && l.closedReason != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Closed: ${l.closedReason}',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(
            _error!,
            key: const Key('enquiry-error'),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        if (l.canWithdraw) ...[
          const SizedBox(height: DesignTokens.s20),
          OutlinedButton(
            key: EnquiryDetailScreen.withdrawKey,
            onPressed: _busy ? null : () => unawaited(_withdraw(l)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
            ),
            child: const Text('Withdraw enquiry'),
          ),
        ],
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}

/// One branch appointment: when, where, status; Cancel until it starts.
class AppointmentDetailScreen extends ConsumerStatefulWidget {
  const AppointmentDetailScreen({
    required this.appointmentId,
    this.justSent = false,
    super.key,
  });

  final String appointmentId;
  final bool justSent;

  static const Key cancelKey = Key('appointment-cancel');
  static const Key confirmCancelKey = Key('appointment-cancel-confirm');

  @override
  ConsumerState<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState
    extends ConsumerState<AppointmentDetailScreen> {
  bool _busy = false;
  String? _error;
  final String _key = const Uuid().v4();

  Future<void> _cancel(BankAppointment a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Cancel this appointment?'),
        content: Text('${a.branchName}, ${appointmentWhen(a)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: AppointmentDetailScreen.confirmCancelKey,
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(banksRepositoryProvider)
        .cancelAppointment(appointmentId: a.id, idempotencyKey: _key);
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _busy = false;
        _error = serviceFailureMessage(f, what: 'this appointment');
      }),
      (_) {
        setState(() => _busy = false);
        ref
          ..invalidate(myAppointmentProvider(a.id))
          ..invalidate(myAppointmentsProvider);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appt = ref.watch(myAppointmentProvider(widget.appointmentId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(appt.asData?.value.reference ?? 'Appointment'),
      ),
      body: SafeArea(
        child: appt.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceFailureView(
                error: error,
                what: 'this appointment',
                onRetry: () => ref.invalidate(
                  myAppointmentProvider(widget.appointmentId),
                ),
              ),
            ],
          ),
          data: _body,
        ),
      ),
    );
  }

  Widget _body(BankAppointment a) {
    final now = ref.watch(servicesClockProvider)().toUtc();
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        if (widget.justSent)
          _SentBanner(
            text: 'Appointment booked at ${a.branchName}. We will remind you '
                'the day before.',
          ),
        Row(
          children: [
            Expanded(child: Text(a.bankName, style: DesignTokens.h3)),
            AppointmentStatusChip(status: a.status),
          ],
        ),
        Text(
          a.reference,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const ServiceSectionTitle('When and where'),
        ServiceCard(
          child: Column(
            children: [
              ServiceRow(
                label: 'When',
                value: appointmentWhen(a),
                valueKey: const Key('appointment-when'),
              ),
              ServiceRow(label: 'Branch', value: a.branchName),
              if (a.branchAddress != null)
                ServiceRow(label: 'Address', value: a.branchAddress!),
              if (a.productName != null)
                ServiceRow(label: 'About', value: a.productName!),
              if (a.purpose != null)
                ServiceRow(label: 'Purpose', value: a.purpose!),
            ],
          ),
        ),
        if (a.status == AppointmentStatus.cancelled) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Cancelled by ${a.cancelledByBank ? 'the bank' : 'you'}'
            '${a.cancelReason == null ? '' : ': ${a.cancelReason}'}',
            key: const Key('appointment-cancelled'),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
        if (a.contact != null) ...[
          const ServiceSectionTitle('What the bank received'),
          ServiceCard(
            child: Column(
              children: [
                ServiceRow(label: 'Name', value: a.contact!.name),
                ServiceRow(label: 'Phone', value: a.contact!.phone),
                if (a.contact!.email != null)
                  ServiceRow(label: 'Email', value: a.contact!.email!),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(
            _error!,
            key: const Key('appointment-error'),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
        ],
        if (a.canCancel(now)) ...[
          const SizedBox(height: DesignTokens.s20),
          OutlinedButton(
            key: AppointmentDetailScreen.cancelKey,
            onPressed: _busy ? null : () => unawaited(_cancel(a)),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
              side: const BorderSide(color: DesignTokens.colorError),
              minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
            ),
            child: const Text('Cancel appointment'),
          ),
        ],
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}
