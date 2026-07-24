import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorApprovedScreen extends ConsumerWidget {
  const CreatorApprovedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Centered content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Approved badge icon
                      Image.asset(
                        'assets/images/vendordashboard/doneicon.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: DesignTokens.s24),

                      // Title
                      const Text(
                        'Application Approved',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s12),

                      // Subtitle
                      const Text(
                        'Congratulations your application has been approved. You can use stylemint to strengthen your brand more',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              decoration: const BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                border: Border(
                  top: BorderSide(
                      color: DesignTokens.borderDefault, width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16, DesignTokens.s16,
                DesignTokens.s16, DesignTokens.s32,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: DesignTokens.primaryGreen,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                    child: InkWell(
                      onTap: () {
                        ref.read(creatorFormProvider.notifier).reset();
                        context.go(RouteNames.creatorDash);
                      },
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.s16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Go to Creator Dashboard',
                              style: DesignTokens.oneLinerSemibold.copyWith(
                                  color: DesignTokens.buttonPrimaryText),
                            ),
                            const SizedBox(width: DesignTokens.s8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: DesignTokens.iconSmall,
                              color: DesignTokens.buttonPrimaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
