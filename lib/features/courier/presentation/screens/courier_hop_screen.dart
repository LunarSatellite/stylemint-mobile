import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_device_key_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One parcel, and the single thing to do with it next.
///
/// Deliberately one action at a time. The hop state decides whether that is
/// collect or hand over, so a courier is never choosing between buttons that
/// the aggregate would refuse — `MarkPickedUp` on an already-collected parcel
/// throws, and showing both would mean offering a guaranteed error.
class CourierHopScreen extends ConsumerWidget {
  const CourierHopScreen({
    required this.hop,
    required this.courierProfileId,
    super.key,
  });

  final DeliveryHop hop;
  final String courierProfileId;

  /// The camera, not the gallery. Proof of a handover is a photo taken at the
  /// handover; letting a courier pick an existing image makes the evidence
  /// worth nothing, and the server cannot tell the difference.
  Future<File?> _capture(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  void _toDeviceKeys(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CourierDeviceKeyScreen(courierProfileId: courierProfileId),
    ),
  );

  Future<void> _pickup(BuildContext context, WidgetRef ref) async {
    final photo = await _capture(context);
    if (photo == null || !context.mounted) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .pickup(hop: hop, proofPhoto: photo);
    if (!context.mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierHopsProvider);
      SmSnackbar.success(context, 'Collected. The parcel is with you.');
      Navigator.of(context).pop();
      return;
    }
    showCourierActionFeedback(
      context,
      result,
      onNeedsDeviceKey: () => _toDeviceKeys(context),
    );
  }

  Future<void> _handoff(BuildContext context, WidgetRef ref) async {
    // Who is receiving it decides the event kind the server signs against, so
    // it is asked explicitly rather than guessed from the hop index.
    final isFinal = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Text(
                'Who are you handing it to?',
                style: DesignTokens.h3,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('The buyer — this is the final delivery'),
              onTap: () => Navigator.of(sheetContext).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Another courier'),
              subtitle: const Text(
                'They scan or tap their phone to take it on',
              ),
              onTap: () => Navigator.of(sheetContext).pop(false),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
    if (isFinal == null || !context.mounted) return;

    if (!isFinal) {
      // A courier-to-courier handoff needs the receiving courier's profile id,
      // which this screen has no way to obtain — it comes from the NFC
      // handshake or a scan between the two devices. Rather than send a
      // handoff with a null recipient and have the chain record the parcel as
      // going nowhere, say so.
      SmSnackbar.error(
        context,
        'Courier-to-courier handoff needs the other phone. Use the NFC tap '
        'once that is set up — it is not available yet.',
      );
      return;
    }

    final photo = await _capture(context);
    if (photo == null || !context.mounted) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .handoff(hop: hop, proofPhoto: photo, isFinalDelivery: true);
    if (!context.mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierHopsProvider);
      SmSnackbar.success(context, 'Delivered. Thanks.');
      Navigator.of(context).pop();
      return;
    }
    showCourierActionFeedback(
      context,
      result,
      onNeedsDeviceKey: () => _toDeviceKeys(context),
    );
  }

  Future<void> _reportProblem(BuildContext context, WidgetRef ref) async {
    final code = await showModalBottomSheet<DeliveryExceptionCode>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Text('What happened?', style: DesignTokens.h3),
            ),
            ...DeliveryExceptionCode.values.map(
              (code) => ListTile(
                title: Text(code.label),
                subtitle: code.isCritical
                    ? const Text('The parcel will be sent back')
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(code),
              ),
            ),
          ],
        ),
      ),
    );
    if (code == null || !context.mounted) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .reportException(
          hopId: hop.id,
          code: code,
          // The code's own default: a weather delay is worth recording without
          // ending the leg, a broken seal ends it either way server-side.
          failHop: code.failsHopByDefault,
        );
    if (!context.mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierHopsProvider);
      SmSnackbar.success(context, 'Reported. Support can see it now.');
      Navigator.of(context).pop();
      return;
    }
    showCourierActionFeedback(context, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(courierActionsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Parcel'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          children: [
            Text(hop.state.label, style: DesignTokens.h2),
            const SizedBox(height: DesignTokens.s4),
            Text(
              '${hop.fromGeohash} → ${hop.toGeohash}',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s16),

            Container(
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('You earn', style: DesignTokens.smallRegular),
                  ),
                  Text(
                    formatMoney(
                      Money(
                        amount: hop.payoutAmount,
                        currency: hop.payoutCurrency,
                      ),
                    ),
                    style: DesignTokens.h3,
                  ),
                ],
              ),
            ),

            if (hop.isLate)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s12),
                child: Text(
                  'This one is past its promised time. Deliver it if you can, '
                  'or report what is holding it up.',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),

            const SizedBox(height: DesignTokens.s24),

            // One action, chosen by state. Both buttons would mean offering a
            // transition the aggregate throws on.
            if (hop.state.awaitingPickup)
              SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'Take a photo and collect',
                  disabled: busy,
                  onPressed: () => _pickup(context, ref),
                ),
              )
            else if (hop.state.awaitingHandoff)
              SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'Hand it over',
                  disabled: busy,
                  onPressed: () => _handoff(context, ref),
                ),
              )
            else
              Text(
                'Nothing to do on this one — it is ${hop.state.label.toLowerCase()}.',
                style: DesignTokens.smallRegular,
              ),

            if (!hop.state.isFinished) ...[
              const SizedBox(height: DesignTokens.s12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => _reportProblem(context, ref),
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Report a problem'),
                ),
              ),
            ],

            if (hop.failureCode != null) ...[
              const SizedBox(height: DesignTokens.s16),
              Text(
                'Reported: ${hop.failureCode!.label}'
                '${hop.failureNote == null ? '' : ' — ${hop.failureNote}'}',
                style: DesignTokens.tiny,
              ),
            ],

            const SizedBox(height: DesignTokens.s24),
            Text(
              'Your phone signs for every collection and handover. That '
              'signature is what shows the parcel was with you.',
              style: DesignTokens.tiny,
            ),
          ],
        ),
      ),
    );
  }
}
