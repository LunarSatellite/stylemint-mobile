import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';

/// Enrols this phone's handover-signing key, once, without asking.
///
/// The courier used to be shown a blocker — "This phone cannot sign handovers
/// yet" — with a Set up button. That is not a decision a rider should be
/// handed: it is setup, it has one correct answer, and until it was done they
/// could not collect a parcel.
///
/// The key itself cannot be removed. Every chain-of-custody entry, pickup
/// included, is rejected server-side without a valid signature from a
/// registered key — see `ChainOfCustodyService.AppendAsync`, which looks the
/// signer up by id, checks the key belongs to a party of the entry, and
/// verifies the signature against a string it rebuilds from its own columns.
/// A courier with no key cannot work. So the friction goes and the key stays.
///
/// Renders nothing. It is a widget rather than a call in `initState` so it
/// can sit in the dashboard's tree and get a `ref` without the dashboard —
/// which is a `ConsumerWidget` — having to become stateful for it.
class CourierSigningEnrolment extends ConsumerStatefulWidget {
  const CourierSigningEnrolment({required this.courierProfileId, super.key});

  final String courierProfileId;

  @override
  ConsumerState<CourierSigningEnrolment> createState() =>
      _CourierSigningEnrolmentState();
}

class _CourierSigningEnrolmentState
    extends ConsumerState<CourierSigningEnrolment> {
  /// Guards against a second attempt while the first is in flight. Enrolment
  /// generates a key pair and registers it, so running twice would leave an
  /// orphan private key in secure storage.
  static final Set<String> _inFlight = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_ensure()));
  }

  Future<void> _ensure() async {
    final id = widget.courierProfileId;
    if (id.isEmpty || _inFlight.contains(id)) return;

    // Already able to sign — nothing to do, and asking the server again on
    // every dashboard open would be pointless traffic.
    final canSign = await ref.read(courierCanSignProvider(id).future);
    if (canSign || !mounted) return;

    _inFlight.add(id);
    try {
      final result = await ref
          .read(courierActionsNotifierProvider.notifier)
          .enrolDeviceKey(courierProfileId: id, deviceModel: _deviceLabel());

      // Silent either way. Success needs no announcement — the rider never
      // knew it was pending. Failure is not surfaced here because there is
      // nothing for them to do about it: the pickup screen already reports
      // CourierActionNeedsDeviceKey at the point it actually matters, and a
      // toast on the dashboard about cryptography would only alarm.
      if (result is CourierActionOk && mounted) {
        ref.invalidate(courierCanSignProvider(id));
      }
    } finally {
      _inFlight.remove(id);
    }
  }

  static String _deviceLabel() {
    if (Platform.isAndroid) return 'Android phone';
    if (Platform.isIOS) return 'iPhone';
    return 'This device';
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
