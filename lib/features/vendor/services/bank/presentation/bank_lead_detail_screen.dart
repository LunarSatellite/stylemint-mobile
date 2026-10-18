import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/shared/bank_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One enquiry or appointment request: what the buyer asked, the contact
/// details they consented to share (with Call / WhatsApp), the status
/// workflow and the bank's private notes.
class BankLeadDetailScreen extends ConsumerStatefulWidget {
  const BankLeadDetailScreen({required this.leadId, super.key});

  final String leadId;

  static Key statusButtonKey(BankLeadStatus s) =>
      Key('bank-lead-status-${s.name}');
  static const Key noteFieldKey = Key('bank-lead-note-field');
  static const Key addNoteKey = Key('bank-lead-add-note');
  static const Key appointmentLinkKey = Key('bank-lead-appointment-link');

  @override
  ConsumerState<BankLeadDetailScreen> createState() =>
      _BankLeadDetailScreenState();
}

class _BankLeadDetailScreenState extends ConsumerState<BankLeadDetailScreen> {
  final _noteController = TextEditingController();
  BankLeadStatus? _changing;
  bool _savingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setStatus(BankLead lead, BankLeadStatus next) async {
    String? reason;
    if (next == BankLeadStatus.closed) {
      reason = await askServiceReason(
        context,
        title: 'Close this lead?',
        message: 'Say why, for your team. The buyer does not see this.',
        confirmLabel: 'Close lead',
      );
      if (reason == null) return;
    }
    setState(() => _changing = next);
    final result = await ref
        .read(bankLeadsRepositoryProvider)
        .setLeadStatus(lead.id, next, reason: reason);
    if (!mounted) return;
    setState(() => _changing = null);
    result.fold(
      (f) => _toast(serviceFailureMessage(f, specific: bankErrorMessage)),
      (_) {
        _toast('Marked ${next.label.toLowerCase()}.');
        ref.invalidate(bankLeadProvider(lead.id));
      },
    );
  }

  Future<void> _addNote(String leadId) async {
    final text = _noteController.text.trim();
    if (text.isEmpty || _savingNote) return;
    setState(() => _savingNote = true);
    final result = await ref
        .read(bankLeadsRepositoryProvider)
        .addNote(leadId, text);
    if (!mounted) return;
    setState(() => _savingNote = false);
    result.fold(
      (f) => _toast(serviceFailureMessage(f, specific: bankErrorMessage)),
      (_) {
        _noteController.clear();
        ref.invalidate(bankLeadNotesProvider(leadId));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = ref.watch(bankLeadProvider(widget.leadId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(lead.value?.reference ?? 'Lead'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(bankLeadProvider(widget.leadId));
            ref.invalidate(bankLeadNotesProvider(widget.leadId));
            await ref.read(bankLeadProvider(widget.leadId).future);
          },
          child: switch ((lead.value, lead.error)) {
            (final BankLead l, _) => _body(l),
            (_, final Object error) => ListView(
              children: [
                ServiceLoadFailureView(
                  error: error,
                  settingUpTitle: 'Your leads inbox is being set up',
                  fallback: 'We could not load this lead.',
                  specific: bankErrorMessage,
                  onRetry: () =>
                      ref.invalidate(bankLeadProvider(widget.leadId)),
                ),
              ],
            ),
            _ => const SmPageLoader(),
          },
        ),
      ),
    );
  }

  Widget _body(BankLead l) {
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    final appointment = l.appointment;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          children: [
            Expanded(child: Text(l.title, style: DesignTokens.h3)),
            ServicePill(l.status.label, tone: bankLeadTone(l.status)),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          [
            l.kind.label,
            if (l.reference.isNotEmpty) l.reference,
            if (l.createdUtc != null) serviceInstantText(l.createdUtc!),
          ].join(' · '),
          style: muted,
        ),
        if (l.branchName != null && appointment == null)
          Text('Preferred branch: ${l.branchName}', style: muted),

        const ServiceSectionTitle('Contact'),
        BankConsentedContactCard(
          contact: l.contact,
          consent: l.consent,
          withdrawn: l.isWithdrawn,
        ),

        if (appointment != null) ...[
          const ServiceSectionTitle('Branch visit'),
          InkWell(
            key: BankLeadDetailScreen.appointmentLinkKey,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            onTap: () => context.push(
              ServiceRoutes.bankAppointmentPath(appointment.id),
            ),
            child: ServiceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            if (appointment.date != null)
                              serviceDateText(appointment.date!),
                            if (appointment.timeText.isNotEmpty)
                              appointment.timeText,
                          ].join(', '),
                          style: DesignTokens.mediumSemibold,
                        ),
                      ),
                      ServicePill(
                        appointment.status.label,
                        tone: bankAppointmentTone(appointment.status),
                      ),
                    ],
                  ),
                  if (appointment.branchName != null)
                    Text(appointment.branchName!, style: muted),
                ],
              ),
            ),
          ),
        ],

        if (l.answers.isNotEmpty || l.message != null) ...[
          const ServiceSectionTitle('What they asked'),
          ServiceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final a in l.answers)
                  ServiceRow(label: a.label, value: a.value),
                if (l.message != null) ...[
                  if (l.answers.isNotEmpty)
                    const SizedBox(height: DesignTokens.s8),
                  Text(l.message!, style: DesignTokens.smallRegular),
                ],
              ],
            ),
          ),
        ],

        const ServiceSectionTitle('Status'),
        if (l.status == BankLeadStatus.closed && l.closedReason != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Text('Closed: ${l.closedReason}', style: muted),
          ),
        if (l.status.isTerminal)
          Text(
            l.status == BankLeadStatus.converted
                ? 'Converted — this lead became a customer.'
                : 'This lead is closed.',
            style: muted,
          )
        else
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              for (final next in l.status.nextStatuses)
                OutlinedButton(
                  key: BankLeadDetailScreen.statusButtonKey(next),
                  onPressed: _changing != null
                      ? null
                      : () => _setStatus(l, next),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: next == BankLeadStatus.closed
                        ? DesignTokens.colorError
                        : DesignTokens.primaryGreen,
                  ),
                  child: _changing == next
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          next == BankLeadStatus.closed
                              ? 'Close'
                              : 'Mark ${next.label.toLowerCase()}',
                        ),
                ),
            ],
          ),

        const ServiceSectionTitle('Notes (only your team sees these)'),
        _Notes(leadId: l.id),
        const SizedBox(height: DesignTokens.s8),
        TextField(
          key: BankLeadDetailScreen.noteFieldKey,
          controller: _noteController,
          maxLength: 2000,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Add a note'),
        ),
        ServiceActionButton(
          key: BankLeadDetailScreen.addNoteKey,
          label: 'Save note',
          icon: Icons.note_add_outlined,
          outlined: true,
          busy: _savingNote,
          onPressed: () => _addNote(l.id),
        ),
        const SizedBox(height: DesignTokens.s32),
      ],
    );
  }
}

class _Notes extends ConsumerWidget {
  const _Notes({required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(bankLeadNotesProvider(leadId));
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    return switch ((notes.value, notes.error)) {
      (final List<BankLeadNote> list, _) when list.isEmpty => Text(
        'No notes yet.',
        style: muted,
      ),
      (final List<BankLeadNote> list, _) => Column(
        children: [
          for (final n in list)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: ServiceCard(
                padding: const EdgeInsets.all(DesignTokens.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.text, style: DesignTokens.smallRegular),
                    if (n.createdUtc != null)
                      Text(
                        serviceInstantText(n.createdUtc!),
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      (_, Object _) => Text('Notes could not be loaded.', style: muted),
      _ => const LinearProgressIndicator(),
    };
  }
}
