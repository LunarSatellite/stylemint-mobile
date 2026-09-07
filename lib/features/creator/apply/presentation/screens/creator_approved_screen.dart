import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorApprovedScreen extends ConsumerStatefulWidget {
  const CreatorApprovedScreen({super.key});

  @override
  ConsumerState<CreatorApprovedScreen> createState() =>
      _CreatorApprovedScreenState();
}

class _CreatorApprovedScreenState extends ConsumerState<CreatorApprovedScreen> {
  bool _activating = false;

  Future<void> _onGoToDashboard() async {
    if (_activating) return;
    setState(() => _activating = true);
    // Grant the Creator role server-side via /v1/creator/activate so the
    // profile screen reads creatorActive == true next render. Idempotent,
    // safe to call even if already activated.
    await ref.read(creatorActivateNotifierProvider.notifier).activate();
    ref.read(creatorFormProvider.notifier).reset();
    if (!mounted) return;
    setState(() => _activating = false);
    context.go(RouteNames.creatorDash);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/doneicon.png',
                        width: 100,
                        height: 100,
                      ),
                      const SizedBox(height: DesignTokens.s24),
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
                      onTap: _activating ? null : _onGoToDashboard,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: DesignTokens.s16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_activating)
                              const SizedBox(
                                width: DesignTokens.iconSmall,
                                height: DesignTokens.iconSmall,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    DesignTokens.buttonPrimaryText,
                                  ),
                                ),
                              )
                            else
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