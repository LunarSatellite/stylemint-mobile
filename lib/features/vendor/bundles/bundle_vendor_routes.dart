import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/presentation/vendor_bundle_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/presentation/vendor_bundles_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/shared/vendor_bundle_routes.dart';

/// The seller app's bundle routes, spread into the app router.
final List<RouteBase> vendorBundleRoutes = <RouteBase>[
  GoRoute(
    path: VendorBundleRoutes.list,
    builder: (ctx, state) => const VendorBundlesScreen(),
  ),
  GoRoute(
    path: VendorBundleRoutes.detail,
    builder: (ctx, state) => VendorBundleDetailScreen(
      bundleId: state.pathParameters['bundleId']!,
    ),
  ),
];
