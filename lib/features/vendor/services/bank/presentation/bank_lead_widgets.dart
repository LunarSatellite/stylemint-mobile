import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_contact.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

ServicePillTone bankLeadTone(BankLeadStatus s) => switch (s) {
  BankLeadStatus.newLead => ServicePillTone.info,
  BankLeadStatus.contacted => ServicePillTone.warning,
  BankLeadStatus.qualified => ServicePillTone.warning,
  BankLeadStatus.converted => ServicePillTone.success,
  BankLeadStatus.closed => ServicePillTone.neutral,
};

ServicePillTone bankAppointmentTone(BankAppointmentStatus s) => switch (s) {
  BankAppointmentStatus.booked => ServicePillTone.info,
  BankAppointmentStatus.completed => ServicePillTone.success,
  BankAppointmentStatus.cancelled => ServicePillTone.neutral,
  BankAppointmentStatus.noShow => ServicePillTone.error,
};

/// The consented contact card: who to call, how they prefer it, and the
/// Call / WhatsApp buttons — only when this lead carries a consented number
/// that was not withdrawn.
class BankConsentedContactCard extends ConsumerWidget {
  const BankConsentedContactCard({
    required this.contact,
    required this.withdrawn,
    this.consent,
    super.key,
  });

  static const Key callKey = Key('bank-contact-call');
  static const Key whatsAppKey = Key('bank-contact-whatsapp');
  static const Key withdrawnKey = Key('bank-contact-withdrawn');

  final BankLeadContact? contact;
  final BankLeadConsent? consent;
  final bool withdrawn;

  Future<void> _open(BuildContext context, WidgetRef ref, Uri uri) async {
    final ok = await ref.read(serviceContactLauncherProvider).open(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that on this phone.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );
    final c = contact;
    if (withdrawn || c == null) {
      return ServiceCard(
        key: withdrawnKey,
        child: Text(
          withdrawn
              ? 'The buyer withdrew this request, so their contact details '
                    'were removed.'
              : 'No contact details were shared on this request.',
          style: muted,
        ),
      );
    }
    final phone = c.phone;
    final callable = isCallablePhone(phone);
    return ServiceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.name, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s4),
          if (phone != null) SelectableText(phone, style: DesignTokens.smallRegular),
          if (c.email != null)
            SelectableText(c.email!, style: DesignTokens.smallRegular),
          if (c.preferredMethod != null)
            Text('Prefers: ${c.preferredMethod!.label}', style: muted),
          if (callable) ...[
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Expanded(
                  child: ServiceActionButton(
                    key: callKey,
                    label: 'Call',
                    icon: Icons.call_rounded,
                    onPressed: () => _open(context, ref, phoneCallUri(phone!)),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: ServiceActionButton(
                    key: whatsAppKey,
                    label: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    outlined: true,
                    onPressed: () => _open(context, ref, whatsAppUri(phone!)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Shared by the buyer for this request only, with their consent'
            '${consent?.acceptedUtc == null ? '' : ' on ${serviceInstantText(consent!.acceptedUtc!)}'}.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          if (consent?.text != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              '"${consent!.text}"',
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
