import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_documents_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/providers/creator_form_provider.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorRejectedScreen extends ConsumerStatefulWidget {
  const CreatorRejectedScreen({super.key});

  @override
  ConsumerState<CreatorRejectedScreen> createState() =>
      _CreatorRejectedScreenState();
}

class _CreatorRejectedScreenState extends ConsumerState<CreatorRejectedScreen> {
  bool _loading = false;

  Future<void> _onApplyAgain() async {
    if (_loading) return;
    setState(() => _loading = true);
    // Backend gap: neither /v1/creator/apply (returns 409 — application
    // exists) nor /v1/accounts/{accountId}/creator-profile/reapply (returns
    // 404 — no CreatorProfile yet) supports re-applying from a rejected
    // CreatorApplication that never became a CreatorProfile. For now, just
    // open the wizard pre-filled from the rejected application so the user
    // can edit; the backend team needs to add a re-submit-from-rejected
    // endpoint before the submit step can succeed.
    await ref.read(creatorApplyNotifierProvider.notifier).checkStatus();
    if (!mounted) return;
    final state = ref.read(creatorApplyNotifierProvider);
    state.maybeWhen(
      loadSuccess: (app) {
        ref.read(creatorFormProvider.notifier).loadFromApplication(app);
      },
      orElse: () {},
    );
    if (context.canPop()) {
      context.pop();
    }
    context.go(RouteNames.creatorApply);
  }

  void _onReturnToHome() {
    ref.read(creatorFormProvider.notifier).reset();
    if (context.canPop()) {
      context.pop();
    }
    context.go(RouteNames.home);
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s40,
                  DesignTokens.s16, DesignTokens.s32,
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/Crossed.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    const Text(
                      'Application Rejected',
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
                      'Unfortunately your application has been rejected. Please contact our support team for more information',
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
                    _RejectionCard(),
                    const SizedBox(height: DesignTokens.s16),
                    const _RejectedDocumentsCard(),
                  ],
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
                    Row(
                      children: [
                        Expanded(
                          child: _ReturnToHomeButton(onTap: _onReturnToHome),
                        ),
                        const SizedBox(width: DesignTokens.s12),
                        Expanded(
                          child: _ApplyAgainButton(
                            loading: _loading,
                            onTap: _onApplyAgain,
                          ),
                        ),
                      ],
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

class _ReturnToHomeButton extends StatelessWidget {
  const _ReturnToHomeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.bgAppFoundation,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: DesignTokens.primaryGreen, width: 1.5),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_rounded,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.primaryGreen),
              const SizedBox(width: DesignTokens.s8),
              Text(
                'Return to Home',
                style: DesignTokens.oneLinerSemibold
                    .copyWith(color: DesignTokens.primaryGreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyAgainButton extends StatelessWidget {
  const _ApplyAgainButton({required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.primaryGreen,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
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
                const Icon(Icons.refresh_rounded,
                    size: DesignTokens.iconSmall,
                    color: DesignTokens.buttonPrimaryText),
              const SizedBox(width: DesignTokens.s8),
              Text(
                loading ? 'Loading...' : 'Apply Again',
                style: DesignTokens.oneLinerSemibold
                    .copyWith(color: DesignTokens.buttonPrimaryText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
/// Shows which identity documents a reviewer rejected, and why.
///
/// Without this the rejected screen said only "contact support", leaving the
/// creator to guess which document to replace on reapply. Renders nothing
/// when no document was rejected — an application can be rejected for
/// reasons unrelated to KYC.
class _RejectedDocumentsCard extends ConsumerStatefulWidget {
  const _RejectedDocumentsCard();

  @override
  ConsumerState<_RejectedDocumentsCard> createState() =>
      _RejectedDocumentsCardState();
}

class _RejectedDocumentsCardState
    extends ConsumerState<_RejectedDocumentsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(creatorDocumentsNotifierProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rejected = ref.watch(creatorDocumentsNotifierProvider).rejected;
    if (rejected.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.colorError),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 18,
                color: DesignTokens.colorError,
              ),
              const SizedBox(width: DesignTokens.s8),
              Text(
                rejected.length == 1
                    ? 'A document was rejected'
                    : '${rejected.length} documents were rejected',
                style: DesignTokens.mediumSemibold
                    .copyWith(color: DesignTokens.textWhite),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          ...rejected.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.type.label, style: DesignTokens.bodyText),
                  Text(
                    d.rejectionReason ??
                        'Please upload a clearer copy when you reapply.',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight),
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
