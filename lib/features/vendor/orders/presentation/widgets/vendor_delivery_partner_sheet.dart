import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/delivery_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/delivery_partner_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_rider_details_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the vendor decided on the delivery-partner sheet. Null (sheet closed)
/// means nothing changes — a request stays open and can be watched again.
sealed class VendorPartnerSheetOutcome {
  const VendorPartnerSheetOutcome();
}

/// Hand it to a third-party courier instead: the screen opens the existing
/// carrier/tracking form.
final class VendorPartnerUseOwnCourier extends VendorPartnerSheetOutcome {
  const VendorPartnerUseOwnCourier();
}

/// The chosen rider has collected it; the screen records the handover.
final class VendorPartnerHandedOver extends VendorPartnerSheetOutcome {
  const VendorPartnerHandedOver(this.rider);

  final AssignedRider rider;
}

Future<VendorPartnerSheetOutcome?> showVendorDeliveryPartnerSheet(
  BuildContext context, {
  required String subOrderId,
}) => showModalBottomSheet<VendorPartnerSheetOutcome>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: DesignTokens.bgAppBody,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(DesignTokens.radiusLarge),
    ),
  ),
  builder: (_) => VendorDeliveryPartnerSheet(subOrderId: subOrderId),
);

/// Find a StyleMint rider for this parcel, watch who is interested, choose.
///
/// Replaces the old picker, which listed routing's candidates and offered the
/// parcel to one of them directly. That list was computed once, when the sheet
/// opened, and any failure behind it read as "no delivery partner can take
/// this" — which was most of what vendors saw. Now riders nearby are notified
/// and say they are interested; the vendor sees them arrive and picks one,
/// and nothing is assigned until they do.
///
/// Live while open: the notifier polls every few seconds, a
/// `delivery.interest` push refreshes it at once, and both stop when the
/// sheet closes.
class VendorDeliveryPartnerSheet extends ConsumerStatefulWidget {
  const VendorDeliveryPartnerSheet({required this.subOrderId, super.key});

  final String subOrderId;

  static const Key findKey = ValueKey<String>('vendor-partner-find');
  static const Key retryKey = ValueKey<String>('vendor-partner-retry');
  static const Key askAgainKey = ValueKey<String>('vendor-partner-ask-again');
  static const Key ownCourierKey = ValueKey<String>(
    'vendor-partner-own-courier',
  );
  static const Key confirmChooseKey = ValueKey<String>(
    'vendor-partner-confirm-choose',
  );
  static const Key handedOverKey = ValueKey<String>(
    'vendor-partner-handed-over',
  );
  static Key chooseKey(String offerId) =>
      ValueKey<String>('vendor-partner-choose-$offerId');
  static Key detailsKey(String offerId) =>
      ValueKey<String>('vendor-partner-details-$offerId');

  @override
  ConsumerState<VendorDeliveryPartnerSheet> createState() =>
      _VendorDeliveryPartnerSheetState();
}

class _VendorDeliveryPartnerSheetState
    extends ConsumerState<VendorDeliveryPartnerSheet> {
  StreamSubscription<DeliveryPushEvent>? _pushSubscription;

  /// Redraws the countdown and the "interested 2m ago" labels. One timer for
  /// the sheet rather than one per card.
  Timer? _ticker;

  DeliveryPartnerNotifier get _notifier =>
      ref.read(deliveryPartnerNotifierProvider(widget.subOrderId).notifier);

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pushSubscription = ref
        .read(deliveryPushBusProvider)
        .events
        .listen(_onPush);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_pushSubscription?.cancel());
    super.dispose();
  }

  void _onPush(DeliveryPushEvent event) {
    if (!mounted || event.type != DeliveryPushType.interest) return;
    final target = event.subOrderId;
    // A push naming another order is someone else's sheet; one with no id
    // is cheap enough to refresh on anyway.
    if (target != null && target != widget.subOrderId) return;
    unawaited(_notifier.refresh());
  }

  Future<void> _choose(InterestedRider rider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        title: Text('Choose ${rider.displayName}?'),
        content: Text(
          '${_firstName(rider.displayName)} is told to collect the parcel now, '
          'and the other riders are told it was taken. This cannot be undone '
          'from here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            key: VendorDeliveryPartnerSheet.confirmChooseKey,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Choose ${_firstName(rider.displayName)}'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final failure = await _notifier.choose(rider.offerId);
    if (failure == null || !mounted) return;
    SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
  }

  /// The rider's details; "Choose this rider" there comes back here and runs
  /// the same confirm-and-select as the row's own button.
  Future<void> _openDetails(InterestedRider rider) async {
    final chosen = await showVendorRiderDetailsSheet(
      context,
      subOrderId: widget.subOrderId,
      rider: rider,
    );
    if (chosen == null || !mounted) return;
    await _choose(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryPartnerNotifierProvider(widget.subOrderId));
    final now = DateTime.now().toUtc();

    final assigned =
        state is DeliveryPartnerLive &&
        state.request.state == DeliveryRequestState.assigned;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s20,
          DesignTokens.s12,
          DesignTokens.s20,
          DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              header: true,
              child: Text(
                'Find a delivery partner',
                style: DesignTokens.displaySection,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'StyleMint riders near you are asked who can take it. You see '
              'who is interested and choose — nobody is assigned until you do.',
              style: DesignTokens.smallDescription,
            ),
            const SizedBox(height: DesignTokens.s16),
            switch (state) {
              DeliveryPartnerLoading(:final finding) => _Busy(
                label: finding
                    ? 'Asking riders near you…'
                    : 'Checking for riders…',
              ),
              DeliveryPartnerNotRequested() => _NotRequested(
                onFind: _notifier.findPartner,
              ),
              DeliveryPartnerFailed(:final failure) => _Problem(
                message: NetworkExceptions.getMessage(failure),
                onRetry: _notifier.retry,
              ),
              DeliveryPartnerLive(:final request, :final choosingOfferId) =>
                _Live(
                  request: request,
                  now: now,
                  choosingOfferId: choosingOfferId,
                  onChoose: _choose,
                  onDetails: _openDetails,
                  onAskAgain: _notifier.findPartner,
                  onOwnCourier: () => Navigator.of(
                    context,
                  ).pop(const VendorPartnerUseOwnCourier()),
                  onHandedOver: (rider) =>
                      Navigator.of(context).pop(VendorPartnerHandedOver(rider)),
                ),
            },
            // The own-courier form stays one tap away in every state but an
            // assignment: a vendor with their own rider at the door should
            // never have to wait out a search to use them. Once a StyleMint
            // rider has the hop, handing it to someone else would strand them.
            if (!assigned) ...[
              const SizedBox(height: DesignTokens.s16),
              TextButton(
                key: VendorDeliveryPartnerSheet.ownCourierKey,
                onPressed: () => Navigator.of(
                  context,
                ).pop(const VendorPartnerUseOwnCourier()),
                child: const Text('Hand it to your own courier instead'),
              ),
            ],
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.textLight,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(child: Text(label, style: DesignTokens.mediumRegular)),
      ],
    ),
  );
}

class _NotRequested extends StatelessWidget {
  const _NotRequested({required this.onFind});

  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Every rider within 5 km who is on shift gets a notification. The '
          'request stays open for 15 minutes.',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s12),
        _PrimaryButton(
          key: VendorDeliveryPartnerSheet.findKey,
          label: 'Find a delivery partner',
          onPressed: onFind,
        ),
      ],
    ),
  );
}

/// A real failure — not "nobody is nearby". Says what went wrong and offers
/// the retry, rather than steering the vendor to their own courier.
class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => _Panel(
    borderColor: DesignTokens.colorError.withValues(alpha: 0.4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: DesignTokens.colorError,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(
                "Couldn't reach delivery partners. $message",
                style: DesignTokens.smallRegular,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        OutlinedButton(
          key: VendorDeliveryPartnerSheet.retryKey,
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _Live extends StatelessWidget {
  const _Live({
    required this.request,
    required this.now,
    required this.choosingOfferId,
    required this.onChoose,
    required this.onDetails,
    required this.onAskAgain,
    required this.onOwnCourier,
    required this.onHandedOver,
  });

  final DeliveryRequest request;
  final DateTime now;
  final String? choosingOfferId;
  final ValueChanged<InterestedRider> onChoose;
  final ValueChanged<InterestedRider> onDetails;
  final VoidCallback onAskAgain;
  final VoidCallback onOwnCourier;
  final ValueChanged<AssignedRider> onHandedOver;

  @override
  Widget build(BuildContext context) {
    switch (request.state) {
      case DeliveryRequestState.assigned:
        final rider = request.assigned;
        return rider == null
            // Assigned with no rider attached should not happen; say what is
            // known rather than draw an empty card.
            ? _Panel(
                child: Text(
                  'A rider has been assigned and is on the way.',
                  style: DesignTokens.mediumRegular,
                ),
              )
            : _Assigned(rider: rider, onHandedOver: onHandedOver);

      case DeliveryRequestState.expired:
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nobody was chosen in time', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'The request closed before a rider was picked. Asking again '
                'notifies whoever is nearby now.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              _PrimaryButton(
                key: VendorDeliveryPartnerSheet.askAgainKey,
                label: 'Ask again',
                onPressed: onAskAgain,
              ),
            ],
          ),
        );

      case DeliveryRequestState.noRiders:
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'No rider is within ${_km(request.radiusKm)} km right now',
                style: DesignTokens.h3,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Nobody on shift is close enough to be asked. Riders come '
                'online through the day, so trying again in a few minutes '
                'often finds someone — or hand it to your own courier.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              _PrimaryButton(
                key: VendorDeliveryPartnerSheet.askAgainKey,
                label: 'Try again',
                onPressed: onAskAgain,
              ),
              const SizedBox(height: DesignTokens.s8),
              OutlinedButton(
                onPressed: onOwnCourier,
                child: const Text('Use your own courier'),
              ),
            ],
          ),
        );

      case DeliveryRequestState.searching:
      case DeliveryRequestState.ridersInterested:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchHeader(request: request, now: now),
            if (request.interested.isEmpty) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Riders who can take it appear here. You choose who does.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            for (final rider in request.interested) ...[
              const SizedBox(height: DesignTokens.s12),
              _RiderCard(
                rider: rider,
                now: now,
                choosing: choosingOfferId == rider.offerId,
                enabled: choosingOfferId == null,
                onChoose: () => onChoose(rider),
                onDetails: () => onDetails(rider),
              ),
            ],
          ],
        );
    }
  }
}

/// "Notified 4 riders within 5 km · open for 14:32", with the search pulse.
class _SearchHeader extends StatelessWidget {
  const _SearchHeader({required this.request, required this.now});

  final DeliveryRequest request;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final left = request.remainingAt(now);
    final riders = request.notifiedCount == 1 ? 'rider' : 'riders';
    return _Panel(
      child: Row(
        children: [
          const _SearchingPulse(),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.interested.isEmpty
                      ? 'Waiting for riders…'
                      : '${request.interested.length} interested',
                  style: DesignTokens.mediumSemibold,
                ),
                Text(
                  'Notified ${request.notifiedCount} $riders within '
                  '${_km(request.radiusKm)} km'
                  '${left == null ? '' : ' · open for ${_clock(left)}'}',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One interested rider: who they are, how they are rated, how far away —
/// and the whole row opens their details.
class _RiderCard extends StatelessWidget {
  const _RiderCard({
    required this.rider,
    required this.now,
    required this.choosing,
    required this.enabled,
    required this.onChoose,
    required this.onDetails,
  });

  final InterestedRider rider;
  final DateTime now;
  final bool choosing;
  final bool enabled;
  final VoidCallback onChoose;
  final VoidCallback onDetails;

  /// "★ 4.8 (23) · 12 deliveries", or "New rider · …" under three ratings.
  static String ratingLine(InterestedRider rider) {
    final rating = rider.rating;
    final count = rider.ratingCount;
    final stars = rating == null
        ? 'New rider'
        : '★ ${rating.toStringAsFixed(1)}${count == null ? '' : ' ($count)'}';
    final n = rider.completedDeliveries;
    return '$stars · $n ${n == 1 ? 'delivery' : 'deliveries'}';
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = rider.vehicle;
    final interestedAt = rider.interestedUtc;
    final details = <String>[
      '${rider.distanceKm.toStringAsFixed(1)} km away',
      ?vehicle,
      if (interestedAt != null) 'interested ${_ago(interestedAt, now)}',
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: VendorDeliveryPartnerSheet.detailsKey(rider.offerId),
            onTap: onDetails,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: Semantics(
              button: true,
              hint: 'Shows ratings, reviews and vehicle',
              child: Row(
                children: [
                  RiderAvatar(name: rider.displayName, url: rider.avatarUrl),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: DesignTokens.s8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              rider.displayName,
                              style: DesignTokens.mediumSemibold,
                            ),
                            if (rider.verified == true)
                              const RiderVerifiedTick(),
                            RiderTierBadge(rider.tier),
                          ],
                        ),
                        Text(
                          ratingLine(rider),
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                        Text(
                          details.join(' · '),
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DesignTokens.textMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          FilledButton(
            key: VendorDeliveryPartnerSheet.chooseKey(rider.offerId),
            onPressed: enabled ? onChoose : null,
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              foregroundColor: DesignTokens.buttonPrimaryText,
              minimumSize: const Size.fromHeight(44),
              shape: const StadiumBorder(),
            ),
            child: choosing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Choose ${_firstName(rider.displayName)}'),
          ),
        ],
      ),
    );
  }
}

class _Assigned extends StatelessWidget {
  const _Assigned({required this.rider, required this.onHandedOver});

  final AssignedRider rider;
  final ValueChanged<AssignedRider> onHandedOver;

  @override
  Widget build(BuildContext context) {
    final first = _firstName(rider.displayName);
    return _Panel(
      borderColor: DesignTokens.primaryGreen.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RiderAvatar(name: rider.displayName, url: rider.avatarUrl),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider.displayName, style: DesignTokens.mediumSemibold),
                    Text(
                      'Assigned · on the way to collect',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                    if (rider.phone != null)
                      Text(
                        rider.phone!,
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            '$first has the pick-up and the drop-off on their map. Record the '
            'handover when they collect the parcel.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s12),
          _PrimaryButton(
            key: VendorDeliveryPartnerSheet.handedOverKey,
            label: 'Handed to $first',
            onPressed: () => onHandedOver(rider),
          ),
        ],
      ),
    );
  }
}

/// Two expanding rings: "still looking". Holds still when the platform asks
/// for reduced motion.
class _SearchingPulse extends StatefulWidget {
  const _SearchingPulse();

  @override
  State<_SearchingPulse> createState() => _SearchingPulseState();
}

class _SearchingPulseState extends State<_SearchingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          for (final offset in const [0.0, 0.5])
            _ring((_controller.value + offset) % 1),
          const Icon(
            Icons.two_wheeler,
            size: 18,
            color: DesignTokens.primaryGreen,
          ),
        ],
      ),
    ),
  );

  Widget _ring(double t) => Container(
    width: 16 + 24 * t,
    height: 16 + 24 * t,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: DesignTokens.primaryGreen.withValues(alpha: 0.6 * (1 - t)),
        width: 2,
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      border: Border.all(
        color: borderColor ?? DesignTokens.textMuted.withValues(alpha: 0.2),
      ),
    ),
    child: child,
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: DesignTokens.primaryGreen,
      foregroundColor: DesignTokens.buttonPrimaryText,
      minimumSize: const Size.fromHeight(48),
      shape: const StadiumBorder(),
    ),
    child: Text(label, textAlign: TextAlign.center),
  );
}

String _firstName(String name) {
  final first = name.trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? name : first;
}

String _km(double km) =>
    km == km.roundToDouble() ? km.toStringAsFixed(0) : km.toStringAsFixed(1);

/// "14:32" — minutes and seconds left.
String _clock(Duration left) {
  final minutes = left.inMinutes;
  final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _ago(DateTime then, DateTime now) {
  final elapsed = now.difference(then);
  if (elapsed.inSeconds < 60) return 'just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  return '${elapsed.inHours}h ago';
}
