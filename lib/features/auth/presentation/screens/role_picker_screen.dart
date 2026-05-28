import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/base_widget.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/auth_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/widgets/role_card.dart';

/// Role Picker Screen - Third step of auth flow
/// User selects their role: Customer, Creator, or Vendor
class RolePickerScreen extends ConsumerStatefulWidget {
  final AuthResponseDto authData;

  const RolePickerScreen({
    Key? key,
    required this.authData,
  }) : super(key: key);

  @override
  ConsumerState<RolePickerScreen> createState() => _RolePickerScreenState();
}

class _RolePickerScreenState extends ConsumerState<RolePickerScreen> {
  String? selectedRole;

  void _handleRoleSelection(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  void _handleContinue() {
    if (selectedRole == null) {
      SmSnackbar.warning(context, 'Please select a role to continue');
      return;
    }

    // TODO: Save selected role + auth tokens to secure storage
    // TODO: Implement role-specific onboarding

    // For now, navigate to appropriate home screen based on role
    String homeRoute = RouteNames.home;
    if (selectedRole == 'creator') {
      homeRoute = RouteNames.creatorHome;
    } else if (selectedRole == 'vendor') {
      homeRoute = RouteNames.vendorHome;
    }

    context.go(homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    return BaseWidget(builder: (_, sizeConfig, theme) {
      return Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: const SmAppBar(
          title: 'Choose Your Role',
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.appHorizontalPadding,
            vertical: DesignTokens.appVerticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Select Your Role',
                style: DesignTokens.h2,
              ),
              const SizedBox(height: DesignTokens.s12),
              Text(
                'You can change this later in your profile settings',
                style: DesignTokens.body,
              ),
              const SizedBox(height: DesignTokens.s32),

              // Role Cards Grid
              GridView.count(
                crossAxisCount: 1,
                mainAxisSpacing: DesignTokens.s16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Customer Role
                  RoleCard(
                    role: 'customer',
                    title: 'Customer',
                    description: 'Shop products through engaging reels',
                    icon: Icons.shopping_bag_outlined,
                    isSelected: selectedRole == 'customer',
                    onTap: () => _handleRoleSelection('customer'),
                  ),

                  // Creator Role
                  RoleCard(
                    role: 'creator',
                    title: 'Creator',
                    description: 'Create content and earn commissions',
                    icon: Icons.videocam_outlined,
                    isSelected: selectedRole == 'creator',
                    onTap: () => _handleRoleSelection('creator'),
                  ),

                  // Vendor Role
                  RoleCard(
                    role: 'vendor',
                    title: 'Vendor',
                    description: 'Sell your products to the community',
                    icon: Icons.storefront_outlined,
                    isSelected: selectedRole == 'vendor',
                    onTap: () => _handleRoleSelection('vendor'),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.s32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: SmPrimaryButton(
                  label: 'Continue',
                  onPressed: () async => _handleContinue(),
                ),
              ),

              const SizedBox(height: DesignTokens.s16),

              // Info Box
              Container(
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBody,
                  borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                  border: Border.all(
                    color: DesignTokens.borderDefault,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Did you know?',
                      style: DesignTokens.small.copyWith(
                        color: DesignTokens.colorInfo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      'You can switch between roles anytime. The more roles you enable, the more earning opportunities you unlock!',
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
