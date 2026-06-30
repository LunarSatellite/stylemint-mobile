import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/mock_cart_repository.dart';

// Using MockCartRepository for development/demo (in-memory, no API needed).
// To restore the real network implementation, replace the body below with:
//
//   CartRepositoryImpl(
//     remoteDataSource: ref.watch(cartRemoteDataSourceProvider),
//     networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
//   )
//
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => MockCartRepository(),
);

final cartNotifierProvider =
    StateNotifierProvider<CartNotifier, CartState>(
      (ref) => CartNotifier(ref.watch(cartRepositoryProvider)),
    );
