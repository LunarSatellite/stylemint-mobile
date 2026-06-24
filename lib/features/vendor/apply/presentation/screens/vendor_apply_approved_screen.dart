import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorApplyApprovedScreen extends StatelessWidget {
  const VendorApplyApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildApprovedBadge(),
                      const SizedBox(height: DesignTokens.s24),
                      Text(
                        'Application Approved',
                        style: DesignTokens.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DesignTokens.s12),
                      Text(
                        'Congratulations your application has been approved. You can use stylemint to strengthen your brand more',
                        style: DesignTokens.bodyText.copyWith(
                          color: DesignTokens.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildDashboardButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedBadge() {
    return Image.asset(
      'assets/images/vendordashboard/badge_approved.png',
      width: 90,
      height: 90,
    );
  }

  Widget _buildDashboardButton(BuildContext context) {
    return Container(
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: DesignTokens.buttonHeight,
        child: ElevatedButton(
          onPressed: () => context.go(RouteNames.vendorDash),
          style: DesignTokens.primaryButtonStyle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Go to Vendor Dashboard',
                style: DesignTokens.oneLinerSemibold.copyWith(
                  color: DesignTokens.buttonPrimaryText,
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              const Icon(
                Icons.arrow_forward,
                color: DesignTokens.buttonPrimaryText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

