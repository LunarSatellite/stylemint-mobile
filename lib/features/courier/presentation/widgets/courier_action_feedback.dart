import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';

/// Turns a [CourierActionResult] into something the courier can act on.
///
/// Centralised because the two non-network failures need more than a message.
/// A courier standing at a door with a parcel they cannot sign for is not
/// helped by "something went wrong" — they need to know which of the two
/// things is missing and where to fix it, and they need that identically on
/// every screen that can hit it.
void showCourierActionFeedback(
  BuildContext context,
  CourierActionResult result, {
  VoidCallback? onNeedsDeviceKey,
}) {
  switch (result) {
    case CourierActionOk():
      return;

    case CourierActionNeedsDeviceKey():
      // Not a snackbar: this is unrecoverable on this screen and the fix is
      // somewhere else, so it gets a dialog with the way out.
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('This phone cannot sign yet'),
          content: const Text(
            'Handovers are signed by your phone, and this one has no signing '
            'key set up — or the key it has is registered to a different '
            'device. Set one up and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Not now'),
            ),
            if (onNeedsDeviceKey != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onNeedsDeviceKey();
                },
                child: const Text('Set up signing'),
              ),
          ],
        ),
      );

    case CourierActionNeedsLocation(:final permanentlyDenied):
      if (!permanentlyDenied) {
        SmSnackbar.error(
          context,
          'We could not get your location. Every handover records where it '
          'happened, so try again once you have a signal.',
        );
        return;
      }
      // The OS will not ask again, so a retry button would do nothing
      // visible. Send them to settings instead — that is the only path.
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Location is turned off'),
          content: const Text(
            'Every handover records where it happened, so location is '
            'required to collect or deliver a parcel. You have blocked it for '
            'StyleMint, which we cannot ask about again from here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Geolocator.openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        ),
      );

    case CourierActionFailed(:final failure):
      SmSnackbar.error(
        context,
        failure.maybeWhen(
          // The server's own message is better than anything generic here:
          // a refused pickup usually says WHY (wrong state, not your hop,
          // signature rejected) and hiding that makes it unfixable.
          server: (message) => message,
          noInternetConnection: () =>
              'No connection. Your parcel is still yours — try again when you '
              'have signal.',
          orElse: () => 'That did not go through. Please try again.',
        ),
      );
  }
}
