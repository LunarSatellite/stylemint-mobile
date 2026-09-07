import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_invoice_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── CANCEL ORDER SCREEN (form) ───────────────────────────────────────────────
class CancelOrderScreen extends ConsumerStatefulWidget {
  const CancelOrderScreen({super.key, required this.orderId, this.order});

  final String orderId;
  final OrderDetail? order;

  @override
  ConsumerState<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends ConsumerState<CancelOrderScreen> {
  OrderCancellationReason? _reason;
  bool _acknowledged = false;
  final _commentCtrl = TextEditingController();

  bool get _canSubmit =>
      _reason != null &&
      _acknowledged &&
      (!_reason!.requiresNote || _commentCtrl.text.trim().isNotEmpty);

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cancelOrderControllerProvider);

    ref.listen<CancelOrderUiState>(cancelOrderControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    if (state.done) {
      return _SuccessView(
        order: widget.order,
        note: _commentCtrl.text.trim().isNotEmpty
            ? _commentCtrl.text.trim()
            : null,
      );
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Cancel Order', style: DesignTokens.sectionInnerTitle),
      ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s8,
            DesignTokens.s16, DesignTokens.s32),
        children: [
          Text('We need you to fill the details below to cancel your order',
              style: DesignTokens.bodyText),
          const SizedBox(height: DesignTokens.s24),

          Text('Why are you cancelling?', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          for (final r in OrderCancellationReason.values)
            _ReasonTile(
              label: r.label,
              selected: _reason == r,
              onTap: () => setState(() => _reason = r),
            ),
          const SizedBox(height: DesignTokens.s16),

          Text(
            _reason?.requiresNote ?? false
                ? 'Tell us more (required)'
                : 'Additional comment (optional)',
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s8),
          TextField(
            controller: _commentCtrl,
            onChanged: (_) => setState(() {}),
            maxLines: 3,
            maxLength: 500,
            style: DesignTokens.bodyText,
            cursorColor: DesignTokens.primaryGreen,
            decoration: InputDecoration(
              hintText: 'Tell us more…',
              hintStyle:
                  DesignTokens.bodyText.copyWith(color: DesignTokens.textMuted),
              filled: true,
              fillColor: DesignTokens.inputFieldFill,
              counterText: '',
              contentPadding: const EdgeInsets.all(DesignTokens.s12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide:
                    const BorderSide(color: DesignTokens.inputFieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide:
                    const BorderSide(color: DesignTokens.inputFieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                borderSide: const BorderSide(color: DesignTokens.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.warningFillDark,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFF1C40F), size: 20),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Important',
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.warningTextLight)),
                      const SizedBox(height: DesignTokens.s4),
                      Text('• Full refund to original payment',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.warningTextLight)),
                      Text('• Cancellation is final',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.warningTextLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          CheckboxListTile(
            value: _acknowledged,
            onChanged: (v) => setState(() => _acknowledged = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: DesignTokens.primaryGreen,
            title: Text(
              'I understand my refund will be issued in 5–7 business days.',
              style: DesignTokens.smallRegular,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          SmPrimaryButton(
            label: 'Proceed',
            height: DesignTokens.buttonHeight,
            borderRadius: DesignTokens.buttonRadius,
            color: DesignTokens.primaryGreen,
            labelColor: DesignTokens.buttonPrimaryText,
            disabled: !_canSubmit || state.isSubmitting,
            isLoadingInitially: state.isSubmitting,
            onPressed: () => ref
                .read(cancelOrderControllerProvider.notifier)
                .cancel(widget.orderId,
                    reason: _reason!, note: _commentCtrl.text.trim()),
          ),
        ],
        ),
      ),
    );
  }
}

// ─── REASON TILE ─────────────────────────────────────────────────────────────
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.s8),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.chipsSelectedFill
              : DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textMuted,
              size: 20,
            ),
            const SizedBox(width: DesignTokens.s12),
            Text(label, style: DesignTokens.bodyText),
          ],
        ),
      ),
    );
  }
}

// ─── SUCCESS / CANCELLED ORDER DETAIL VIEW ────────────────────────────────────
class _SuccessView extends StatefulWidget {
  const _SuccessView({required this.order, this.note});

  final OrderDetail? order;
  final String? note;

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> {
  bool _detailsExpanded = false;
  late final DateTime _cancelledAt;

  @override
  void initState() {
    super.initState();
    _cancelledAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite),
          onPressed: () => context.go(RouteNames.orders),
        ),
        title:
            const Text('Order Details', style: DesignTokens.sectionInnerTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CancelledOrderCard(order: widget.order),
            const SizedBox(height: DesignTokens.s16),
            _CancellationDetailsCard(
              order: widget.order,
              cancelledAt: _cancelledAt,
            ),
            const SizedBox(height: DesignTokens.s16),
            const _CancelledHorizontalTimeline(),
            const SizedBox(height: DesignTokens.s16),
            _VerticalTimeline(
              order: widget.order,
              cancelledAt: _cancelledAt,
              note: widget.note,
            ),
            const SizedBox(height: DesignTokens.s8),
            _ViewOtherDetailsToggle(
              expanded: _detailsExpanded,
              onTap: () =>
                  setState(() => _detailsExpanded = !_detailsExpanded),
            ),
            if (_detailsExpanded) _OtherDetailsSection(order: widget.order),
            const SizedBox(height: DesignTokens.s32),
          ],
        ),
      ),
    );
  }
}

// ─── ORDER CARD (cancelled state) ─────────────────────────────────────────────
class _CancelledOrderCard extends StatelessWidget {
  const _CancelledOrderCard({required this.order});

  final OrderDetail? order;

  @override
  Widget build(BuildContext context) {
    final placed = order != null
        ? 'Placed on ${DateFormat('HH:mm MMM d, yyyy').format(order!.placedAt)}'
        : '';
    final total = order != null ? formatMoney(order!.total) : '';

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/icons/OrderImage.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order?.orderNumber ?? '—'}',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$placed · $total',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Tracking ID: ${order?.trackingNumber ?? 'N/A'}',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: Color(0xFF00BCFF),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CANCELLATION DETAILS CARD ────────────────────────────────────────────────
class _CancellationDetailsCard extends StatelessWidget {
  const _CancellationDetailsCard({
    required this.order,
    required this.cancelledAt,
  });

  final OrderDetail? order;
  final DateTime cancelledAt;

  @override
  Widget build(BuildContext context) {
    final cancelledStr =
        DateFormat('HH:mm MMM d, yyyy').format(cancelledAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s4),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cancellation Details', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          _CancDetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Canceled On',
            value: cancelledStr,
          ),
          _CancDetailRow(
            icon: Icons.credit_card_outlined,
            label: 'Refund Method',
            value: order?.paymentMethod ?? '—',
          ),
          _CancDetailRow(
            icon: Icons.receipt_outlined,
            label: 'Amount',
            value: order != null ? formatMoney(order!.total) : '—',
          ),
          _CancDetailRow(
            icon: Icons.mail_outline,
            label: 'Confirmation',
            value: 'Check your email',
          ),
          _CancDetailRow(
            icon: Icons.label_outline,
            label: 'Refund Status',
            badge: 'Pending',
          ),
        ],
      ),
    );
  }
}

class _CancDetailRow extends StatelessWidget {
  const _CancDetailRow({
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
        children: [
          Icon(icon, size: 14, color: DesignTokens.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted),
            ),
          ),
          if (value != null)
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.end,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (badge != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

// ─── HORIZONTAL 3-STEP CANCELLED TIMELINE ────────────────────────────────────
class _CancelledHorizontalTimeline extends StatelessWidget {
  const _CancelledHorizontalTimeline();

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
              const _CancelledStage(index: 0, label: 'Shipped', isCompleted: true),
              _connector(),
              const _CancelledStage(index: 1, label: 'In Transit', isCompleted: true),
              _connector(),
              const _CancelledStage(
                  index: 2, label: 'Order\nCancelled', isCompleted: false, isCancelled: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _connector() => Expanded(
        child: SizedBox(
          height: 48,
          child: Center(
            child: LayoutBuilder(
              builder: (_, c) => CustomPaint(
                size: Size(c.maxWidth, 1.5),
                painter: _DotLinePainter(),
              ),
            ),
          ),
        ),
      );
}

class _CancelledStage extends StatelessWidget {
  const _CancelledStage({
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: _iconFor(index, fg),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: isCompleted
                ? const Icon(Icons.check_circle_rounded,
                    size: 14, color: DesignTokens.primaryGreen)
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

// ─── VERTICAL ORDER HISTORY TIMELINE ─────────────────────────────────────────
class _VerticalTimeline extends StatelessWidget {
  const _VerticalTimeline({
    required this.order,
    required this.cancelledAt,
    this.note,
  });

  final OrderDetail? order;
  final DateTime cancelledAt;
  final String? note;

  List<_OrderEvent> _buildEvents() {
    final fmt = DateFormat('dd MMM, HH:mm');
    final placed = order?.placedAt ??
        cancelledAt.subtract(const Duration(days: 3));

    return [
      _OrderEvent(
        icon: Icons.cancel_outlined,
        iconBg: const Color(0xFF3D1111),
        iconFg: const Color(0xFFFF6B6B),
        title: 'Order Canceled',
        isCompleted: false,
        isCancelled: true,
        subItems: [
          _SubItem(
            text: (note != null && note!.isNotEmpty)
                ? note!
                : 'The customer canceled the order',
            time: fmt.format(cancelledAt),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.local_shipping_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'In Transit',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubItem(
            text: 'The package has crossed the transit and is on its way to be delivered',
            time: fmt.format(
                placed.add(const Duration(days: 2, hours: 2, minutes: 15))),
          ),
          _SubItem(
            text: 'The package is being checked in the transit',
            time: fmt.format(placed.add(const Duration(days: 2))),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'Shipped',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubItem(
            text: 'The package has been shipped',
            time: fmt.format(
                placed.add(const Duration(hours: 23, minutes: 5))),
          ),
          _SubItem(
            text: 'The package is in the shipping lane',
            time: fmt.format(
                placed.add(const Duration(hours: 22, minutes: 30))),
          ),
          _SubItem(
            text: 'The package is being tagged with the shipping address details',
            time: fmt.format(
                placed.add(const Duration(hours: 22, minutes: 20))),
          ),
          _SubItem(
            text: 'Order items are being gathered & packaged for shipping',
            time: fmt.format(placed.add(const Duration(hours: 21))),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.assignment_turned_in_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'Order Confirmed',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubItem(
            text: 'Order was confirmed',
            time: fmt.format(placed.add(const Duration(minutes: 1))),
          ),
        ],
      ),
      _OrderEvent(
        icon: Icons.shopping_bag_outlined,
        iconBg: const Color(0xFF052E16),
        iconFg: DesignTokens.primaryGreen,
        title: 'Order Placed',
        isCompleted: true,
        isCancelled: false,
        subItems: [
          _SubItem(
            text: 'Order was placed',
            time: fmt.format(placed),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final events = _buildEvents();
    return Container(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s8),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < events.length; i++)
            _Section(event: events[i], isLast: i == events.length - 1),
          const SizedBox(height: DesignTokens.s4),
          const Icon(Icons.keyboard_arrow_up_rounded,
              size: 22, color: DesignTokens.textMuted),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.event, required this.isLast});

  final _OrderEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: icon circle + connector line
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
          // Right: title + sub-events
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.textWhite),
                        ),
                      ),
                      if (event.isCompleted)
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: DesignTokens.primaryGreen),
                      if (event.isCancelled)
                        const Icon(Icons.error_rounded,
                            size: 14, color: Color(0xFFFF6B6B)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in event.subItems) _SubItemRow(item: item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubItemRow extends StatelessWidget {
  const _SubItemRow({required this.item});

  final _SubItem item;

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
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.time,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── VIEW / HIDE OTHER DETAILS TOGGLE ────────────────────────────────────────
class _ViewOtherDetailsToggle extends StatelessWidget {
  const _ViewOtherDetailsToggle(
      {required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
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
              expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              size: 16,
              color: DesignTokens.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── OTHER DETAILS SECTION (4 tiles) ─────────────────────────────────────────
class _OtherDetailsSection extends StatelessWidget {
  const _OtherDetailsSection({required this.order});

  final OrderDetail? order;

  @override
  Widget build(BuildContext context) {
    final itemCount = order?.items.length ?? 0;
    final total = order != null ? formatMoney(order!.total) : '';

    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          _OtherDetailsTile(
            icon: Icons.location_on_outlined,
            title: 'Shipping Address',
            subtitle: order?.shippingAddress ?? 'Not available',
          ),
          const _TileDivider(),
          _OtherDetailsTile(
            icon: Icons.inventory_2_outlined,
            title: 'Order Summary',
            subtitle: '$itemCount item${itemCount == 1 ? '' : 's'} · $total Total',
          ),
          const _TileDivider(),
          _OtherDetailsTile(
            icon: Icons.receipt_long_outlined,
            title: 'View Invoice',
            subtitle: 'Your invoice for the order',
            onTap: order == null
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OrderInvoiceScreen(order: order!),
                      ),
                    ),
          ),
          const _TileDivider(),
          _OtherDetailsTile(
            icon: Icons.headset_mic_outlined,
            title: 'Contact Support',
            subtitle: 'Have any queries? We are here to help',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ContactSupportScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtherDetailsTile extends StatelessWidget {
  const _OtherDetailsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: DesignTokens.textMuted),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.textWhite),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.iconLight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: DesignTokens.borderDefault,
      indent: DesignTokens.s16,
      endIndent: DesignTokens.s16,
    );
  }
}

// ─── DATA MODELS ─────────────────────────────────────────────────────────────
class _OrderEvent {
  const _OrderEvent({
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
  final List<_SubItem> subItems;
}

class _SubItem {
  const _SubItem({required this.text, required this.time});

  final String text;
  final String time;
}

// ─── DOTTED LINE PAINTER ─────────────────────────────────────────────────────
class _DotLinePainter extends CustomPainter {
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
