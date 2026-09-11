import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/rate_review_sheet.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

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
          onPressed: () => context.pop(),
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
          loadSuccess: (order) => _OrderDetailBody(
            order: order,
            notifier: ref.read(provider.notifier),
          ),
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load order details.',
            onRetry: () =>
                ref.read(provider.notifier).loadOrder(widget.orderId),
          ),
          actionInProgress: (order) => _OrderDetailBody(
            order: order,
            actionPending: true,
            notifier: ref.read(provider.notifier),
          ),
          actionFailure: (failure) => _loader(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _OrderDetailBody extends ConsumerStatefulWidget {
  const _OrderDetailBody({
    required this.order,
    required this.notifier,
    this.actionPending = false,
  });

  final OrderDetail order;
  final OrderDetailNotifier notifier;
  final bool actionPending;

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
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrackSummaryCard(
            order: order,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          const SizedBox(height: DesignTokens.s24),
          KeyedSubtree(
            key: _trackingSectionKey,
            child:
                story?.when(
                  data: (chapters) => chapters.isEmpty
                      ? _TrackingTimeline(status: order.status)
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
                _TrackingTimeline(status: order.status),
          ),
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
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CancelledSummaryCard(order: order),
          const SizedBox(height: DesignTokens.s16),
          _CancInfoCard(order: order),
          const SizedBox(height: DesignTokens.s16),
          const _CancelledTimeline3(),
          const SizedBox(height: DesignTokens.s16),
          _OrderHistoryTimeline(order: order),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.s16,
        horizontal: DesignTokens.s12,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/OrderImage.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Row(
                      children: [
                        // The price is short and fixed-width; give the date
                        // (the longer, more important string) the flexible
                        // slot instead of splitting the row 50/50, which
                        // truncated it down to a few characters.
                        Flexible(
                          child: Text(
                            'Placed on $placed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ),
                        const _Dot(),
                        Text(
                          formatMoney(order.total),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 16,
                  color: DesignTokens.iconLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Backend-provided estimated-delivery date.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s8,
              vertical: DesignTokens.s4,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.tagInfoFill,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 12,
                  color: DesignTokens.tagInfoText,
                ),
                const SizedBox(width: DesignTokens.s4),
                Text(
                  'Estimated delivery: $expected',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.tagInfoText,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Tracking ID: ${order.trackingNumber}',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: Color(0xFF00BCFF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    height: 3,
    margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
    decoration: const BoxDecoration(
      color: Color(0xFF71717B),
      shape: BoxShape.circle,
    ),
  );
}

// ── Tracking timeline ─────────────────────────────────────────────────────────
enum _StageState { completed, ongoing, remaining }

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.status});

  final OrderTrackStatus status;

  static const _stages = [
    'Shipped',
    'In Transit',
    'Out for\nDelivery',
    'Delivered',
  ];

  // -1 means "before any of these 4 stages" — nothing here should render as
  // the active/ongoing step. preparingForShipping used to map to 0, which is
  // the *index* of the 'Shipped' stage, so a brand-new order that hadn't
  // shipped yet showed "Shipped" as its current status (confirmed live: a
  // just-placed Cash on Delivery order rendered with "Shipped" highlighted
  // green before the vendor had even confirmed it).
  int get _current => switch (status) {
    OrderTrackStatus.preparingForShipping => -1,
    OrderTrackStatus.inTransit => 1,
    OrderTrackStatus.outForDelivery => 2,
    OrderTrackStatus.delivered => 4,
    OrderTrackStatus.cancelled => -1,
  };

  _StageState _stateFor(int i) {
    if (i < _current) return _StageState.completed;
    if (i == _current) return _StageState.ongoing;
    return _StageState.remaining;
  }

  static Widget _iconForStage(int index, Color color) {
    switch (index) {
      case 0:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.inventory_2_outlined, size: 20, color: color),
            Positioned(
              bottom: -5,
              right: -7,
              child: Icon(Icons.back_hand_outlined, size: 13, color: color),
            ),
          ],
        );
      case 1:
        return Icon(Icons.local_shipping_outlined, size: 26, color: color);
      case 2:
        return Icon(Icons.airport_shuttle_rounded, size: 26, color: color);
      case 3:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.local_shipping_outlined, size: 20, color: color),
            Positioned(
              bottom: -5,
              right: -7,
              child: Icon(Icons.check_circle, size: 13, color: color),
            ),
          ],
        );
      default:
        return Icon(Icons.circle_outlined, size: 26, color: color);
    }
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _stages.length; i++) ...[
                _StageIndicator(
                  index: i,
                  state: _stateFor(i),
                  label: _stages[i],
                ),
                if (i < _stages.length - 1)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: Center(
                        child: LayoutBuilder(
                          builder: (_, c) => CustomPaint(
                            size: Size(c.maxWidth, 1.5),
                            painter: _DottedLinePainter(),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Uses Delivery's append-only Story Mode projection when a package has a
/// Style Mint tracking number, rather than guessing events from order state.
class _DeliveryStoryTimeline extends StatelessWidget {
  const _DeliveryStoryTimeline({
    required this.status,
    required this.chapters,
  });

  final OrderTrackStatus status;
  final List<DeliveryStoryChapter> chapters;

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
      _TrackingTimeline(status: status),
      const SizedBox(height: DesignTokens.s16),
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
                      color: const Color(0xFF052E16),
                      borderRadius: BorderRadius.circular(10),
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
      padding: const EdgeInsets.all(DesignTokens.s24),
      decoration: DesignTokens.cardDecoration(),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: DesignTokens.primaryGreen,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: DesignTokens.s12),
          Text('Loading live delivery tracking…'),
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
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: DesignTokens.textMuted,
            size: 32,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Live tracking is temporarily unavailable.',
            textAlign: TextAlign.center,
            style: DesignTokens.oneLinerSemibold,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Your order details are safe. Try loading the delivery journey again.',
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry live tracking'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StageIndicator extends StatelessWidget {
  const _StageIndicator({
    required this.index,
    required this.state,
    required this.label,
  });

  final int index;
  final _StageState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (state) {
      _StageState.completed => const Color(0xFF052E16),
      _StageState.ongoing => const Color(0xFF052E16),
      _StageState.remaining => DesignTokens.inputFieldFill,
    };
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            key: ValueKey('delivery-stage-icon-$index'),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: _TrackingTimeline._iconForStage(
              index,
              DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: state == _StageState.completed
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: DesignTokens.primaryGreen,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Cancelled: summary card ───────────────────────────────────────────────────
class _CancelledSummaryCard extends StatelessWidget {
  const _CancelledSummaryCard({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final placed =
        'Placed on ${DateFormat('HH:mm MMM d, yyyy').format(order.placedAt)}';
    final total = formatMoney(order.total);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/icons/OrderImage.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$placed · $total',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D1111),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Cancelled',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Tracking ID: ${order.trackingNumber}',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: Color(0xFF00BCFF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Cancelled: cancellation details card ──────────────────────────────────────
class _CancInfoCard extends StatelessWidget {
  const _CancInfoCard({required this.order});
  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final cancelledOn = DateFormat(
      'HH:mm MMM d, yyyy',
    ).format(order.placedAt.add(const Duration(days: 1)));
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s4,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cancellation Details', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          _CancInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Canceled On',
            value: cancelledOn,
          ),
          _CancInfoRow(
            icon: Icons.credit_card_outlined,
            label: 'Refund Method',
            value: order.paymentMethod,
          ),
          _CancInfoRow(
            icon: Icons.receipt_outlined,
            label: 'Amount',
            value: formatMoney(order.total),
          ),
          const _CancInfoRow(
            icon: Icons.mail_outline,
            label: 'Confirmation',
            value: 'Check your email',
          ),
          const _CancInfoRow(
            icon: Icons.label_outline,
            label: 'Refund Status',
            badge: 'Pending',
          ),
        ],
      ),
    );
  }
}

class _CancInfoRow extends StatelessWidget {
  const _CancInfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: DesignTokens.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (value != null)
            Text(
              value!,
              textAlign: TextAlign.end,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1F38),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4FC3F7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Cancelled: 3-step horizontal timeline ────────────────────────────────────
class _CancelledTimeline3 extends StatelessWidget {
  const _CancelledTimeline3();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tracking Timeline', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CancelledStep3(
                index: 0,
                label: 'Shipped',
                isCompleted: true,
              ),
              _dotConnector(),
              const _CancelledStep3(
                index: 1,
                label: 'In Transit',
                isCompleted: true,
              ),
              _dotConnector(),
              const _CancelledStep3(
                index: 2,
                label: 'Order\nCancelled',
                isCompleted: false,
                isCancelled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dotConnector() => Expanded(
    child: SizedBox(
      height: 48,
      child: Center(
        child: LayoutBuilder(
          builder: (_, c) => CustomPaint(
            size: Size(c.maxWidth, 1.5),
            painter: _CancelDotPainter(),
          ),
        ),
      ),
    ),
  );
}

class _CancelledStep3 extends StatelessWidget {
  const _CancelledStep3({
    required this.index,
    required this.label,
    required this.isCompleted,
    this.isCancelled = false,
  });

  final int index;
  final String label;
  final bool isCompleted;
  final bool isCancelled;

  static Widget _iconFor(int index, Color color) {
    switch (index) {
      case 0:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.inventory_2_outlined, size: 20, color: color),
            Positioned(
              bottom: -5,
              right: -7,
              child: Icon(Icons.back_hand_outlined, size: 13, color: color),
            ),
          ],
        );
      case 1:
        return Icon(Icons.local_shipping_outlined, size: 26, color: color);
      default:
        return Icon(Icons.cancel_outlined, size: 26, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = isCancelled
        ? const Color(0xFF3D1111)
        : const Color(0xFF052E16);
    final Color fg = isCancelled
        ? const Color(0xFFFF6B6B)
        : DesignTokens.primaryGreen;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            key: ValueKey('delivery-stage-icon-$index'),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: _iconFor(index, fg),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: isCompleted
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: DesignTokens.primaryGreen,
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cancelled: vertical order history timeline ────────────────────────────────
class _OrderHistoryTimeline extends StatelessWidget {
  const _OrderHistoryTimeline({required this.order});
  final OrderDetail order;

  List<_OrderEvt> _buildEvents() {
    final fmt = DateFormat('dd MMM, HH:mm');
    final placed = order.placedAt;
    return [
      _OrderEvt(
        icon: Icons.cancel_outlined,
        iconBg: const Color(0xFF3D1111),
        iconFg: const Color(0xFFFF6B6B),
        title: 'Order Canceled',
        isCompleted: false,
        isCancelled: true,
        subItems: [
          _SubEvt(
            text: 'The customer canceled the order',
            time: fmt.format(placed.add(const Duration(days: 1, hours: 2))),
          ),
        ],
      ),
      _OrderEvt(
        icon: Icons.local_shipping_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'In Transit',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubEvt(
            text:
                'The package has crossed the transit and is on its way to be delivered',
            time: fmt.format(
              placed.add(const Duration(days: 1, hours: 2, minutes: 15)),
            ),
          ),
          _SubEvt(
            text: 'The package is being checked in the transit',
            time: fmt.format(placed.add(const Duration(days: 1))),
          ),
        ],
      ),
      _OrderEvt(
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'Shipped',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubEvt(
            text: 'The package has been shipped',
            time: fmt.format(placed.add(const Duration(hours: 23, minutes: 5))),
          ),
          _SubEvt(
            text: 'The package is in the shipping lane',
            time: fmt.format(
              placed.add(const Duration(hours: 22, minutes: 30)),
            ),
          ),
          _SubEvt(
            text:
                'The package is being tagged with the shipping address details',
            time: fmt.format(
              placed.add(const Duration(hours: 22, minutes: 20)),
            ),
          ),
          _SubEvt(
            text: 'Order items are being gathered & packaged for shipping',
            time: fmt.format(placed.add(const Duration(hours: 21))),
          ),
        ],
      ),
      _OrderEvt(
        icon: Icons.assignment_turned_in_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'Order Confirmed',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubEvt(
            text: 'Order was confirmed',
            time: fmt.format(placed.add(const Duration(minutes: 1))),
          ),
        ],
      ),
      _OrderEvt(
        icon: Icons.shopping_bag_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'Order Placed',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubEvt(text: 'Order was placed', time: fmt.format(placed)),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s8,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _HistSection(event: events[i], isLast: i == events.length - 1),
          const SizedBox(height: DesignTokens.s4),
          const Icon(
            Icons.keyboard_arrow_up_rounded,
            size: 22,
            color: DesignTokens.textMuted,
          ),
        ],
      ),
    );
  }
}

class _HistSection extends StatelessWidget {
  const _HistSection({required this.event, required this.isLast});
  final _OrderEvt event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: event.iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(event.icon, size: 16, color: event.iconFg),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      width: 2,
                      color: DesignTokens.borderDefault,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          event.title,
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      if (event.isCompleted) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: DesignTokens.primaryGreen,
                        ),
                      ],
                      if (event.isCancelled) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.error_rounded,
                          size: 14,
                          color: Color(0xFFFF6B6B),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in event.subItems) _HistSubRow(item: item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistSubRow extends StatelessWidget {
  const _HistSubRow({required this.item});
  final _SubEvt item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: DesignTokens.dotSeparator,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.text,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.time,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderEvt {
  const _OrderEvt({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.isCompleted,
    required this.isCancelled,
    required this.subItems,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final bool isCompleted;
  final bool isCancelled;
  final List<_SubEvt> subItems;
}

class _SubEvt {
  const _SubEvt({required this.text, required this.time});
  final String text;
  final String time;
}

class _CancelDotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
            Text(
              expanded ? 'Hide Other Details' : 'View Other Details',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
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

  void _handleRequestReturn(BuildContext context) {
    showDialog<_ReturnRequestResult>(
      context: context,
      builder: (ctx) =>
          _ReturnRequestDialog(items: order.items, notifier: notifier),
    ).then((result) {
      if (result != null) {
        notifier.requestReturn(
          subOrderId: result.item.subOrderId,
          subOrderLineId: result.item.id,
          quantity: result.quantity,
          reason: result.reason,
          photoUrls: result.photoUrls,
        );
      }
    });
  }
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
    required this.onTap,
  });

  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

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
  });

  final OrderDetailItem item;
  final int quantity;
  final String reason;
  final List<String> photoUrls;
}

/// Collects everything the backend's `SubmitReturnVm` requires: which line
/// item, how many units, why, and at least one photo (skill §13.7) — a
/// bare reason string always 400s server-side.
class _ReturnRequestDialog extends StatefulWidget {
  const _ReturnRequestDialog({required this.items, required this.notifier});

  final List<OrderDetailItem> items;
  final OrderDetailNotifier notifier;

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

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.items.first;
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

  void _submit() {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a reason for the return.');
      return;
    }
    if (_photoUrls.isEmpty) {
      setState(() => _error = 'Please add at least one photo.');
      return;
    }
    Navigator.pop(
      context,
      _ReturnRequestResult(
        item: _selectedItem,
        quantity: _quantity,
        reason: _controller.text.trim(),
        photoUrls: _photoUrls,
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
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: DesignTokens.bgAppBody,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(DesignTokens.cardRadius),
                      ),
                    ),
                    builder: (_) => RateReviewSheet(
                      productId: item.productId,
                      orderId: order.id,
                    ),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2E16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.home_outlined,
                    size: 12,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Home',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                    _BillRow(
                      label: 'Subtotal',
                      value: formatMoney(order.subtotal),
                    ),
                    const SizedBox(height: 8),
                    _BillRow(
                      label: 'Shipping',
                      value: formatMoney(order.shipping),
                    ),
                    const SizedBox(height: 8),
                    _BillRow(label: 'Tax', value: formatMoney(order.tax)),
                    const Divider(
                      color: DesignTokens.borderDefault,
                      height: 24,
                    ),
                    _BillRow(
                      label: 'Grand Total',
                      value: formatMoney(order.total),
                      bold: true,
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
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: bold
              ? DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                )
              : DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
        ),
        Text(
          value,
          style: bold
              ? DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                )
              : DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
        ),
      ],
    );
  }
}
