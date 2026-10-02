import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Signing keys for this courier, and the one this phone holds.
///
/// Every handover is signed by the phone that performed it. The private key is
/// generated on the device and never leaves it, so a key registered on another
/// phone is listed here but cannot be used from this one — which is the single
/// most confusing failure in the whole courier flow if it is not spelled out,
/// because the server happily lists an active key while every pickup fails.
class CourierDeviceKeyScreen extends ConsumerWidget {
  const CourierDeviceKeyScreen({required this.courierProfileId, super.key});

  final String courierProfileId;

  Future<void> _enrol(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .enrolDeviceKey(
          courierProfileId: courierProfileId,
          deviceModel: _deviceLabel(),
        );
    if (!context.mounted) return;

    if (result is CourierActionOk) {
      ref
        ..invalidate(courierDeviceKeysProvider(courierProfileId))
        ..invalidate(courierCanSignProvider(courierProfileId));
      SmSnackbar.success(context, 'This phone can now sign handovers.');
      return;
    }
    showCourierActionFeedback(context, result);
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    CourierDeviceKeyInfo key,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Revoke this key?'),
        content: Text(
          'Handovers already signed with it stay valid — this only stops it '
          'being used again. ${key.deviceModel} will need a new key before it '
          'can collect anything.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .revokeDeviceKey(
          publicKeyId: key.publicKeyId,
          reason: 'Revoked by the courier from the app.',
        );
    if (!context.mounted) return;

    if (result is CourierActionOk) {
      ref
        ..invalidate(courierDeviceKeysProvider(courierProfileId))
        ..invalidate(courierCanSignProvider(courierProfileId));
      return;
    }
    showCourierActionFeedback(context, result);
  }

  /// A label for the key list, so a courier with two phones can tell which is
  /// which. Platform only — not a device id, which is neither available to
  /// apps nor needed here.
  static String _deviceLabel() {
    if (Platform.isAndroid) return 'Android phone';
    if (Platform.isIOS) return 'iPhone';
    return Platform.operatingSystem;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(courierActionsNotifierProvider);
    final keys = ref.watch(courierDeviceKeysProvider(courierProfileId));
    final canSign = ref.watch(courierCanSignProvider(courierProfileId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Signing'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          children: [
            Text('Why this exists', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'When you collect or hand over a parcel, your phone signs for it. '
              'That signature is what proves the parcel was with you, and it is '
              'what protects you if someone later says it was not.',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s20),

            canSign.when(
              loading: () => const Center(child: SmBrandLoader()),
              error: (_, _) => const SizedBox.shrink(),
              data: (ready) => Container(
                padding: const EdgeInsets.all(DesignTokens.s16),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  border: Border.all(
                    color: ready
                        ? DesignTokens.primaryGreen.withValues(alpha: 0.4)
                        : DesignTokens.colorError.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      ready
                          ? Icons.verified_user_rounded
                          : Icons.gpp_maybe_rounded,
                      color: ready
                          ? DesignTokens.primaryGreen
                          : DesignTokens.colorError,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Text(
                        ready
                            ? 'This phone can sign handovers.'
                            : 'This phone cannot sign yet. Any key below '
                                  'belongs to a different device — the private '
                                  'half never leaves the phone that made it.',
                        style: DesignTokens.smallRegular,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),

            SizedBox(
              width: double.infinity,
              child: SmPrimaryButton(
                label: 'Set up signing on this phone',
                disabled: busy,
                onPressed: () => _enrol(context, ref),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            Text('Registered keys', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s8),
            keys.when(
              loading: () => const Center(child: SmBrandLoader()),
              error: (_, _) => Text(
                "Couldn't load your keys.",
                style: DesignTokens.smallRegular,
              ),
              data: (list) => list.isEmpty
                  ? Text(
                      'None yet. Set one up above before your first collection.',
                      style: DesignTokens.smallRegular,
                    )
                  : Column(
                      children: list
                          .map(
                            (key) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                key.isActive
                                    ? Icons.key_rounded
                                    : Icons.key_off_rounded,
                                color: key.isActive
                                    ? DesignTokens.primaryGreen
                                    : DesignTokens.textLight,
                              ),
                              title: Text(
                                key.deviceModel.isEmpty
                                    ? 'Unnamed device'
                                    : key.deviceModel,
                                style: DesignTokens.mediumSemibold,
                              ),
                              subtitle: Text(
                                key.isActive
                                    ? 'Active'
                                    : 'Revoked${key.revocationReason == null ? '' : ' — ${key.revocationReason}'}',
                                style: DesignTokens.tiny,
                              ),
                              trailing: key.isActive
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Revoke',
                                      onPressed: busy
                                          ? null
                                          : () => _revoke(context, ref, key),
                                    )
                                  : null,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
