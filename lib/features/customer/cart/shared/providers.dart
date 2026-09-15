import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/repositories/cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
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

  static int? _settledCount(CartState state) => state.maybeWhen(
    initial: () => 0,
    loadSuccess: (cart) =>
        cart.items.fold<int>(0, (sum, item) => sum + item.quantity),
    orElse: () => null,
  );
}

/// Best-effort basket insights card. A failure here should never block
/// the cart screen — watch via `.asData?.value`.
final basketOptimizationProvider = FutureProvider.autoDispose<BasketOptimization?>((ref) async {
  final result = await ref.watch(cartRepositoryProvider).getBasketOptimization();
  return result.fold((_) => null, (opt) => opt);
});

/// "Try other baskets" — autoDispose so reopening the screen builds fresh
/// options for the cart as it is now.
final basketScenariosNotifierProvider =
    StateNotifierProvider.autoDispose<
      BasketScenariosNotifier,
      BasketScenariosState
    >((ref) => BasketScenariosNotifier(ref.watch(cartRepositoryProvider)));
