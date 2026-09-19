import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/carbon_impact_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/condition_assurance_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/custody_proof_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_acceptance_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_recovery_offers_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_care_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_return_link.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/warranty_claim_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/rate_review_sheet.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/cancelled_order_views.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_pill.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({
    required this.orderId,
    this.focusDeliveryRecovery = false,
    super.key,
  });

  final String orderId;

  /// Opened from the "your delivery is at risk" notification
  /// (`stylemint://delivery/{trackingNumber}/recovery`): scroll the AI
  /// Delivery Guardian banner and its recovery offers into view, and say
  /// so when the delivery has since recovered and the banner is empty.
  final bool focusDeliveryRecovery;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(orderDetailNotifierProvider(widget.orderId).notifier)
          .loadOrder(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = orderDetailNotifierProvider(widget.orderId);
    final state = ref.watch(provider);

    ref.listen<OrderDetailState>(provider, (previous, next) {
      next.maybeWhen(
        actionFailure: (failure) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Order Details',
          style: DesignTokens.sectionInnerTitle,
        ),
        centerTitle: true,
      ),
      // Scaffold doesn't inset its body from the bottom by default — the
      // system gesture/nav bar was clipping the last action row and the
      // "Cancel Order" button.
      body: SafeArea(
        child: state.when(
          initial: () => _loader(),
          loadInProgress: () => _loader(),
          loadSuccess: (order) => _refreshable(
            order,
            _OrderDetailBody(
              order: order,
              notifier: ref.read(provider.notifier),
              focusDeliveryRecovery: widget.focusDeliveryRecovery,
            ),
          ),
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load order details.',
            onRetry: () =>
                ref.read(provider.notifier).loadOrder(widget.orderId),
          ),
          actionInProgress: (order) => _refreshable(
            order,
            _OrderDetailBody(
              order: order,
              actionPending: true,
              notifier: ref.read(provider.notifier),
              focusDeliveryRecovery: widget.focusDeliveryRecovery,
            ),
          ),
          actionFailure: (failure) => _loader(),
        ),
      ),
    );
  }

  Widget _loader() => const SmPageLoader();

  Widget _refreshable(OrderDetail order, Widget child) => RefreshIndicator(
    color: DesignTokens.primaryGreen,
    onRefresh: () =>
        refreshOrderDetail(ref, routeOrderId: widget.orderId, order: order),
    child: child,
  );
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({
    required this.order,
    required this.notifier,
    this.actionPending = false,
    this.focusDeliveryRecovery = false,
  });

  final OrderDetail order;
  final OrderDetailNotifier notifier;
  final bool actionPending;
  final bool focusDeliveryRecovery;

  @override
  ConsumerState<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends ConsumerState<_OrderDetailBody> {
  bool _expanded = false;
  final GlobalKey _trackingSectionKey = GlobalKey();

  Future<void> _scrollToTracking() async {
    final trackingContext = _trackingSectionKey.currentContext;
    if (trackingContext == null) return;

    await Scrollable.ensureVisible(
      trackingContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  /// Wires a Post-Purchase Care action to the flow this screen already has;
  /// null omits the button (no tracking to scroll to, or no matching order
  /// line to return, review or buy again).
  CareActionHandler? _careActionFor(
    OrderDetail order,
    CareItem care,
    CareAction action,
  ) {
    final line = _orderLineFor(order, care);
    switch (action) {
      case CareAction.track:
        return order.trackingNumber?.trim().isNotEmpty == true
            ? (_) => _scrollToTracking()
            : null;
      case CareAction.returnItem:
        if (line == null) return null;
        return (_) => _startReturnRequest(
          context,
          order: order,
          notifier: widget.notifier,
          initialItem: line,
        );
      case CareAction.review:
        if (line == null || line.productId.isEmpty) return null;
        return (_) => _showRateReviewSheet(
          context,
          productId: line.productId,
          orderId: order.id,
        );
      case CareAction.reorder:
        if (line == null || line.productId.isEmpty) return null;
        return (_) => context.push('/product/${line.productId}');
      case CareAction.getHelp:
        return (_) => context.push(RouteNames.supportContact);
      case CareAction.warrantyClaim:
        return (_) => showWarrantyClaimSheet(
          context,
          ref,
          orderNumber: order.orderNumber,
          item: care,
        );
      case CareAction.warrantyStatus:
        return (_) => showWarrantyStatusSheet(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final trackingNumber = order.trackingNumber;

    final story = trackingNumber?.startsWith('SM-D-') == true
        ? ref.watch(deliveryStoryProvider(trackingNumber!))
        : null;
    if (order.status == OrderTrackStatus.cancelled) {
      return _buildCancelledView(order);
    }
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrackSummaryCard(
            order: order,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          if (trackingNumber?.startsWith('SM-D-') == true) ...[
            const SizedBox(height: DesignTokens.s12),
            _DeliveryRiskBanner(
              trackingNumber: trackingNumber!,
              autoFocus: widget.focusDeliveryRecovery,
            ),
            _PackageSealCard(trackingNumber: trackingNumber),
            // "Can't be there when it arrives?" — authorise, review and
            // revoke a delegated handover for *this* parcel, where the
            // customer already is. Offered while the parcel is still
            // in flight; once it is delivered only the history renders.
            HandoverDelegationCard(
              trackingNumber: trackingNumber,
              canDelegate: _parcelMayStillBeDelegated(order.status),
            ),
            // Only once the parcel may have reached the buyer; the card
            // itself checks the package is out for delivery or delivered.
            if (_parcelMayHaveArrived(order.status))
              DeliveryAcceptanceCard(
                trackingNumber: trackingNumber,
                items: order.items,
              ),
            const CarbonImpactCard(),
          ],
          OrderCareCard(
            orderNumber: order.orderNumber,
            resolveAction: (item, action) =>
                _careActionFor(order, item, action),
          ),
          OrderReturnLink(order: order),
          const SizedBox(height: DesignTokens.s24),
          KeyedSubtree(
            key: _trackingSectionKey,
            // Backend timeline per sub-order; the derived stages below are
            // the fallback when that call fails.
            child: OrderTrackingSection(
              orderNumber: order.orderNumber,
              supplement: story?.maybeWhen(
                data: (chapters) => chapters.isEmpty
                    ? null
                    : _DeliveryStoryTimeline(
                        status: order.status,
                        chapters: chapters,
                        showStages: false,
                      ),
                orElse: () => null,
              ),
              fallback:
                  story?.when(
                    data: (chapters) => chapters.isEmpty
                        ? _TrackingTimeline(
                            status: order.status,
                            channel: order.fulfillmentChannel,
                          )
                        : _DeliveryStoryTimeline(
                            status: order.status,
                            chapters: chapters,
                          ),
                    loading: () => const _DeliveryStoryLoading(),
                    error: (_, __) => _DeliveryStoryError(
                      onRetry: () => ref.invalidate(
                        deliveryStoryProvider(trackingNumber!),
                      ),
                    ),
                  ) ??
                  _TrackingTimeline(
                    status: order.status,
                    channel: order.fulfillmentChannel,
                  ),
            ),
          ),
          // The signed handover log, directly under the tracking history the
          // customer is already reading. It renders nothing at all — not even
          // its own leading gap — when the parcel has no custody entries or
          // the endpoint is unavailable, which is why the spacing lives
          // inside the card rather than here.
          if (trackingNumber?.startsWith('SM-D-') == true) ...[
            CustodyProofCard(trackingNumber: trackingNumber!),
            // What was recorded about the parcel's condition, under the
            // handover log it cites. Same self-effacing contract: no
            // controls, no findings or an unavailable endpoint and it draws
            // nothing, not even its own leading gap.
            ConditionAssuranceCard(trackingNumber: trackingNumber),
          ],
          if (order.status == OrderTrackStatus.delivered) ...[
            const SizedBox(height: DesignTokens.s24),
            _ReviewableItemsSection(order: order),
          ],
          _ViewOtherDetails(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            _OtherDetails(
              order: order,
              actionPending: widget.actionPending,
              notifier: widget.notifier,
              onViewTracking: trackingNumber?.trim().isNotEmpty == true
                  ? _scrollToTracking
                  : null,
            ),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }

  Widget _buildCancelledView(OrderDetail order) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CancelledOrderSummary(order: order),
          const SizedBox(height: DesignTokens.s16),
          // No `cancelledAt`: the card reads the recorded cancellation event.
          CancellationDetailsCard(order: order),
          const SizedBox(height: DesignTokens.s16),
          OrderTrackingSection(
            orderNumber: order.orderNumber,
            fallback: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CancelledTrackingStepper(orderNumber: order.orderNumber),
                const SizedBox(height: DesignTokens.s16),
                CancelledOrderHistory(orderNumber: order.orderNumber),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          _ViewOtherDetails(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            _OtherDetails(
              order: order,
              actionPending: widget.actionPending,
              notifier: widget.notifier,
            ),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }
}

// ── Track Order summary card ──────────────────────────────────────────────────
class _TrackSummaryCard extends StatelessWidget {
  const _TrackSummaryCard({
    required this.order,
    required this.expanded,
    required this.onToggle,
  });

  final OrderDetail order;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final placed = DateFormat('HH:mm MMM d, yyyy').format(order.placedAt);
    // The API supplies one estimated delivery date. Do not manufacture a
    // range that customers could interpret as a delivery commitment.
    final expected = DateFormat('MMM dd, yyyy').format(
      order.estimatedDelivery,
    );

    final delivered = order.status == OrderTrackStatus.delivered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The state first, in the display face. Everything the card used to
        // lead with - the order number, the date, the total - is paperwork;
        // it is still here, just below the answer to the question the buyer
        // actually opened this screen with.
        MallStatusSummary(
          eyebrow: 'Order #${order.orderNumber}',
          title: order.status.label,
          tone: OrderStatusPill.mallToneFor(
            OrderStatusBadge.toneFor(order.status),
          ),
          icon: OrderStatusBadge.iconFor(order.status),
          detail: delivered
              ? 'Delivered on $expected'
              : 'Estimated delivery $expected',
          footnote: 'Placed $placed',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: DesignTokens.cardDecoration(),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/OrderImage.svg',
                width: 48,
                height: 48,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMoney(order.total),
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                        fontFeatures: mallTabularFigures,
                      ),
                    ),
                    if (order.trackingNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tracking ID ${order.trackingNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontFeatures: mallTabularFigures,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Semantics(
                button: true,
                label: expanded ? 'Hide order details' : 'Show order details',
                child: GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox.square(
                    dimension: DesignTokens.minTouchTarget,
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.chevron_right_rounded,
                      size: 20,
                      color: DesignTokens.iconLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tracking timeline ──────────────────────────────────────

/// The derived stage view, shown only when the backend timeline is not
/// available. It used to draw its own marks, its own dashed rule and its own
/// two shades of green; it is now the kit's stepper, so a stage that has not
/// happened is a hollow ring behind a dashed rail rather than a very slightly
/// darker square - readable with the colour taken away.
///
/// **It is channel-aware, and that is the whole point.** This widget draws
/// stages from order state alone, with no backend timeline to correct it. A
/// collection order rendered through the courier stages showed Shipped, In
/// transit and Out for delivery — three journeys nobody made, drawn as
/// progress, on an order a buyer walks in and picks up. The backend fixed
/// its own copy of that defect; this is the client's copy, and
/// [collectionStages] exists so the fix cannot be undone by accident.
class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({
    required this.status,
    this.channel = OrderFulfillmentChannel.delivery,
  });

  final OrderTrackStatus status;

  /// Defaults to delivery, so every existing call site keeps the courier
  /// stages it already had.
  final OrderFulfillmentChannel channel;

  static const deliveryStages = [
    'Shipped',
    'In transit',
    'Out for delivery',
    'Delivered',
  ];

  /// No shipment, no transit, no last mile. The order is confirmed, it is
  /// prepared, it waits at the counter, the buyer takes it.
  static const collectionStages = [
    'Confirmed',
    'Preparing',
    'Ready for collection',
    'Collected',
  ];

  List<String> get _stages =>
      channel.isCollection ? collectionStages : deliveryStages;

  // -1 means "before any of these 4 stages" — nothing here should render as
  // the active/ongoing step. preparingForShipping used to map to 0, which is
  // the *index* of the 'Shipped' stage, so a brand-new order that hadn't
  // shipped yet showed "Shipped" as its current status (confirmed live: a
  // just-placed Cash on Delivery order rendered with "Shipped" highlighted
  // green before the vendor had even confirmed it).
  int get _current => switch (status) {
    OrderTrackStatus.preparingForShipping => -1,
    // On the collection path the order-level "fulfilling" state means the
    // seller is preparing it, not that it is moving through a network.
    OrderTrackStatus.inTransit => channel.isCollection ? 1 : 1,
    OrderTrackStatus.outForDelivery => channel.isCollection ? 2 : 2,
    OrderTrackStatus.delivered => 4,
    OrderTrackStatus.cancelled => -1,
  };

  MallStepState _stateFor(int i) {
    // A cancelled order is not merely "not there yet": say the stages will
    // not happen rather than leaving four hopeful hollow rings on screen.
    if (status == OrderTrackStatus.cancelled) return MallStepState.skipped;
    if (i < _current) return MallStepState.done;
    if (i == _current) return MallStepState.current;
    return MallStepState.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tracking Timeline', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s16),
          MallStatusStepper(
            semanticLabel: 'Tracking timeline',
            steps: [
              for (var i = 0; i < _stages.length; i++)
                MallTimelineStep(
                  title: _stages[i],
                  state: _stateFor(i),
                  markKey: ValueKey('delivery-stage-icon-$i'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uses Delivery's append-only Story Mode projection when a package has a
/// Style Mint tracking number, rather than guessing events from order state.
/// "AI Delivery Guardian" — shows nothing when the delivery is on track,
/// loading, or the check failed (best-effort, never blocking).
class _DeliveryRiskBanner extends ConsumerStatefulWidget {
  const _DeliveryRiskBanner({
    required this.trackingNumber,
    this.autoFocus = false,
  });

  final String trackingNumber;

  /// Arrived from the at-risk push notification: scroll this banner into
  /// view once the risk read lands, and — when the delivery has recovered
  /// in the meantime, so there is nothing to warn about — say so instead of
  /// leaving the customer on a screen with no trace of the alert.
  final bool autoFocus;

  @override
  ConsumerState<_DeliveryRiskBanner> createState() =>
      _DeliveryRiskBannerState();
}

class _DeliveryRiskBannerState extends ConsumerState<_DeliveryRiskBanner> {
  bool _focused = false;

  void _focusOnce() {
    if (_focused || !widget.autoFocus) return;
    _focused = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.05,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingNumber = widget.trackingNumber;
    final risk = ref.watch(deliveryRiskProvider(trackingNumber)).asData?.value;
    if (risk == null || !risk.atRisk) {
      // Opened from the notification and the backend now says the delivery
      // is fine: the alert is answered, not missing.
      if (widget.autoFocus && risk != null) {
        _focusOnce();
        return _BackOnTrackNote(trackingNumber: trackingNumber);
      }
      return const SizedBox.shrink();
    }
    _focusOnce();

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.warning500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: DesignTokens.warning500,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      risk.customerMessage,
                      style: DesignTokens.smallRegular.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (risk.recommendedAction != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        risk.recommendedAction!,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // The remedies belong with the worry, not on a screen the customer
          // has to go and find. Renders nothing when there is none to offer.
          DeliveryRecoveryOffersView(trackingNumber: trackingNumber),
        ],
      ),
    );
  }
}

/// Shown in the risk banner's place when the customer opened the at-risk
/// notification but the delivery has since recovered — so the alert has a
/// visible answer instead of vanishing into an ordinary order screen.
class _BackOnTrackNote extends StatelessWidget {
  const _BackOnTrackNote({required this.trackingNumber});

  final String trackingNumber;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreen.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(DesignTokens.s8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 18,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            'Good news — delivery $trackingNumber is back on track. '
            'No action needed.',
            style: DesignTokens.smallRegular.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Voyager "Tamper/Seal Proof" — the vendor's own pack-time tamper-evident
/// seal (photo of the sealed box + a unique seal id), distinct from
/// [_SealBadge] below (which shows a courier's in-transit handoff photo
/// for one story chapter). Renders nothing if the vendor never applied a
/// seal, or the read fails — supplementary trust signal, never blocking.
class _PackageSealCard extends ConsumerWidget {
  const _PackageSealCard({required this.trackingNumber});

  final String trackingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seal = ref.watch(packageSealProvider(trackingNumber)).asData?.value;
    if (seal == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: InkWell(
        onTap: () => _showFullPhoto(context, seal.sealPhotoUrl),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s4),
                child: Image.network(
                  seal.sealPhotoUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 40,
                    height: 40,
                    color: DesignTokens.bgAppBodyLight,
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Packed sealed by the seller',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Seal #${seal.sealId} · tap to view photo',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: DesignTokens.iconWhite),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tamper and Condition Assurance" — the seal photo taken at pickup,
/// shown as proof the package left the vendor sealed. Renders nothing if
/// the backend hasn't attached a photo (older packages, or a courier tier
/// that doesn't capture one).
class _SealBadge extends StatelessWidget {
  const _SealBadge({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s8),
      child: InkWell(
        onTap: () => _showSealPhoto(context, photoUrl!),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s4),
              child: Image.network(
                photoUrl!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 40,
                  height: 40,
                  color: DesignTokens.bgAppBodyLight,
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Text(
              'Sealed for your protection · tap to view',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSealPhoto(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: DesignTokens.iconWhite),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStoryTimeline extends StatelessWidget {
  const _DeliveryStoryTimeline({
    required this.status,
    required this.chapters,
    this.showStages = true,
  });

  final OrderTrackStatus status;
  final List<DeliveryStoryChapter> chapters;

  /// False when the backend timeline above already shows the stages.
  final bool showStages;

  static IconData _iconFor(DeliveryStoryChapterKind kind) => switch (kind) {
    DeliveryStoryChapterKind.sealed => Icons.inventory_2_outlined,
    DeliveryStoryChapterKind.pickedUp => Icons.back_hand_outlined,
    DeliveryStoryChapterKind.onTheMove => Icons.local_shipping_outlined,
    DeliveryStoryChapterKind.handedOff => Icons.swap_horiz_rounded,
    DeliveryStoryChapterKind.arrivedLocal => Icons.location_on_outlined,
    DeliveryStoryChapterKind.outForDelivery => Icons.airport_shuttle_rounded,
    DeliveryStoryChapterKind.delivered => Icons.check_circle_rounded,
    DeliveryStoryChapterKind.unknown => Icons.notifications_active_outlined,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showStages) ...[
        _TrackingTimeline(status: status),
        const SizedBox(height: DesignTokens.s16),
      ],
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Delivery Updates',
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s12),
            for (final chapter in chapters) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: ValueKey(
                      'delivery-update-icon-${chapter.sequence}',
                    ),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryGreenDark,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _iconFor(chapter.kind),
                      color: DesignTokens.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: DesignTokens.oneLinerSemibold,
                        ),
                        if (chapter.subtitle.isNotEmpty)
                          Text(
                            chapter.subtitle,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        Text(
                          DateFormat(
                            'MMM d, h:mm a',
                          ).format(chapter.occurredUtc.toLocal()),
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        if (chapter.kind == DeliveryStoryChapterKind.sealed)
                          _SealBadge(photoUrl: chapter.heroImageUrl),
                      ],
                    ),
                  ),
                ],
              ),
              if (chapter != chapters.last)
                const SizedBox(height: DesignTokens.s16),
            ],
          ],
        ),
      ),
    ],
  );
}

class _DeliveryStoryLoading extends StatelessWidget {
  const _DeliveryStoryLoading();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Loading live delivery tracking',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      // A spinner says only "wait". The skeleton has the shape of the
      // updates that are about to land, so the wait is legible.
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmSkeleton.line(width: 160, height: 16),
          SizedBox(height: DesignTokens.s16),
          _StorySkeletonRow(),
          SizedBox(height: DesignTokens.s12),
          _StorySkeletonRow(),
        ],
      ),
    ),
  );
}

class _DeliveryStoryError extends StatelessWidget {
  const _DeliveryStoryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'Live tracking is temporarily unavailable',
    child: Container(
      width: double.infinity,
      decoration: DesignTokens.cardDecoration(),
      child: MallErrorState(
        title: 'Live tracking is paused',
        body:
            'Your order and its details are safe — we just could not reach '
            'the courier feed.',
        retryLabel: 'Retry live tracking',
        onRetry: onRetry,
      ),
    ),
  );
}

/// The shape of one incoming delivery update.
class _StorySkeletonRow extends StatelessWidget {
  const _StorySkeletonRow();

  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SmSkeleton.box(
        width: 36,
        height: 36,
        radius: DesignTokens.radiusMedium,
      ),
      SizedBox(width: DesignTokens.s12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmSkeleton.line(width: 180, height: 13),
            SizedBox(height: DesignTokens.s6),
            SmSkeleton.line(width: 120, height: 11),
          ],
        ),
      ),
    ],
  );
}

class _ViewOtherDetails extends StatelessWidget {
  const _ViewOtherDetails({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          0,
          DesignTokens.s16,
          0,
          DesignTokens.s12,
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                expanded ? 'Hide other details' : 'View other details',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s4),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: DesignTokens.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expanded "other details" (price, shipping, items, actions) ────────────────
class _OtherDetails extends StatelessWidget {
  const _OtherDetails({
    required this.order,
    required this.actionPending,
    required this.notifier,
    this.onViewTracking,
  });

  final OrderDetail order;
  final bool actionPending;
  final OrderDetailNotifier notifier;
  final VoidCallback? onViewTracking;

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.length;
    final totalStr = formatMoney(order.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group 1
        _ActionRowCard(
          children: [
            // A collection order has no shipping address and the row says
            // so, rather than opening a sheet onto an empty one.
            if (order.isCollection)
              _ActionRow(
                key: const ValueKey('order-collection-row'),
                iconData: Icons.storefront_outlined,
                iconColor: DesignTokens.iconLight,
                iconBg: DesignTokens.bgAppBodyLight,
                title: 'Collection',
                subtitle: _collectionRowSubtitle(order),
              )
            else
              _ActionRow(
                iconData: Icons.location_on_outlined,
                iconColor: DesignTokens.iconLight,
                iconBg: DesignTokens.bgAppBodyLight,
                title: 'Shipping Address',
                subtitle: order.shippingAddress,
                onTap: () => _showShippingAddressSheet(context, order),
              ),
            _rowDivider(),
            _ActionRow(
              iconData: Icons.inventory_2_outlined,
              iconColor: DesignTokens.iconLight,
              iconBg: DesignTokens.bgAppBodyLight,
              title: 'Order Summary',
              subtitle:
                  '$itemCount item${itemCount == 1 ? '' : 's'} • $totalStr Total',
              onTap: () => _showOrderSummarySheet(context, order),
            ),
            _rowDivider(),
            _ActionRow(
              iconData: Icons.receipt_long_outlined,
              iconColor: DesignTokens.iconLight,
              iconBg: DesignTokens.bgAppBodyLight,
              title: 'View Invoice',
              subtitle: 'Your invoice for the order',
              onTap: () => context.push(
                '/orders/${order.orderNumber}/invoice',
                extra: order,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        // Group 2
        _ActionRowCard(
          children: [
            if (onViewTracking != null) ...[
              _ActionRow(
                iconData: Icons.local_shipping_outlined,
                iconColor: DesignTokens.iconLight,
                iconBg: DesignTokens.bgAppBodyLight,
                title: 'View Delivery Tracking',
                subtitle: order.trackingNumber?.startsWith('SM-D-') == true
                    ? 'Live StyleMint package updates'
                    : 'View the latest package status',
                onTap: onViewTracking!,
              ),
              _rowDivider(),
            ],
            _ActionRow(
              iconData: Icons.headset_mic_outlined,
              iconColor: DesignTokens.iconLight,
              iconBg: DesignTokens.bgAppBodyLight,
              title: 'Contact Support',
              subtitle: 'Have any queries? We are here to help',
              onTap: () => context.push(RouteNames.supportContact),
            ),
            if (order.canCancel) ...[
              _rowDivider(),
              _ActionRow(
                iconData: Icons.cancel_outlined,
                iconColor: DesignTokens.iconLight,
                iconBg: DesignTokens.bgAppBodyLight,
                title: 'Cancel Order',
                subtitle: 'Order cancellation procedure',
                onTap: () => context.push(
                  '/orders/${order.orderNumber}/cancel',
                  extra: order,
                ),
              ),
            ],
            if (order.canReturn) ...[
              _rowDivider(),
              _ActionRow(
                iconData: Icons.keyboard_return_outlined,
                iconColor: DesignTokens.iconLight,
                iconBg: DesignTokens.bgAppBodyLight,
                title: 'Request Return',
                subtitle: 'Start a return for this order',
                onTap: () => _handleRequestReturn(context),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _rowDivider() => const Divider(
    color: DesignTokens.borderDefault,
    height: 1,
    indent: 16,
    endIndent: 16,
  );

  void _handleRequestReturn(BuildContext context) =>
      _startReturnRequest(context, order: order, notifier: notifier);
}

/// Whether a StyleMint parcel may have reached the buyer, so the "Got your
/// parcel?" card should check its package. The overall order status never
/// reads "out for delivery" (Fulfilling maps to in transit), so in-transit
/// orders are checked too; the card itself requires the package to be out
/// for delivery or delivered.
/// Whether a handover delegation can still be created for this parcel.
/// Mirrors the backend rule (`PackageState.Delivered/Returning/Returned` is
/// refused with `business_rule`) so the button is not offered into a
/// guaranteed refusal. Existing delegations still render either way.
bool _parcelMayStillBeDelegated(OrderTrackStatus status) =>
    status != OrderTrackStatus.delivered &&
    status != OrderTrackStatus.cancelled;

bool _parcelMayHaveArrived(OrderTrackStatus status) =>
    status == OrderTrackStatus.inTransit ||
    status == OrderTrackStatus.outForDelivery ||
    status == OrderTrackStatus.delivered;

/// The order line a Post-Purchase Care item refers to (care
/// `subOrderLineId` is the order detail line id), or null if absent.
OrderDetailItem? _orderLineFor(OrderDetail order, CareItem care) {
  final lineId = care.subOrderLineId.toLowerCase();
  if (lineId.isEmpty) return null;
  for (final item in order.items) {
    if (item.id.toLowerCase() == lineId) return item;
  }
  return null;
}

/// Opens the return request dialog (optionally preselecting [initialItem])
/// and submits the collected return through the order detail notifier.
void _startReturnRequest(
  BuildContext context, {
  required OrderDetail order,
  required OrderDetailNotifier notifier,
  OrderDetailItem? initialItem,
}) {
  showDialog<_ReturnRequestResult>(
    context: context,
    builder: (ctx) => _ReturnRequestDialog(
      items: order.items,
      notifier: notifier,
      initialItem: initialItem,
    ),
  ).then((result) {
    if (result != null) {
      notifier.requestReturn(
        subOrderId: result.item.subOrderId,
        subOrderLineId: result.item.id,
        quantity: result.quantity,
        reason: result.reason,
        photoUrls: result.photoUrls,
        resolution: result.resolution,
        replacementVariantId: result.replacementVariantId,
      );
    }
  });
}

class _ActionRowCard extends StatelessWidget {
  const _ActionRowCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: DesignTokens.cardDecoration(),
    child: Column(children: children),
  );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  /// Null for a row that only states a fact. The chevron goes with it —
  /// an affordance for a sheet that does not open is a small lie.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.iconLight,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// What [_ReturnRequestDialog] hands back to the caller on Submit.
class _ReturnRequestResult {
  const _ReturnRequestResult({
    required this.item,
    required this.quantity,
    required this.reason,
    required this.photoUrls,
    required this.resolution,
    this.replacementVariantId,
  });

  final OrderDetailItem item;
  final int quantity;
  final String reason;
  final List<String> photoUrls;
  final ReturnResolutionChoice resolution;
  final String? replacementVariantId;
}

/// Collects everything the backend's `SubmitReturnVm` requires: which line
/// item, how many units, why, and at least one photo (skill §13.7) — a
/// bare reason string always 400s server-side.
class _ReturnRequestDialog extends StatefulWidget {
  const _ReturnRequestDialog({
    required this.items,
    required this.notifier,
    this.initialItem,
  });

  final List<OrderDetailItem> items;
  final OrderDetailNotifier notifier;

  /// Preselected line (e.g. from the Care & returns card); first item if null.
  final OrderDetailItem? initialItem;

  @override
  State<_ReturnRequestDialog> createState() => _ReturnRequestDialogState();
}

class _ReturnRequestDialogState extends State<_ReturnRequestDialog> {
  final _controller = TextEditingController();
  late OrderDetailItem _selectedItem;
  int _quantity = 1;
  final List<String> _photoUrls = [];
  bool _uploading = false;
  String? _error;
  ReturnResolutionChoice _resolution = ReturnResolutionChoice.refund;
  List<ReplacementOption> _replacementOptions = const [];
  ReplacementOption? _selectedReplacement;
  bool _loadingReplacements = false;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem ?? widget.items.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    final either = await widget.notifier.uploadReturnPhoto(picked.path);
    if (!mounted) return;
    either.fold(
      (failure) => setState(() {
        _uploading = false;
        _error = 'Photo upload failed. Try again.';
      }),
      (url) => setState(() {
        _uploading = false;
        _photoUrls.add(url);
      }),
    );
  }

  Future<void> _setResolution(ReturnResolutionChoice choice) async {
    setState(() {
      _resolution = choice;
      _error = null;
      _selectedReplacement = null;
      _replacementOptions = const [];
      _loadingReplacements = choice == ReturnResolutionChoice.replacement;
    });
    if (choice == ReturnResolutionChoice.refund) return;

    final result = await widget.notifier.getReplacementOptions(
      _selectedItem.productId,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loadingReplacements = false;
        _error = 'Could not load replacement options. Try again.';
      }),
      (options) {
        final eligible = options
            .where(
              (option) =>
                  option.price.currency == _selectedItem.unitPrice.currency,
            )
            .toList(growable: false);
        setState(() {
          _loadingReplacements = false;
          _replacementOptions = eligible;
          _selectedReplacement = eligible.isEmpty ? null : eligible.first;
          if (eligible.isEmpty) {
            _error = 'No replacement variant is currently in stock.';
          }
        });
      },
    );
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a reason for the return.');
      return;
    }
    if (_photoUrls.isEmpty) {
      setState(() => _error = 'Please add at least one photo.');
      return;
    }
    if (_resolution == ReturnResolutionChoice.replacement &&
        _selectedReplacement == null) {
      setState(() => _error = 'Choose an available replacement variant.');
      return;
    }
    Navigator.pop(
      context,
      _ReturnRequestResult(
        item: _selectedItem,
        quantity: _quantity,
        reason: _controller.text.trim(),
        photoUrls: _photoUrls,
        resolution: _resolution,
        replacementVariantId: _selectedReplacement?.variantId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: Text('Request Return', style: DesignTokens.sectionInnerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.items.length > 1) ...[
              Text('Item', style: DesignTokens.smallDescription),
              const SizedBox(height: DesignTokens.s8),
              DropdownButton<OrderDetailItem>(
                isExpanded: true,
                value: _selectedItem,
                dropdownColor: DesignTokens.bgAppBody,
                items: widget.items
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          i.productName,
                          style: DesignTokens.bodyText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (item) => setState(() {
                  _selectedItem = item ?? _selectedItem;
                  _quantity = 1;
                }),
              ),
              const SizedBox(height: DesignTokens.s12),
            ],
            Text(
              'How should we resolve it?',
              style: DesignTokens.smallDescription,
            ),
            const SizedBox(height: DesignTokens.s8),
            SegmentedButton<ReturnResolutionChoice>(
              segments: const [
                ButtonSegment(
                  value: ReturnResolutionChoice.refund,
                  icon: Icon(Icons.currency_rupee_rounded),
                  label: Text('Refund'),
                ),
                ButtonSegment(
                  value: ReturnResolutionChoice.replacement,
                  icon: Icon(Icons.swap_horiz_rounded),
                  label: Text('Replace'),
                ),
              ],
              selected: {_resolution},
              onSelectionChanged: (values) => _setResolution(values.first),
            ),
            if (_loadingReplacements) ...[
              const SizedBox(height: DesignTokens.s12),
              const LinearProgressIndicator(),
            ] else if (_resolution == ReturnResolutionChoice.replacement &&
                _replacementOptions.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s12),
              DropdownButtonFormField<ReplacementOption>(
                initialValue: _selectedReplacement,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Replacement variant',
                ),
                dropdownColor: DesignTokens.bgAppBody,
                items: _replacementOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          '${option.label} · ${formatMoney(option.price)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (option) =>
                    setState(() => _selectedReplacement = option),
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Stock is held for 24 hours. Cheaper options refund the difference; higher-priced options collect only the balance.',
                style: DesignTokens.smallDescription,
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Text('Quantity', style: DesignTokens.smallDescription),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: DesignTokens.iconLight,
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                ),
                Text('$_quantity', style: DesignTokens.mediumSemibold),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: DesignTokens.iconLight,
                  onPressed: _quantity < _selectedItem.qty
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: DesignTokens.bodyText,
              decoration: DesignTokens.inputDecoration(
                hintText: 'Reason for return',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                    child: Image.network(
                      _photoUrls[i],
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: DesignTokens.s8),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pickAndUploadPhoto,
              style: DesignTokens.outlinedButtonStyle(),
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                _photoUrls.isEmpty ? 'Add Photo' : 'Add Another Photo',
                style: DesignTokens.mediumSemibold,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                _error!,
                style: DesignTokens.smallRegular.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: _uploading ? null : _submit,
          child: Text(
            'Submit',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.textWhite,
                ),
              )
            : Icon(icon, color: color),
        label: Text(
          label,
          style: DesignTokens.mediumSemibold.copyWith(color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (valueStyle ?? DesignTokens.mediumSemibold).copyWith(
              color: valueColor ?? DesignTokens.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Write a Review (delivered orders only) ────────────────────────────────────
void _showRateReviewSheet(
  BuildContext context, {
  required String productId,
  required String orderId,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBody,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.cardRadius),
      ),
    ),
    builder: (_) => RateReviewSheet(productId: productId, orderId: orderId),
  );
}

class _ReviewableItemsSection extends StatelessWidget {
  const _ReviewableItemsSection({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rate Your Items', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s12),
          for (final item in order.items) ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                  child: Image.network(
                    item.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: DesignTokens.bgAppBodyLight,
                      child: const Icon(
                        Icons.image,
                        size: 18,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                OutlinedButton(
                  onPressed: () => _showRateReviewSheet(
                    context,
                    productId: item.productId,
                    orderId: order.id,
                  ),
                  style: DesignTokens.outlinedButtonStyle(),
                  child: Text(
                    'Write a Review',
                    style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (item != order.items.last)
              const SizedBox(height: DesignTokens.s12),
          ],
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image, color: DesignTokens.textMuted),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: DesignTokens.mediumSemibold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  item.variantName,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: ${item.qty}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    Text(
                      formatMoney(item.unitPrice),
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen,
                        fontFeatures: mallTabularFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the collection row says under its title. Never a place — this
/// screen holds no resolved counter name; the tracking timeline does, and
/// prints it only when the backend resolved one.
String _collectionRowSubtitle(OrderDetail order) => order.collectedAt == null
    ? 'You’re collecting this order in store'
    : 'Collected in store';

// ── Sheet launchers ───────────────────────────────────────────────────────────

void _showShippingAddressSheet(BuildContext context, OrderDetail order) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShippingAddressSheet(
      address: order.shippingAddress,
      receiverName: order.receiverName,
      receiverPhone: order.receiverPhone,
    ),
  );
}

void _showOrderSummarySheet(BuildContext context, OrderDetail order) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _OrderSummarySheet(order: order),
  );
}

// ── Shipping Address Sheet ────────────────────────────────────────────────────

class _ShippingAddressSheet extends StatelessWidget {
  const _ShippingAddressSheet({
    required this.address,
    required this.receiverName,
    required this.receiverPhone,
  });
  final String address;
  final String receiverName;
  final String receiverPhone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DesignTokens.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Shipping Address', style: DesignTokens.sectionInnerTitle),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: DesignTokens.iconLight,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const MallStatusPill(
              label: 'Home',
              tone: MallStatusTone.progress,
              icon: Icons.home_outlined,
              dense: true,
            ),
            const SizedBox(height: 12),
            if (receiverName.isNotEmpty) ...[
              Text(
                receiverName,
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (receiverPhone.isNotEmpty) ...[
              Text(
                receiverPhone,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              address,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Summary Sheet ───────────────────────────────────────────────────────

class _OrderSummarySheet extends StatelessWidget {
  const _OrderSummarySheet({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, sc) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 14),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.borderDefault,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    Text(
                      'Order Summary',
                      style: DesignTokens.sectionInnerTitle,
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.close,
                        color: DesignTokens.iconLight,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: DesignTokens.borderDefault, height: 1),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Items (${order.items.length})',
                      style: DesignTokens.mediumSemibold,
                    ),
                    const SizedBox(height: 12),
                    for (final item in order.items) _SummaryItemRow(item: item),
                    const SizedBox(height: 8),
                    const Divider(color: DesignTokens.borderDefault),
                    const SizedBox(height: 12),
                    Text('Bill Details', style: DesignTokens.mediumSemibold),
                    const SizedBox(height: 12),
                    // The kit's ledger: one rhythm, tabular figures, the
                    // hairline where the total starts, and the paid line
                    // said in words rather than implied by weight.
                    MallMoneyLedger(
                      semanticLabel: 'Bill details',
                      amounts: [
                        MallAmount(
                          label: 'Subtotal',
                          value: formatMoney(order.subtotal),
                        ),
                        MallAmount(
                          label: 'Shipping',
                          value: formatMoney(order.shipping),
                        ),
                        MallAmount(
                          label: 'Tax',
                          value: formatMoney(order.tax),
                        ),
                        MallAmount(
                          label: 'Paid',
                          value: formatMoney(order.total),
                          kind: MallAmountKind.total,
                          note: order.paymentMethod,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItemRow extends StatelessWidget {
  const _SummaryItemRow({required this.item});
  final OrderDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(
                  Icons.image,
                  size: 20,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.variantName} · Qty ${item.qty}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoney(item.unitPrice),
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
              fontSize: 13,
              fontFeatures: mallTabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
