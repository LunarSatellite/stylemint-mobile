import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Cancel Order flow — reason selection + final confirmation + success.
/// Pixel-matched to `Cancel Order - Step 2/Confirmation Step 3/Successful.pdf`
/// (Customer User). Reuses [OrdersRepository.cancelOrder].
class CancelOrderScreen extends ConsumerStatefulWidget {
  const CancelOrderScreen({super.key, required this.orderId, this.order});

  final String orderId;
  final OrderDetail? order;

  @override
  ConsumerState<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends ConsumerState<CancelOrderScreen> {
  static const _reasons = [
    'Found better price',
    'Changed my mind',
    'Ordered by mistake',
    'Other reason',
  ];

  String? _reason;
  final _commentCtrl = TextEditingController();

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
      return _SuccessView(order: widget.order);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s8,
            DesignTokens.s16, DesignTokens.s32),
        children: [
          Text('We need you to fill the details below to cancel your order.',
              style: DesignTokens.bodyText),
          const SizedBox(height: DesignTokens.s24),

          Text('Why are you cancelling?', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          for (final r in _reasons)
            _ReasonTile(
              label: r,
              selected: _reason == r,
              onTap: () => setState(() => _reason = r),
            ),
          const SizedBox(height: DesignTokens.s16),

          Text('Additional comment (optional)',
              style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s8),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 300,
            style: DesignTokens.bodyText,
            cursorColor: DesignTokens.primaryGreen,
            decoration: InputDecoration(
              hintText: 'Tell us more…',
              hintStyle: DesignTokens.bodyText
                  .copyWith(color: DesignTokens.textMuted),
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

          // Important notice (Fill/Info/Dark).
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.infoFillDark,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: DesignTokens.infoIconLight, size: 20),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cancellation is final',
                          style: DesignTokens.mediumSemibold
                              .copyWith(color: DesignTokens.infoTextLight)),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        'You cannot undo the cancellation after this. A full '
                        'refund will be issued to your original payment method.',
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.infoTextLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s32),

          SmPrimaryButton(
            label: 'Confirm Cancellation',
            height: DesignTokens.buttonHeight,
            borderRadius: DesignTokens.buttonRadius,
            color: DesignTokens.colorError,
            labelColor: DesignTokens.textWhite,
            disabled: _reason == null || state.isSubmitting,
            isLoadingInitially: state.isSubmitting,
            onPressed: () => ref
                .read(cancelOrderControllerProvider.notifier)
                .cancel(widget.orderId,
                    reason: _reason, comment: _commentCtrl.text.trim()),
          ),
        ],
      ),
    );
  }
}

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
              color:
                  selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
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

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.order});

  final OrderDetail? order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            children: [
              const SizedBox(height: DesignTokens.s32),
              const Icon(Icons.check_circle_outline,
                  size: 64, color: DesignTokens.primaryGreen),
              const SizedBox(height: DesignTokens.s16),
              Text('Order Canceled Successfully',
                  textAlign: TextAlign.center, style: DesignTokens.titleLarge),
              if (order != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text('Order #${order!.orderNumber}',
                    style: DesignTokens.bodyText),
              ],
              const SizedBox(height: DesignTokens.s24),
              Container(
                padding: const EdgeInsets.all(DesignTokens.s16),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Refund Details', style: DesignTokens.mediumSemibold),
                    const SizedBox(height: DesignTokens.s12),
                    if (order != null)
                      _kv('Amount', formatMoney(order!.total)),
                    const SizedBox(height: DesignTokens.s8),
                    _kv('Refund window', '5–7 business days'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'View My Orders',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  onPressed: () async => context.go(RouteNames.orders),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k,
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textLight)),
          Text(v, style: DesignTokens.mediumSemibold),
        ],
      );
}
