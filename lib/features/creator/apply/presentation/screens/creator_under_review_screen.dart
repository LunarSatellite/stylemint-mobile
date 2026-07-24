import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorUnderReviewScreen extends ConsumerWidget {
  const CreatorUnderReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.read(creatorFormProvider).email;

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
                    // Under-review illustration
                    Image.asset(
                      'assets/images/vendordashboard/underreview.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    // Title
                    const Text(
                      'Application Under Review',
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
                      'Your application is being reviewed. We will notify you with the results once the review process is completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: DesignTokens.textLight,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s28),

                    // What happens next
                    _InfoCard(
                      title: 'What Happens next ?',
                      titleColor: DesignTokens.colorInfo,
                      fillColor: DesignTokens.infoFillDark,
                      items: const [
                        'Our team reviews your application (1–3 days)',
                        'We verify your social media profiles',
                        'You\'ll receive an email with our decision',
                      ],
                    ),
                    const SizedBox(height: DesignTokens.s16),

                    // While you wait
                    _InfoCard(
                      title: 'While you wait',
                      titleColor: DesignTokens.colorWarning,
                      fillColor: DesignTokens.warningFillDark,
                      items: [
                        'Make sure notifications are enabled',
                        if (email.isNotEmpty)
                          'Check your email ($email)'
                        else
                          'Check your email inbox',
                        'Review our Creator Guidelines',
                        'Browse Success Stories from other creators',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              decoration: const BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                border: Border(
                  top: BorderSide(color: DesignTokens.borderDefault, width: 1),
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
// Info / Warning card with bullet list
// ---------------------------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color fillColor;
  final List<String> items;

  const _InfoCard({
    required this.title,
    required this.titleColor,
    required this.fillColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: titleColor,
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textLight,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
