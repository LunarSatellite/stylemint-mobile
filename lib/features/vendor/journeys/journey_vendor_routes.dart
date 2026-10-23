import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/create_journey_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/vendor_journey_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/vendor_journeys_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_routes.dart';

/// The seller app's journey routes, spread into the app router. `new` is
/// listed before `:journeyId` so it is not read as an id.
final List<RouteBase> vendorJourneyRoutes = <RouteBase>[
  GoRoute(
    path: JourneyRoutes.list,
    builder: (ctx, state) => const VendorJourneysScreen(),
  ),
  GoRoute(
    path: JourneyRoutes.create,
    builder: (ctx, state) => const CreateJourneyScreen(),
  ),
  GoRoute(
    path: JourneyRoutes.detail,
    builder: (ctx, state) => VendorJourneyDetailScreen(
      journeyId: state.pathParameters['journeyId']!,
    ),
  ),
];
