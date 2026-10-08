import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';

/// Keeps the dashboard's offers and parcels current while a vendor decides,
/// so being chosen puts the job on the map without the rider pulling to
/// refresh.
///
/// Two ways in. A delivery push re-reads at once — `delivery.selected` is the
/// one that matters, since the hop it assigned is what the map draws. And
/// because push is not guaranteed (a build without Firebase config gets
/// none), while the rider is waiting on a vendor-select offer the offers are
/// re-read every [pollInterval] in the foreground; an offer turning
/// `Selected` re-reads the parcels. Renders nothing.
class CourierDeliveryPushListener extends ConsumerStatefulWidget {
  const CourierDeliveryPushListener({
    this.pollInterval = const Duration(seconds: 15),
    super.key,
  });

  final Duration pollInterval;

  @override
  ConsumerState<CourierDeliveryPushListener> createState() =>
      _CourierDeliveryPushListenerState();
}

class _CourierDeliveryPushListenerState
    extends ConsumerState<CourierDeliveryPushListener> {
  StreamSubscription<DeliveryPushEvent>? _subscription;
  Timer? _poll;
  Timer? _hopRetry;

  /// Whether any vendor-select offer is waiting on the vendor — the only
  /// time polling from the dashboard is worth it.
  bool _waiting = false;
  Set<String> _selected = const {};

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(deliveryPushBusProvider).events.listen(_onPush);
    _poll = Timer.periodic(widget.pollInterval, (_) => _tick());
  }

  void _onPush(DeliveryPushEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case DeliveryPushType.selected:
        ref
          ..invalidate(courierHopsProvider)
          ..invalidate(courierOffersProvider);
        // The push can beat the hop row: Delivery writes it from the same
        // assignment event a moment later. One more read catches it.
        _hopRetry?.cancel();
        _hopRetry = Timer(const Duration(seconds: 3), () {
          if (mounted) ref.invalidate(courierHopsProvider);
        });
      case DeliveryPushType.request:
      case DeliveryPushType.notSelected:
        ref.invalidate(courierOffersProvider);
      case DeliveryPushType.interest:
        // A vendor's notification; nothing on the rider's side changes.
        break;
    }
  }

  void _tick() {
    if (!mounted || !_waiting) return;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
    ref.invalidate(courierOffersProvider);
  }

  void _onOffers(List<HopOffer> offers) {
    final vendorSelect = offers.where((o) => o.isVendorSelect);
    _waiting = vendorSelect.any(
      (o) => o.interestState == OfferInterestState.interested,
    );
    final selected = vendorSelect
        .where((o) => o.interestState == OfferInterestState.selected)
        .map((o) => o.id)
        .toSet();
    if (selected.difference(_selected).isNotEmpty) {
      ref.invalidate(courierHopsProvider);
    }
    _selected = selected;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _hopRetry?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<HopOffer>>>(courierOffersProvider, (_, next) {
      if (next case AsyncData(:final value)) _onOffers(value);
    });
    return const SizedBox.shrink();
  }
}
