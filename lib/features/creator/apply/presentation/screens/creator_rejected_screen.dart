import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorRejectedScreen extends ConsumerWidget {
  const CreatorRejectedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s40,
                  DesignTokens.s16, DesignTokens.s32,
                ),
                child: Column(
                  children: [
                    // Rejected icon
                    Image.asset(
                      'assets/images/Crossed.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    // Title
                    const Text(
                      'Application Rejected',
                      textAlign: TextAlign.center,
                      style: DesignTokens.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.s12),

                    // Subtitle
                    Text(
                      'Unfortunately your application has been rejected. Please contact our support team for more information',
                      textAlign: TextAlign.center,
                      style: DesignTokens.mediumRegular
                          .copyWith(color: DesignTokens.textLight),
                    ),
                    const SizedBox(height: DesignTokens.s28),

                    // Rejection reasons card
                    _RejectionCard(),
                  ],
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Need Help?  ',
                          style: DesignTokens.mediumRegular
                              .copyWith(color: DesignTokens.textLight),
                        ),
                        GestureDetector(
                          onTap: () => context
                              .push(RouteNames.creatorSupportContact),
                          child: Text(
                            'Contact Support',
                            style: DesignTokens.mediumSemibold
                                .copyWith(color: DesignTokens.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: DesignTokens.primaryGreen,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                        child: InkWell(
                          onTap: () {
                            ref.read(creatorFormProvider.notifier).reset();
                            context.go(RouteNames.home);
                          },
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: DesignTokens.s16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.home_rounded,
                                    size: DesignTokens.iconSmall,
                                    color: DesignTokens.buttonPrimaryText),
                                const SizedBox(width: DesignTokens.s8),
                                Text(
                                  'Return to Home',
                                  style: DesignTokens.oneLinerSemibold
                                      .copyWith(
                                          color:
                                              DesignTokens.buttonPrimaryText),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rejection reasons card
// ---------------------------------------------------------------------------
class _RejectionCard extends StatelessWidget {
  static const _guidelinesStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    color: DesignTokens.textLight,
    decoration: TextDecoration.underline,
    decorationColor: DesignTokens.textLight,
    height: 1.4,
  );

  static const _bodyStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    color: DesignTokens.textLight,
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.infoFillDark,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What might have caused the rejection',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DesignTokens.colorInfo,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          _bullet(const Text('Less social media engagement',
              style: _bodyStyle)),
          _bullet(Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text: 'Your content may be against our ',
                    style: _bodyStyle),
                const TextSpan(
                    text: 'Creator Guidelines', style: _guidelinesStyle),
              ],
            ),
          )),
          _bullet(Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                    text:
                        'Your social media profile numbers does not match our numbers stated in our ',
                    style: _bodyStyle),
                const TextSpan(
                    text: 'Creator Guidelines', style: _guidelinesStyle),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _bullet(Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(
                color: DesignTokens.colorInfo,
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
              )),
          Expanded(child: content),
        ],
      ),
    );
  }
}
