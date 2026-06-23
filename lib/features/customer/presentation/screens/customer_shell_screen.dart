import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/customer_bottom_nav_bar.dart';

/// Persistent shell for the 4 customer tabs (Home, Discover, Track Order,
/// Profile). Uses [StatefulNavigationShell] so each branch keeps its own
/// navigation stack and scroll position across tab switches.
class CustomerShellScreen extends ConsumerWidget {
  const CustomerShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Bottom-bar index of the Home (reels) tab.
  static const _homeBranchIndex = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          final reselected = index == navigationShell.currentIndex;
          // Tapping Home while already on it refreshes the reels feed.
          if (reselected && index == _homeBranchIndex) {
            ref.read(homeTabReselectedProvider.notifier).state++;
          }
          navigationShell.goBranch(index, initialLocation: reselected);
        },
      ),
    );
  }
}
