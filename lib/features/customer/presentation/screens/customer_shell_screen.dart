import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/auth/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/current_user_avatar_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/customer_bottom_nav_bar.dart';

/// Persistent shell for the customer tabs. Uses [StatefulNavigationShell] so
/// each branch (Home, Discover, Profile) keeps its own navigation stack and
/// scroll position across tab switches.
///
/// The bar also carries Cart, between the centre Scan action and Profile.
/// Cart is not a branch: it opens the cart page (with checkout) over the
/// shell, so bar indices from Cart onwards are one past their branch index.
/// Orders is reached from Profile's "My Orders".
class CustomerShellScreen extends ConsumerWidget {
  const CustomerShellScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Branch index of the Home (reels) tab.
  static const _homeBranch = 0;

  /// Branch index of the Profile tab.
  static const _profileBranch = 2;

  static int _barIndexFor(int branch) =>
      branch < CustomerBottomNavBar.cartIndex ? branch : branch + 1;

  static int _branchFor(int barIndex) =>
      barIndex < CustomerBottomNavBar.cartIndex ? barIndex : barIndex - 1;

  Future<void> _openCart(BuildContext context, WidgetRef ref) async {
    if (await ensureAuth(context, ref, reason: AuthReason.checkout)) {
      if (context.mounted) await context.push(RouteNames.cart);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomerBottomNavBar(
        currentIndex: _barIndexFor(navigationShell.currentIndex),
        cartBadge: ref.watch(cartItemCountProvider),
        avatarUrl: ref.watch(currentUserAvatarUrlProvider),
        onScan: () => unawaited(context.push(RouteNames.scan)),
        onTap: (barIndex) {
          if (barIndex == CustomerBottomNavBar.cartIndex) {
            unawaited(_openCart(context, ref));
            return;
          }
          final branch = _branchFor(barIndex);
          final reselected = branch == navigationShell.currentIndex;
          // Tapping Home while already on it refreshes the reels feed.
          if (reselected && branch == _homeBranch) {
            ref.read(homeTabReselectedProvider.notifier).state++;
          }
          // Profile's role list needs to notice a vendor/creator approval
          // that happened elsewhere.
          if (branch == _profileBranch) {
            ref.read(profileTabVisitedProvider.notifier).state++;
          }
          navigationShell.goBranch(branch, initialLocation: reselected);
        },
      ),
    );
  }
}
