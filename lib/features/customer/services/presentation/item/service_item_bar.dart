import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_choice.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/service_cart_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// The item page's purchase bar for a stay or trip: the price for what is
/// chosen (total, and what is paid now), Add to cart and Buy now. Both stay
/// off until the server has priced the choice as available.
///
/// Adding sends the choice as the cart line's `serviceOptions` (service
/// cart contract v1 §2.1); nothing is held until checkout starts. Opened from
/// a cart line ([replaceLineId]), the new line replaces that one — a
/// service line's options cannot change once added.
class ServiceItemBar extends ConsumerStatefulWidget {
  const ServiceItemBar({
    required this.productId,
    required this.choice,
    this.variantId,
    this.replaceLineId,
    this.reelTagContextId,
    super.key,
  });

  final String productId;
  final String? variantId;
  final ServiceChoice choice;
  final String? replaceLineId;

  /// The reel tag the page was opened from, for the creator's credit.
  final String? reelTagContextId;

  static const Key addKey = Key('service-item-add-to-cart');
  static const Key buyKey = Key('service-item-buy-now');
  static const Key summaryKey = Key('service-item-bar-summary');

  @override
  ConsumerState<ServiceItemBar> createState() => _ServiceItemBarState();
}

class _ServiceItemBarState extends ConsumerState<ServiceItemBar> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.choice.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant ServiceItemBar old) {
    super.didUpdateWidget(old);
    if (old.choice != widget.choice) {
      old.choice.removeListener(_rebuild);
      widget.choice.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.choice.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// Add to cart ([thenCart] false) or Buy now ([thenCart] true). Buy now
  /// opens the cart, never checkout, and adds the booking only when the
  /// cart does not already hold exactly this choice.
  Future<void> _add({required bool thenCart}) async {
    final options = widget.choice.toOptions();
    if (options == null) return;
    if (!await servicesEnsureAuth(context, ref) || !mounted) return;
    if (thenCart && widget.replaceLineId == null) {
      final inCart = ref
          .read(cartNotifierProvider)
          .maybeWhen(
            loadSuccess: (cart) =>
                cart.serviceLineFor(widget.productId, options) != null,
            orElse: () => false,
          );
      if (inCart) {
        unawaited(context.push(RouteNames.cart));
        return;
      }
    }
    setState(() => _busy = true);
    final result = await ref
        .read(serviceCartRepositoryProvider)
        .addToCart(
          productId: widget.productId,
          variantId: widget.variantId,
          reelTagContextId: widget.reelTagContextId,
          options: options,
          // One key per tap: a retry after a timeout is the same add.
          idempotencyKey: const Uuid().v4(),
        );
    if (!mounted) return;
    await result.fold(
      (failure) async {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(serviceFailureMessage(failure, what: 'this booking')),
            backgroundColor: DesignTokens.colorError,
          ),
        );
      },
      (cart) async {
        final cartNotifier = ref.read(cartNotifierProvider.notifier)
          ..showCart(cart);
        final replaced = widget.replaceLineId;
        if (replaced != null && cart.items.any((i) => i.id == replaced)) {
          await cartNotifier.removeItem(replaced);
        }
        if (!mounted) return;
        setState(() => _busy = false);
        if (thenCart) {
          unawaited(context.push(RouteNames.cart));
        } else if (replaced != null) {
          // Back to the cart the buyer came from, with the new choice.
          if (context.canPop()) context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to cart'),
              backgroundColor: DesignTokens.primaryGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final choice = widget.choice;
    final quote = choice.quote;
    final option = choice.paymentOption;
    final ready = choice.canAdd && !_busy;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final summary = quote == null || !quote.available
        ? (choice.isComplete
              ? (choice.quoting ? 'Checking availability…' : null)
              : choice.isStay
              ? 'Choose dates and a room'
              : 'Choose a departure')
        : option == null
        ? 'Total ${serviceMoney(quote.totalPrice)}'
        : 'Total ${serviceMoney(quote.totalPrice)} · '
              '${serviceMoney(option.payNow)} now'
              '${option.payAtVenue.amount > 0 ? ' · ${serviceMoney(option.payAtVenue)} at the venue' : ''}';
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s12 + bottomPad,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: DesignTokens.glassStroke),
        boxShadow: DesignTokens.shadowLifted,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary != null) ...[
            Text(
              summary,
              key: ServiceItemBar.summaryKey,
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ServiceItemBar.addKey,
                  onPressed: ready
                      ? () => unawaited(_add(thenCart: false))
                      : null,
                  style: DesignTokens.outlinedButtonStyle(),
                  child: Text(
                    widget.replaceLineId == null ? 'Add to Cart' : 'Update cart',
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: ElevatedButton(
                  key: ServiceItemBar.buyKey,
                  onPressed: ready
                      ? () => unawaited(_add(thenCart: true))
                      : null,
                  style: DesignTokens.primaryButtonStyle(),
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Buy Now',
                          style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The item page's bar for a bank product: Enquire, and Book appointment
/// when a branch takes them. Both forms ask for consent naming the bank
/// before anything is shared (banks contract v1). Never Add to cart.
class BankItemBar extends ConsumerWidget {
  const BankItemBar({required this.productId, required this.bank, super.key});

  /// The item's product id — the bank product id (service items contract v1
  /// §1).
  final String productId;
  final BankItem bank;

  static const Key enquireKey = Key('bank-item-enquire');
  static const Key appointmentKey = Key('bank-item-appointment');

  Future<void> _open(BuildContext context, WidgetRef ref, String path) async {
    if (await servicesEnsureAuth(context, ref) && context.mounted) {
      unawaited(context.push(path));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final productId = bank.product?.id ?? this.productId;
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s12 + bottomPad,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: DesignTokens.glassStroke),
        boxShadow: DesignTokens.shadowLifted,
      ),
      child: Row(
        children: [
          if (bank.takesAppointments) ...[
            Expanded(
              child: OutlinedButton(
                key: appointmentKey,
                style: DesignTokens.outlinedButtonStyle(),
                onPressed: () => unawaited(
                  _open(
                    context,
                    ref,
                    RouteNames.bankAppointmentFormPath(
                      bank.bankId,
                      productId: productId,
                    ),
                  ),
                ),
                child: Text(
                  'Book appointment',
                  style: DesignTokens.mediumSemibold,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
          ],
          Expanded(
            child: ElevatedButton(
              key: enquireKey,
              style: DesignTokens.primaryButtonStyle(),
              onPressed: () => unawaited(
                _open(context, ref, RouteNames.bankEnquiryFormPath(productId)),
              ),
              child: Text(
                'Enquire',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.buttonPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
