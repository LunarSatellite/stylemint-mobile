import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_cancellation_reason.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_invoice_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/cancelled_order_views.dart';
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
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Cancel Order',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s32,
          ),
          children: [
            Text(
              'We need you to fill the details below to cancel your order',
              style: DesignTokens.bodyText,
            ),
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
                hintStyle: DesignTokens.bodyText.copyWith(
                  color: DesignTokens.textMuted,
                ),
                filled: true,
                fillColor: DesignTokens.inputFieldFill,
                counterText: '',
                contentPadding: const EdgeInsets.all(DesignTokens.s12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: const BorderSide(
                    color: DesignTokens.inputFieldBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: const BorderSide(
                    color: DesignTokens.inputFieldBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: const BorderSide(
                    color: DesignTokens.primaryGreen,
                  ),
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
                  const Icon(
                    Icons.info_outline,
                    color: DesignTokens.warning300,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.warningTextLight,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          '• Full refund to original payment',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.warningTextLight,
                          ),
                        ),
                        Text(
                          '• Cancellation is final',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.warningTextLight,
                          ),
                        ),
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
                  .cancel(
                    widget.orderId,
                    reason: _reason!,
                    note: _commentCtrl.text.trim(),
                  ),
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.go(RouteNames.orders),
        ),
        title: const Text(
          'Order Details',
          style: DesignTokens.sectionInnerTitle,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CancelledOrderSummary(order: widget.order),
            const SizedBox(height: DesignTokens.s16),
            CancellationDetailsCard(
              order: widget.order,
              cancelledAt: _cancelledAt,
            ),
            const SizedBox(height: DesignTokens.s16),
            const CancelledTrackingStepper(),
            const SizedBox(height: DesignTokens.s16),
            CancelledOrderHistory(
              order: widget.order,
              cancelledAt: _cancelledAt,
              note: widget.note,
            ),
            const SizedBox(height: DesignTokens.s8),
            _ViewOtherDetailsToggle(
              expanded: _detailsExpanded,
              onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
            ),
            if (_detailsExpanded) _OtherDetailsSection(order: widget.order),
            const SizedBox(height: DesignTokens.s32),
          ],
        ),
      ),
    );
  }
}

// ─── VIEW / HIDE OTHER DETAILS TOGGLE ────────────────────────────────────────
class _ViewOtherDetailsToggle extends StatelessWidget {
  const _ViewOtherDetailsToggle({required this.expanded, required this.onTap});

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
            subtitle:
                '$itemCount item${itemCount == 1 ? '' : 's'} · $total Total',
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
          horizontal: DesignTokens.s16,
          vertical: 14,
        ),
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
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
