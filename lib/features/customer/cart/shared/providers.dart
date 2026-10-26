import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/repositories/cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/basket_scenarios_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';

final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>(
  (ref) => CartRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(
    remoteDataSource: ref.watch(cartRemoteDataSourceProvider),
  ),
);

final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(ref.watch(cartRepositoryProvider)),
);

/// Units in the cart, for count badges (the bottom bar's Cart tab).
final cartItemCountProvider = NotifierProvider<CartItemCountNotifier, int>(
  CartItemCountNotifier.new,
);

/// Holds the last settled count while a cart request is in flight or has
/// failed, so an add reads as the count rising instead of flashing to 0.
class CartItemCountNotifier extends Notifier<int> {
  @override
  int build() {
    ref.listen<CartState>(cartNotifierProvider, (_, next) {
      final count = _settledCount(next);
      if (count != null) state = count;
    });
    return _settledCount(ref.read(cartNotifierProvider)) ?? 0;
  }

  /// Adopts a count an API told us authoritatively — the shopping
  /// assistant's `cart-additions` returns the new total, and the badge should
  /// move the moment it lands rather than after the cart round-trips.
  void observeExternalCount(int count) {
    if (count >= 0) state = count;
  }

  static int? _settledCount(CartState state) => state.maybeWhen(
    initial: () => 0,
    loadSuccess: (cart) =>
        cart.items.fold<int>(0, (sum, item) => sum + item.quantity),
    orElse: () => null,
  );
}

/// The cart as last loaded, for controls that show what is in it — the
/// product page's in-cart counter. Like [cartItemCountProvider] it holds the
/// last settled cart while a request is in flight or has failed, so a
/// counter does not flash back to "Add to cart" mid-change. Null until the
/// cart has loaded, and again after a sign-out resets it.
final settledCartProvider = NotifierProvider<SettledCartNotifier, Cart?>(
  SettledCartNotifier.new,
);

class SettledCartNotifier extends Notifier<Cart?> {
  @override
  Cart? build() {
    ref.listen<CartState>(cartNotifierProvider, (_, next) {
      next.maybeWhen<void>(
        initial: () {
          state = null;
        },
        loadSuccess: (cart) {
          state = cart;
        },
        orElse: () {},
      );
    });
    return ref
        .read(cartNotifierProvider)
        .maybeWhen(loadSuccess: (cart) => cart, orElse: () => null);
  }

  /// Puts back the cart from before a change the server refused. The cart
  /// notifier showed that change optimistically, and the caller refetches
  /// right after, which replaces this with the server's cart.
  void restore(Cart? cart) => state = cart;
}

/// Best-effort basket insights card. A failure here should never block
/// the cart screen — watch via `.asData?.value`.
final basketOptimizationProvider =
    FutureProvider.autoDispose<BasketOptimization?>((ref) async {
      final result = await ref
          .watch(cartRepositoryProvider)
          .getBasketOptimization();
      return result.fold((_) => null, (opt) => opt);
    });

/// Transparent, policy-governed value choices for the current cart.
final cartOfferAdviceProvider = FutureProvider.autoDispose<CartOfferAdvice?>((
  ref,
) async {
  final result = await ref.watch(cartRepositoryProvider).getOfferAdvice();
  return result.fold((_) => null, (advice) => advice);
});

/// "Try other baskets" — autoDispose so reopening the screen builds fresh
/// options for the cart as it is now.
final basketScenariosNotifierProvider =
    StateNotifierProvider.autoDispose<
      BasketScenariosNotifier,
      BasketScenariosState
    >((ref) => BasketScenariosNotifier(ref.watch(cartRepositoryProvider)));
