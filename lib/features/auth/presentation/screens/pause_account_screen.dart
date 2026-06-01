import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/account_pause_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PauseAccountScreen extends ConsumerStatefulWidget {
  const PauseAccountScreen({super.key});

  @override
  ConsumerState<PauseAccountScreen> createState() =>
      _PauseAccountScreenState();
}

class _PauseAccountScreenState extends ConsumerState<PauseAccountScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(accountPauseProvider.notifier).load();
  }

  Future<void> _pauseAccount() async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Pause Account',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How many days would you like to pause your account?',
              style: TextStyle(color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s16),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [7, 14, 30, 90].map((d) {
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s20,
                        vertical: DesignTokens.s12),
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBodyLight,
                      borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius),
                    ),
                    child: Text('$d days',
                        style: DesignTokens.oneLinerSemibold),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: DesignTokens.textMuted)),
          ),
        ],
      ),
    );
    if (days != null) {
      ref.read(accountPauseActionProvider.notifier).pause(days: days);
    }
  }

  Future<void> _resumeAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Resume Account',
            style: TextStyle(color: DesignTokens.textWhite)),
        content: const Text(
          'Your account will be reactivated.',
          style: TextStyle(color: DesignTokens.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: DesignTokens.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resume',
                style: TextStyle(color: DesignTokens.primaryGreen)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(accountPauseActionProvider.notifier).resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountPauseProvider);
    ref.listen<AccountPauseActionState>(accountPauseActionProvider,
        (previous, next) {
      next.maybeWhen(
        loadSuccess: () {
          ref.read(accountPauseProvider.notifier).load();
          ref.read(accountPauseActionProvider.notifier).reset();
        },
        loadFailure: (_) => SmSnackbar.error(context, 'Action failed'),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pause Account',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (pause) {
            final isPaused = pause.isActive;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    decoration: BoxDecoration(
                      color: DesignTokens.infoFillDark,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.cardRadius),
                      border: Border.all(color: DesignTokens.infoIconLight
                          .withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: DesignTokens.infoIconLight,
                            size: DesignTokens.iconMedium),
                        const SizedBox(width: DesignTokens.s12),
                        Expanded(
                          child: Text(
                            'Pausing your account will temporarily hide your profile, '
                            'listings, and content. You can resume at any time.',
                            style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.infoTextLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s24),

                  Text(
                    isPaused ? 'Account Paused' : 'Account Active',
                    style: DesignTokens.sectionInnerTitle.copyWith(
                      color: isPaused
                          ? DesignTokens.secondaryYellow
                          : DesignTokens.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),

                  if (isPaused && pause.pauseUntilUtc != null)
                    Text(
                      'Paused until: ${pause.pauseUntilUtc!.toLocal().toString().split('.')[0]}',
                      style: DesignTokens.bodyText,
                    ),

                  const SizedBox(height: DesignTokens.s32),

                  if (isPaused)
                    SizedBox(
                      width: double.infinity,
                      child: SmPrimaryButton(
                        label: 'Resume My Account',
                        onPressed: _resumeAccount,
                        height: DesignTokens.buttonHeight,
                        borderRadius: DesignTokens.buttonRadius,
                        color: DesignTokens.primaryGreen,
                        labelColor: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: SmPrimaryButton(
                        label: 'Pause My Account',
                        onPressed: _pauseAccount,
                        height: DesignTokens.buttonHeight,
                        borderRadius: DesignTokens.buttonRadius,
                        color: DesignTokens.secondaryYellow,
                        labelColor: DesignTokens.textDark,
                      ),
                    ),
                ],
              ),
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load pause status',
                    style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                GestureDetector(
                  onTap: () =>
                      ref.read(accountPauseProvider.notifier).load(),
                  child: Text('Retry',
                      style: TextStyle(color: DesignTokens.primaryGreen)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}
