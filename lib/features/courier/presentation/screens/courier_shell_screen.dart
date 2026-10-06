import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_balance_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_dashboard_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_profile_screen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_bottom_nav_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_nav_icons.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The delivery partner's app: Home, Balance, Profile.
///
/// Tabs rather than a single scrolling dashboard with links, so the surface
/// reads like the rest of the app — the customer, creator and vendor sides all
/// sit on [SmBottomNavBar], and a courier arriving from any of them should not
/// find a different shape of app.
///
/// [IndexedStack] rather than swapping the child: the Home tab holds a map
/// whose camera the rider has panned and a work list they have scrolled, and
/// rebuilding those on every tab change would throw both away.
class CourierShellScreen extends ConsumerStatefulWidget {
  const CourierShellScreen({required this.profile, super.key});

  final CourierProfile profile;

  @override
  ConsumerState<CourierShellScreen> createState() => _CourierShellScreenState();
}

class _CourierShellScreenState extends ConsumerState<CourierShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: IndexedStack(
        index: _index,
        children: [
          CourierDashboardScreen(profile: profile),
          CourierBalanceScreen(courierProfileId: profile.id),
          CourierProfileScreen(profile: profile),
        ],
      ),
      bottomNavigationBar: SmBottomNavBar(
        currentIndex: _index,
        items: [
          SmBottomNavItem.glyph(SmNavIcons.home, label: 'Home'),
          // The app's own glyph set has no wallet; analytics is the closest
          // honest fit for a screen of figures, and a borrowed glyph beats a
          // one-off icon that matches nothing else in the bar.
          SmBottomNavItem.glyph(SmNavIcons.analytics, label: 'Balance'),
          SmBottomNavItem.glyph(SmNavIcons.person, label: 'Profile'),
        ],
        // Tapping the current tab is a refresh everywhere else in the app, and
        // the three screens here each own a RefreshIndicator, so this only
        // changes tabs and leaves pull-to-refresh as the way to re-read.
        onTap: (index) {
          if (index != _index) setState(() => _index = index);
        },
      ),
    );
  }
}
