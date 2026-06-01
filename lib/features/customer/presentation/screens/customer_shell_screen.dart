import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/customer_bottom_nav_bar.dart';

/// Persistent shell for the 4 customer tabs (Home, Discover, Track Order,
/// Profile). Uses [StatefulNavigationShell] so each branch keeps its own
/// navigation stack and scroll position across tab switches.
class CustomerShellScreen extends StatelessWidget {
  const CustomerShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
