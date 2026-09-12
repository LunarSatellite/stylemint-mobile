import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/datasources/cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/repositories/cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
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

/// Best-effort basket insights card. A failure here should never block
/// the cart screen — watch via `.asData?.value`.
final basketOptimizationProvider = FutureProvider.autoDispose<BasketOptimization?>((ref) async {
  final result = await ref.watch(cartRepositoryProvider).getBasketOptimization();
  return result.fold((_) => null, (opt) => opt);
});
