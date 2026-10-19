import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Signed in already, or signed in through the app's sheet. The sheet is
/// only shown when [servicesSignedInProvider] says the buyer is a guest.
Future<bool> servicesEnsureAuth(BuildContext context, WidgetRef ref) async {
  if (ref.read(servicesSignedInProvider)) return true;
  return ensureAuth(context, ref, reason: AuthReason.general);
}

/// 7–15 digits once spaces and dashes are removed, with an optional
/// leading `+` (banks contract v1 §3).
bool isValidContactPhone(String raw) {
  final s = raw.replaceAll(RegExp(r'[\s\-]'), '');
  return RegExp(r'^\+?\d{7,15}$').hasMatch(s);
}

bool isValidContactEmail(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return true;
  return s.length <= 254 && RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
}

/// The buyer's contact details for one enquiry or appointment. What they
/// submit here is exactly what the bank sees — nothing else about them.
class BankContactFields extends StatelessWidget {
  const BankContactFields({
    required this.name,
    required this.phone,
    required this.email,
    required this.method,
    required this.onMethodChanged,
    super.key,
  });

  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController email;
  final PreferredContactMethod method;
  final ValueChanged<PreferredContactMethod> onMethodChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        key: const Key('bank-contact-name'),
        controller: name,
        textCapitalization: TextCapitalization.words,
        style: DesignTokens.smallRegular,
        decoration: serviceInputDecoration('Your name'),
        validator: (v) {
          final s = v?.trim() ?? '';
          if (s.length < 2) return 'Enter your name';
          if (s.length > 100) return 'Keep it under 100 characters';
          return null;
        },
      ),
      const SizedBox(height: DesignTokens.s12),
      TextFormField(
        key: const Key('bank-contact-phone'),
        controller: phone,
        keyboardType: TextInputType.phone,
        style: DesignTokens.smallRegular,
        decoration: serviceInputDecoration(
          'Phone number',
          hint: '+977 98XXXXXXXX',
        ),
        validator: (v) =>
            isValidContactPhone(v ?? '') ? null : 'Enter a valid phone number',
      ),
      const SizedBox(height: DesignTokens.s12),
      TextFormField(
        key: const Key('bank-contact-email'),
        controller: email,
        keyboardType: TextInputType.emailAddress,
        style: DesignTokens.smallRegular,
        decoration: serviceInputDecoration('Email (optional)'),
        validator: (v) =>
            isValidContactEmail(v ?? '') ? null : 'Enter a valid email',
      ),
      const SizedBox(height: DesignTokens.s12),
      Text(
        'How should the bank contact you?',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
      const SizedBox(height: DesignTokens.s4),
      Wrap(
        spacing: DesignTokens.s8,
        children: [
          for (final m in PreferredContactMethod.values)
            ChoiceChip(
              key: Key('bank-contact-method-${m.name}'),
              label: Text(m.label),
              selected: method == m,
              onSelected: (_) => onMethodChanged(m),
            ),
        ],
      ),
    ],
  );
}

/// The consent box: the server's wording, verbatim, beside a checkbox that
/// starts unticked. Nothing is sent to [bankName] until it is ticked.
class BankConsentBox extends StatelessWidget {
  const BankConsentBox({
    required this.bankName,
    required this.consent,
    required this.accepted,
    required this.onChanged,
    this.showError = false,
    super.key,
  });

  static const Key checkboxKey = Key('bank-consent-checkbox');
  static const Key errorKey = Key('bank-consent-error');

  final String bankName;
  final BankConsent consent;
  final bool accepted;
  final ValueChanged<bool> onChanged;

  /// The buyer tried to send without ticking it.
  final bool showError;

  @override
  Widget build(BuildContext context) => ServiceCard(
    borderColor: showError && !accepted
        ? DesignTokens.colorError
        : DesignTokens.borderDefault,
    padding: const EdgeInsets.all(DesignTokens.s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share my details with $bankName',
          key: const Key('bank-consent-title'),
          style: DesignTokens.mediumSemibold,
        ),
        const SizedBox(height: DesignTokens.s8),
        InkWell(
          onTap: () => onChanged(!accepted),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: checkboxKey,
                value: accepted,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: DesignTokens.primaryGreen,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    consent.text,
                    key: const Key('bank-consent-text'),
                    style: DesignTokens.smallRegular,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showError && !accepted)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s4),
            child: Text(
              'Tick the box so $bankName may contact you. Without it nothing '
              'is sent.',
              key: errorKey,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
            ),
          ),
      ],
    ),
  );
}

Color leadStatusColor(LeadStatus s) => switch (s) {
  LeadStatus.newLead => DesignTokens.colorInfo,
  LeadStatus.contacted => DesignTokens.primaryGreen,
  LeadStatus.qualified => DesignTokens.colorWarning,
  LeadStatus.converted => DesignTokens.colorSuccess,
  LeadStatus.closed => DesignTokens.textMuted,
};

Color appointmentStatusColor(AppointmentStatus s) => switch (s) {
  AppointmentStatus.booked => DesignTokens.primaryGreen,
  AppointmentStatus.cancelled => DesignTokens.textMuted,
  AppointmentStatus.completed => DesignTokens.colorSuccess,
  AppointmentStatus.noShow => DesignTokens.colorError,
};

/// "Withdrawn" beats the bank's status: the buyer took it back.
class LeadStatusChip extends StatelessWidget {
  const LeadStatusChip({required this.lead, super.key});

  final BankLead lead;

  @override
  Widget build(BuildContext context) => lead.isWithdrawn
      ? const ServiceChip(label: 'Withdrawn', color: DesignTokens.textMuted)
      : ServiceChip(
          label: lead.status.label,
          color: leadStatusColor(lead.status),
        );
}

class AppointmentStatusChip extends StatelessWidget {
  const AppointmentStatusChip({required this.status, super.key});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) => ServiceChip(
    label: status.label,
    color: appointmentStatusColor(status),
  );
}

/// "Tue, 21 Oct · 10:00–10:30".
String appointmentWhen(BankAppointment a) {
  final range = a.endTime.isEmpty ? a.startTime : '${a.startTime}–${a.endTime}';
  return '${serviceShortDate(a.date)} · $range';
}
