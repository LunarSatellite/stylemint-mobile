import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_job_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_action_feedback.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_offer_card.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Hop offers, with the time left on each.
///
/// Offers are a Dutch auction: each round raises the payout, so one left to
/// expire can come back worth more. That makes the deadline the most important
/// thing on the card — a static "expires at 14:32" is useless to someone on a
/// bike, so this ticks.
///
/// Vendor-select offers are not first-come: the rider says they are
/// interested and the vendor chooses, minutes later. So this screen re-reads
/// while it is open — every [pollInterval] while the rider is online and the
/// app is in front, and at once on a delivery push — and the card follows the
/// answer: waiting, chosen (and off to the map), or not chosen.
class CourierOffersScreen extends ConsumerStatefulWidget {
  const CourierOffersScreen({
    this.pollInterval = const Duration(seconds: 10),
    super.key,
  });

  final Duration pollInterval;

  @override
  ConsumerState<CourierOffersScreen> createState() =>
      _CourierOffersScreenState();
}

class _CourierOffersScreenState extends ConsumerState<CourierOffersScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _poll;
  StreamSubscription<DeliveryPushEvent>? _pushSubscription;
  bool _foreground = true;

  /// The last interest state seen per offer, to tell a fresh "Selected" — the
  /// vendor just chose this rider — from one that was already there when the
  /// screen opened. Only the fresh one navigates.
  final Map<String, OfferInterestState> _known = {};

  /// What a tap just did, shown until the re-read it triggered lands, so the
  /// card does not flick back to "I'm interested" for a round trip.
  final Map<String, OfferInterestState> _optimistic = {};

  /// Seconds each "not chosen" card has been on screen, counted by the
  /// ticker. It fades out after [_notSelectedLingerSeconds] — long enough to
  /// read, not long enough to clutter the list.
  final Map<String, int> _notSelectedAge = {};
  final Set<String> _faded = {};

  static const _notSelectedLingerSeconds = 4;

  /// A lookup for "Open the map" is in flight; a second tap waits for it.
  bool _openingJob = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;

    // One timer for the screen, not one per card: a dozen offers would
    // otherwise mean a dozen timers all redrawing the same second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        for (final id in _notSelectedAge.keys.toList()) {
          _notSelectedAge[id] = _notSelectedAge[id]! + 1;
        }
      });
    });
    _poll = Timer.periodic(widget.pollInterval, (_) => _pollTick());
    _pushSubscription = ref
        .read(deliveryPushBusProvider)
        .events
        .listen(_onPush);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _poll?.cancel();
    unawaited(_pushSubscription?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        // Whatever happened while away — a vendor choosing, most likely —
        // is worth seeing now rather than at the next tick.
        _refresh();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _foreground = false;
      case AppLifecycleState.inactive:
        break;
    }
  }

  /// Polls only when it can matter: in the foreground, and on shift — an
  /// offline rider is offered nothing, so re-reading would be pure traffic.
  void _pollTick() {
    if (!mounted || !_foreground || !_online) return;
    _refresh();
  }

  bool get _online {
    final accountId = ref.read(courierAccountIdProvider);
    if (accountId.isEmpty) return true;
    // Unknown counts as online: polling a little too much is cheaper than a
    // rider missing the answer they are waiting on.
    return ref
        .read(courierProfileProvider(accountId))
        .maybeWhen(
          data: (profile) => profile?.isOnline ?? true,
          orElse: () => true,
        );
  }

  void _refresh() {
    if (mounted) ref.invalidate(courierOffersProvider);
  }

  void _onPush(DeliveryPushEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case DeliveryPushType.selected:
        ref.invalidate(courierHopsProvider);
        _refresh();
      case DeliveryPushType.request:
      case DeliveryPushType.notSelected:
        _refresh();
      case DeliveryPushType.interest:
      case DeliveryPushType.confirmRequest:
      case DeliveryPushType.delivered:
        break;
    }
  }

  /// Reacts to each fresh read: forgets optimistic overrides, starts the fade
  /// on newly "not chosen" cards, and goes to the map when this rider has
  /// just been chosen.
  void _onOffers(List<HopOffer> offers) {
    _optimistic.clear();
    HopOffer? newlySelected;
    for (final offer in offers) {
      if (!offer.isVendorSelect) continue;
      final before = _known[offer.id];
      if (offer.interestState == OfferInterestState.selected &&
          before != null &&
          before != OfferInterestState.selected) {
        newlySelected = offer;
      }
      if (offer.interestState == OfferInterestState.notSelected) {
        _notSelectedAge.putIfAbsent(offer.id, () => 0);
      }
      _known[offer.id] = offer.interestState;
    }
    final chosen = newlySelected;
    if (chosen != null) _celebrate(chosen);
  }

  void _celebrate(HopOffer offer) {
    final where = offer.pickup?.label;
    SmSnackbar.success(
      context,
      where == null
          ? "You've got it! Head to the pick-up."
          : "You've got it! Pick up at $where.",
    );
    _openMap();
  }

  /// Back to the dashboard, which is the map. Popped when there is somewhere
  /// to pop to — the dashboard pushed this screen, or the router stacked it
  /// over `/courier` — and routed there otherwise.
  void _openMap() {
    // The hop the selection created is what the dashboard's map draws.
    ref.invalidate(courierHopsProvider);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    GoRouter.maybeOf(context)?.go(RouteNames.courier);
  }

  /// "Open the map" on a chosen offer: straight to that job on the in-app
  /// map. An offer carries the package, not the hop, so the hop is looked up
  /// among the rider's jobs; until the job row exists (it is written a moment
  /// after the selection) this falls back to the dashboard, whose map draws
  /// the same job.
  Future<void> _openJob(HopOffer offer) async {
    if (_openingJob) return;
    _openingJob = true;
    final result = await ref.read(courierRepositoryProvider).listJobs();
    _openingJob = false;
    if (!mounted) return;
    final job = result
        .getOrElse((_) => const [])
        .where((j) => j.packageId == offer.packageId && !j.status.isFinished)
        .firstOrNull;
    if (job == null) {
      _openMap();
      return;
    }
    ref.invalidate(courierHopsProvider);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // In place of this screen, so back goes to the dashboard.
      unawaited(
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => CourierJobScreen(hopId: job.hopId),
          ),
        ),
      );
      return;
    }
    GoRouter.maybeOf(context)?.go(RouteNames.courierJobPath(job.hopId));
  }

  Future<void> _accept(HopOffer offer) async {
    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .acceptOffer(offer.id);
    if (!mounted) return;

    if (result is CourierActionOk) {
      if (offer.isVendorSelect) {
        // Interest only — nothing is the rider's yet, so the parcels list is
        // left alone and the card switches to waiting.
        setState(() => _optimistic[offer.id] = OfferInterestState.interested);
        _refresh();
        SmSnackbar.success(
          context,
          'Sent. The vendor sees you and will choose soon.',
        );
        return;
      }
      // Both lists move: the offer leaves, and a hop appears. Refreshing only
      // the offers would leave the courier wondering where the parcel went.
      ref
        ..invalidate(courierOffersProvider)
        ..invalidate(courierHopsProvider);
      SmSnackbar.success(context, 'Accepted. It is in your parcels now.');
      return;
    }
    showCourierActionFeedback(context, result);
  }

  Future<void> _withdraw(HopOffer offer) async {
    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .withdrawInterest(offer.id);
    if (!mounted) return;

    if (result is CourierActionOk) {
      setState(() => _optimistic[offer.id] = OfferInterestState.none);
      _refresh();
      return;
    }
    showCourierActionFeedback(context, result);
  }

  Future<void> _decline(HopOffer offer) async {
    final reason = await showModalBottomSheet<DeclineReason>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Text(
                // Said plainly, because it is true and it changes behaviour:
                // the router feeds these reasons back into matching.
                'Why are you passing? This changes what you get offered next.',
                style: DesignTokens.smallRegular,
                textAlign: TextAlign.center,
              ),
            ),
            ...DeclineReason.values.map(
              (reason) => ListTile(
                title: Text(reason.label),
                onTap: () => Navigator.of(sheetContext).pop(reason),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;

    final result = await ref
        .read(courierActionsNotifierProvider.notifier)
        .declineOffer(offerId: offer.id, reason: reason);
    if (!mounted) return;

    if (result is CourierActionOk) {
      ref.invalidate(courierOffersProvider);
      return;
    }
    showCourierActionFeedback(context, result);
  }

  /// Which offers are on screen.
  ///
  /// Auctions as before: pending and not yet expired. Vendor-select offers
  /// stay through their whole arc — waiting, chosen, not chosen, expired —
  /// because each is an answer the rider is owed; only a pass removes one,
  /// and a "not chosen" one fades out on its own.
  List<HopOffer> _visible(List<HopOffer> offers, DateTime now) => offers
      .where((offer) {
        if (!offer.isVendorSelect) {
          return offer.isPending && !offer.hasExpiredAt(now);
        }
        if (offer.state == HopOfferState.declined) return false;
        return !_faded.contains(offer.id);
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<HopOffer>>>(courierOffersProvider, (_, next) {
      // Fresh reads only. A refresh in flight still carries the previous
      // list, and treating that as an answer would drop the optimistic state
      // a round trip early.
      if (next case AsyncData(:final value)) _onOffers(value);
    });

    final offers = ref.watch(courierOffersProvider);
    final busy = ref.watch(courierActionsNotifierProvider);
    final now = DateTime.now().toUtc();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Offers'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(courierOffersProvider),
          child: offers.when(
            loading: () => const Center(child: SmBrandLoader()),
            error: (_, _) => ListView(
              padding: const EdgeInsets.all(DesignTokens.s20),
              children: [
                Text(
                  "Couldn't load offers. Pull to refresh.",
                  style: DesignTokens.smallRegular,
                ),
              ],
            ),
            data: (list) {
              final live = _visible(list, now);
              if (live.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(DesignTokens.s20),
                  children: [
                    Text('Nothing waiting on you', style: DesignTokens.h3),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'Offers arrive when a parcel near you needs carrying. '
                      'If none are coming, check your deposit and that your '
                      'account is live.',
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(DesignTokens.s20),
                itemCount: live.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.s12),
                itemBuilder: (_, index) {
                  final offer = live[index];
                  final card = CourierOfferCard(
                    key: ValueKey<String>('offer-${offer.id}'),
                    offer: offer,
                    now: now,
                    busy: busy,
                    interestState: _optimistic[offer.id],
                    onAccept: () => _accept(offer),
                    onDecline: () => _decline(offer),
                    onWithdraw: () => _withdraw(offer),
                    onOpenMap: () => _openJob(offer),
                  );
                  final age = _notSelectedAge[offer.id];
                  if (age == null ||
                      offer.interestState != OfferInterestState.notSelected) {
                    return card;
                  }
                  final fading = age >= _notSelectedLingerSeconds;
                  return AnimatedOpacity(
                    opacity: fading ? 0 : 1,
                    duration: const Duration(milliseconds: 600),
                    onEnd: () {
                      if (fading && mounted) {
                        setState(() => _faded.add(offer.id));
                      }
                    },
                    child: card,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
