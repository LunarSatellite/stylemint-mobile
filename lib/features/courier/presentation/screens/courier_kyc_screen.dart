import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Identity checks for a delivery partner.
///
/// Takes the **last four digits** of a government ID and a reference to an
/// identity check done elsewhere — deliberately not a document or a photo. The
/// endpoint accepts nothing else, and that is the right shape: this app should
/// not be carrying images of people's ID papers when the backend never asked
/// for them.
///
/// Submitting moves the profile to KycInReview and no further. Approval is an
/// admin action on a separate endpoint, so there is no "approve" path here and
/// nothing a courier can do to hurry it.
class CourierKycScreen extends ConsumerStatefulWidget {
  const CourierKycScreen({required this.courierProfileId, super.key});

  final String courierProfileId;

  @override
  ConsumerState<CourierKycScreen> createState() => _CourierKycScreenState();
}

class _CourierKycScreenState extends ConsumerState<CourierKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _last4 = TextEditingController();
  final _reference = TextEditingController();

  @override
  void dispose() {
    _last4.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .submitKyc(
          courierProfileId: widget.courierProfileId,
          governmentIdLast4: _last4.text.trim(),
          selfieMatchRef: _reference.text.trim(),
        );
    if (!mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierProfileProvider(ref.read(courierAccountIdProvider)));
      return;
    }
    showCourierActionFeedback(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courierActionsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Identity checks'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirm who you are', style: DesignTokens.h2),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'You will be carrying other people’s parcels, so we verify '
                  'every delivery partner. We only keep the last four digits '
                  'of your ID — not a copy of the document.',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(height: DesignTokens.s24),

                TextFormField(
                  controller: _last4,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Last 4 digits of your government ID',
                    counterText: '',
                  ),
                  // Mirrors the server rule (exactly 4 digits) so a courier is
                  // told here rather than by a 422 after a round trip.
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length != 4) return 'Enter exactly 4 digits.';
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.s16),

                TextFormField(
                  controller: _reference,
                  enabled: !busy,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Verification reference',
                    helperText:
                        'The reference from your identity check. Support can '
                        'give you this if you do not have it.',
                  ),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true)
                      ? 'Enter your verification reference.'
                      : null,
                ),
                const SizedBox(height: DesignTokens.s24),

                SizedBox(
                  width: double.infinity,
                  child: SmPrimaryButton(
                    label: 'Submit for review',
                    disabled: busy,
                    onPressed: _submit,
                  ),
                ),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  'A reviewer checks this by hand, so it is not instant. You '
                  'do not need to come back — this screen updates itself.',
                  style: DesignTokens.tiny,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
