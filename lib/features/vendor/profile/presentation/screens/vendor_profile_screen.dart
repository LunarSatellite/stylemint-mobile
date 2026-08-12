import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor profile screen reached from the dashboard bottom-nav "Profile"
/// tab. Kept intentionally minimal so the AppBar layout (Settings + Back on
/// the right) is the primary deliverable; populate the body once we wire
/// the vendor profile data source.
class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: DesignTokens.sectionInnerTitle),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: DesignTokens.textWhite,
              size: 22,
            ),
            onPressed: () => context.push(RouteNames.settings),
          ),
          // Back button intentionally lives on the right (per request). Pops
          // back to the vendor dashboard. Works because the bottom-nav tap
          // that landed here uses `context.push`, not `context.go`.
          IconButton(
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite,
              size: 18,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.vendorDash);
              }
            },
          ),
        ],
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.s24),
            child: Text(
              'Vendor profile content coming soon.',
              style: DesignTokens.mediumRegular,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}