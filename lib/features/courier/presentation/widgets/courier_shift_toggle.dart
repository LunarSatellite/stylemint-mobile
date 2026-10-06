import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Go online / go offline — the switch that decides whether parcels arrive.
///
/// This is the availability gate now. It used to be the `Active` lifecycle
/// state, which nothing ever set: an approved courier sat with a working
/// dashboard and was never a candidate for any parcel, because advancing out
/// of Onboarded needed an operator pressing a button labelled for something
/// else. A rider saying "I am on shift" is both the honest signal and one
/// they control.
///
/// Leads the dashboard above the map: whether work can arrive at all matters
/// more than where the current job is.
class CourierShiftToggle extends ConsumerStatefulWidget {
  const CourierShiftToggle({required this.profile, super.key});

  final CourierProfile profile;

  @override
  ConsumerState<CourierShiftToggle> createState() => _CourierShiftToggleState();
}

class _CourierShiftToggleState extends ConsumerState<CourierShiftToggle> {
  /// What the switch shows while the call is in flight.
  ///
  /// Held locally so the switch moves under the rider's thumb rather than
  /// waiting a round trip to look like it did anything. Reconciled from the
  /// profile on success and reverted on failure, so it never lies for long.
  bool? _pending;

  Future<void> _set(bool online) async {
    setState(() => _pending = online);

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .setShift(courierProfileId: widget.profile.id, online: online);

    if (!mounted) return;

    if (result is CourierActionOk) {
      // Re-read rather than trust the optimistic value: the server decides,
      // and a courier whose review has lapsed may have been refused.
      ref.invalidate(courierProfileProvider(widget.profile.accountId));
      setState(() => _pending = null);
      return;
    }

    setState(() => _pending = null);
    showCourierActionFeedback(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(courierActionsNotifierProvider);
    final online = _pending ?? widget.profile.isOnline;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: online
              ? DesignTokens.primaryGreen
              : DesignTokens.textMuted.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s8,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    online ? "You're online" : "You're offline",
                    style: DesignTokens.mediumSemibold,
                  ),
                  Text(
                    online
                        ? 'Parcels near you can be offered.'
                        : 'Go online to start receiving parcels.',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: online,
              // Disabled while any courier action is in flight, so a second
              // tap cannot race the first.
              onChanged: busy ? null : _set,
            ),
          ],
        ),
      ),
    );
  }
}
