import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorSubmittedScreen extends ConsumerStatefulWidget {
  const CreatorSubmittedScreen({super.key});

  @override
  ConsumerState<CreatorSubmittedScreen> createState() =>
      _CreatorSubmittedScreenState();
}

class _CreatorSubmittedScreenState
    extends ConsumerState<CreatorSubmittedScreen> {
  late final DateTime _submittedAt;
  late final String _appId;

  @override
  void initState() {
    super.initState();
    _submittedAt = DateTime.now();
    _appId =
        '#CR${_submittedAt.year}-${(_submittedAt.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
  }

  String get _formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = _submittedAt.hour.toString().padLeft(2, '0');
    final m = _submittedAt.minute.toString().padLeft(2, '0');
    return '$h:$m ${months[_submittedAt.month - 1]} ${_submittedAt.day}, ${_submittedAt.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                    // Success badge
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    // Title
                    const Text(
                      'Application Submitted',
                      textAlign: TextAlign.center,
                      style: DesignTokens.titleMedium,
                    ),
                    const SizedBox(height: DesignTokens.s12),

                    // Subtitle
                    Text(
                      'Thank you for applying to become a creator on ReelCommerce. We\'re reviewing your application',
                      textAlign: TextAlign.center,
                      style: DesignTokens.mediumRegular
                          .copyWith(color: DesignTokens.textLight),
                    ),
                    const SizedBox(height: DesignTokens.s28),

                    // Status card
                    _StatusCard(
                        appId: _appId, submittedAt: _formattedDate),
                    const SizedBox(height: DesignTokens.s16),

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
                          onTap: () => context.push(RouteNames.supportContact),
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
                                          color: DesignTokens.buttonPrimaryText),
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
// Application Current Status card
// ---------------------------------------------------------------------------
class _StatusCard extends StatelessWidget {
  final String appId;
  final String submittedAt;
  const _StatusCard({required this.appId, required this.submittedAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.folder_rounded,
              color: Color(0xFFF1C40F), size: 36),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Application Current Status',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Submitted on $submittedAt',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                // Under Review chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.warningFillDark,
                    borderRadius:
                        BorderRadius.circular(DesignTokens.chipRadius),
                    border: Border.all(
                        color: DesignTokens.colorWarning.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 12, color: DesignTokens.colorWarning),
                      const SizedBox(width: 4),
                      Text(
                        'Under Review',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: DesignTokens.colorWarning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Application ID: $appId',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  Text('• ',
                      style: TextStyle(
                          color: titleColor,
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14)),
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
