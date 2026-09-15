import 'package:flutter/widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/discover_page.dart';

/// The Discover tab (`/search`). Its body is [DiscoverPage]; full results
/// stay on `/search-results`.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const DiscoverPage();
}
