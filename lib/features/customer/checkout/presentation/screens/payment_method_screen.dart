// This file intentionally contains only PaymentMethodScreen.
// All checkout logic lives in checkout_screen.dart.
// The previous version of this file incorrectly duplicated CheckoutScreen here.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Standalone screen for selecting a payment method.
/// Navigated to via GoRouter at `${RouteNames.checkout}/payment-method`.
/// On selection, pops with the chosen [PaymentMethod].
class PaymentMethodScreen extends ConsumerWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Payment Method',
            style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: state.maybeWhen(
        loadSuccess: (summary, _) => _MethodList(
          methods: _buildMethods(summary),
          selectedId: summary.paymentMethod.id,
          onSelect: (method) => context.pop(method),
        ),
        orElse: () => state.maybeWhen(
          loadFailure: (failure, _) => SmErrorView(
            message: 'Failed to load payment methods.',
            onRetry: () =>
                ref.read(checkoutNotifierProvider.notifier).load(),
          ),
          orElse: () => const Center(
            child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen),
          ),
        ),
      ),
    );
  }

  List<PaymentMethod> _buildMethods(CheckoutSummary summary) {
    PaymentMethod? savedCard;
    for (final method in summary.availablePaymentMethods) {
      if (method.type == PaymentMethodType.card) {
        savedCard = method;
        break;
      }
    }
    return checkoutPaymentMethods(savedCard: savedCard);
  }
}

// ─── METHOD LIST ──────────────────────────────────────────────────────────────
class _MethodList extends StatefulWidget {
  const _MethodList({
    required this.methods,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PaymentMethod> methods;
  final String selectedId;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  State<_MethodList> createState() => _MethodListState();
}

class _MethodListState extends State<_MethodList> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              Container(
                decoration: DesignTokens.cardDecoration(),
                child: Column(
                  children: List.generate(widget.methods.length, (i) {
                    final method = widget.methods[i];
                    final isSelected = _selectedId == method.id;
                    final isLast = i == widget.methods.length - 1;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() => _selectedId = method.id);
                            widget.onSelect(method);
                          },
                          borderRadius: BorderRadius.circular(
                              DesignTokens.cardRadius),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.s16,
                                vertical: DesignTokens.s12),
                            child: Row(
                              children: [
                                _PaymentIcon(type: method.type),
                                const SizedBox(width: DesignTokens.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        method.label,
                                        style: DesignTokens.oneLinerSemibold
                                            .copyWith(
                                            color:
                                            DesignTokens.textWhite),
                                      ),
                                      Text(
                                        _subtitle(method),
                                        style: DesignTokens.smallRegular
                                            .copyWith(
                                            color:
                                            DesignTokens.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                // Radio circle
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? DesignTokens.primaryGreen
                                          : DesignTokens.borderDefault,
                                      width: isSelected ? 5 : 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: DesignTokens.borderDefault,
                            indent: DesignTokens.s16,
                            endIndent: DesignTokens.s16,
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _subtitle(PaymentMethod m) {
    switch (m.type) {
      case PaymentMethodType.card:
        return m.lastFour != null
            ? 'Visa ending in ${m.lastFour}'
            : 'Credit / Debit card';
      case PaymentMethodType.eSewa:
        return 'eSewa wallet';
      case PaymentMethodType.cod:
        return 'Pay on delivery';
      case PaymentMethodType.paypal:
        return 'PayPal';
    }
  }
}

// ─── PAYMENT ICON ─────────────────────────────────────────────────────────────
class _PaymentIcon extends StatelessWidget {
  const _PaymentIcon({required this.type});

  final PaymentMethodType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      alignment: Alignment.center,
      child: _logo(),
    );
  }

  Widget _logo() {
    switch (type) {
      case PaymentMethodType.card:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Color(0xFF1A1F71),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        );
      case PaymentMethodType.eSewa:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'e-',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        );
      case PaymentMethodType.cod:
        return const Icon(
          Icons.payments_outlined,
          color: Color(0xFF4CAF50),
          size: 24,
        );
      case PaymentMethodType.paypal:
        return const Icon(
          Icons.payment_rounded,
          color: Color(0xFF003087),
          size: 24,
        );
    }
  }
}
