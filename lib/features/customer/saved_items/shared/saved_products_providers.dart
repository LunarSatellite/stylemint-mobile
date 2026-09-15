import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_for_later_api.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_products_notifier.dart';

final savedForLaterApiProvider = Provider<SavedForLaterApi>(
  (ref) => SavedForLaterRemoteApi(ref.watch(apiClientProvider)),
);

/// Whether the viewer is signed in; the saved list is only read then.
///
/// Follows the session only once the app has started it: building it here
/// would pull its whole graph (profile, cart) into every screen with a heart.
/// `toggleSavedProduct` re-checks after a sign-in.
final savedProductsSignedInProvider = Provider<bool>((ref) {
  if (!ref.exists(sessionControllerProvider)) return false;
  return ref.watch(
    sessionControllerProvider.select((session) => session.isAuthenticated),
  );
});

/// The default variant of a product, from its public detail.
final savedProductsVariantResolverProvider = Provider<DefaultVariantResolver>(
  (ref) => (productId) async {
    final result = await ref
        .read(discoveryRepositoryProvider)
        .getProductDetail(productId);
    return result.fold((_) => null, (product) => product.defaultVariantId);
  },
);

/// One saved-products state for every save heart in the app.
final savedProductsNotifierProvider =
    StateNotifierProvider<SavedProductsNotifier, SavedProductsState>(
      (ref) => SavedProductsNotifier(
        () => ref.read(savedForLaterApiProvider),
        signedIn: ref.watch(savedProductsSignedInProvider),
        resolveDefaultVariant: (productId) =>
            ref.read(savedProductsVariantResolverProvider)(productId),
      ),
    );
