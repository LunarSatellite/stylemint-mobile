import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/checkout/checkout_service_guests.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The words for a checkout failure about stays and trips (service cart
/// contract v1 §6 `checkout.service_*`), or null for any other failure —
/// those keep the checkout's own message.
String? checkoutServiceMessage(NetworkExceptions failure) {
  final code = failure.validationCode;
  if (code == null || !code.startsWith('checkout.service')) return null;
  return serviceFailureMessage(
    ServiceFailure(ServiceFailureKind.rejected, code: code),
  );
}

/// Per cart line id, why a stay or trip could not be held or placed — the
/// `errors[]` of `checkout.service_unavailable` (field = cart line id, code =
/// the reason), or the one line `checkout.service_guests_required` names.
Map<String, String> checkoutServiceLineErrors(NetworkExceptions failure) =>
    failure.maybeWhen(
      validation: (code, message, field, errors) {
        if (!code.startsWith('checkout.service')) return const {};
        if (errors.isNotEmpty) {
          return serviceLineErrors([
            for (final e in errors)
              (field: e.field, code: e.code, message: e.message),
          ]);
        }
        if (field != null && field.isNotEmpty) {
          return {
            field:
                checkoutServiceMessage(failure) ??
                message ??
                'Check this booking.',
          };
        }
        return const {};
      },
      orElse: () => const {},
    );

/// Checkout could not start: a stay or trip in the cart was taken since it
/// was added (§3.1). Names each one, and sends the buyer back to the cart to
/// remove it — nothing is held and nothing is charged.
class CheckoutServiceUnavailable extends ConsumerWidget {
  const CheckoutServiceUnavailable({
    required this.failure,
    required this.onBackToCart,
    required this.onRetry,
    super.key,
  });

  final NetworkExceptions failure;
  final VoidCallback onBackToCart;
  final VoidCallback onRetry;

  static const Key viewKey = Key('checkout-service-unavailable');
  static Key lineKey(String lineId) => Key('checkout-unavailable-$lineId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errors = checkoutServiceLineErrors(failure);
    final names = ref
        .watch(cartNotifierProvider)
        .maybeWhen(
          loadSuccess: (cart) => {
            for (final i in cart.items) i.id: i.productName,
          },
          orElse: () => const <String, String>{},
        );
    return ListView(
      key: viewKey,
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        const Icon(
          Icons.event_busy_outlined,
          size: 40,
          color: DesignTokens.colorWarning,
        ),
        const SizedBox(height: DesignTokens.s12),
        Text(
          checkoutServiceMessage(failure) ??
              'Some bookings in your cart are no longer available.',
          textAlign: TextAlign.center,
          style: DesignTokens.mediumSemibold,
        ),
        const SizedBox(height: DesignTokens.s16),
        for (final e in errors.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Text(
              '${names[e.key] ?? 'A booking'}: ${e.value}',
              key: lineKey(e.key),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        const SizedBox(height: DesignTokens.s16),
        FilledButton(
          onPressed: onBackToCart,
          child: const Text('Back to cart'),
        ),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
