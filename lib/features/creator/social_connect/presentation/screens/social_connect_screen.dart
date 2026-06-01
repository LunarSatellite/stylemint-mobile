import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/widgets/platform_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class SocialConnectScreen extends ConsumerWidget {
  const SocialConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialConnectNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s8,
              ),
              child: Text(
                'Connected Platforms',
                style: DesignTokens.titleLarge,
              ),
            ),
          Expanded(
            child: state.maybeWhen(
              loadSuccess: (accounts) {
                if (accounts.isEmpty) {
                  return const SmEmptyState(
                    message: 'No platforms connected yet.',
                    icon: Icons.link_off,
                  );
                }
                final notifier =
                    ref.read(socialConnectNotifierProvider.notifier);
                return RefreshIndicator(
                  color: DesignTokens.primaryGreen,
                  onRefresh: () => notifier.load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                    ),
                    itemCount: accounts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: DesignTokens.s8),
                    itemBuilder: (_, i) => PlatformCard(
                      account: accounts[i],
                      onConnect:
                          () => notifier.connect(
                            accounts[i].platform,
                            'auth_code',
                          ),
                      onDisconnect:
                          () => notifier.disconnect(accounts[i].id),
                    ),
                  ),
                );
              },
              loadFailure: (failure) => SmErrorView(
                message: 'Failed to load platforms.',
                onRetry:
                    () =>
                        ref
                            .read(socialConnectNotifierProvider.notifier)
                            .load(),
              ),
              orElse: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
