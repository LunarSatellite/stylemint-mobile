import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_routes.dart';

/// The buyer's bundle routes, spread into the app router.
final List<RouteBase> bundleCustomerRoutes = <RouteBase>[
  GoRoute(
    path: BundleRoutes.detail,
    builder: (ctx, state) => BundleScreen(
      bundleId: state.pathParameters['bundleId']!,
      taggedBundleId: state.uri.queryParameters[BundleRoutes.tagParam],
      affiliateCode: state.uri.queryParameters[BundleRoutes.refParam],
    ),
  ),
];
