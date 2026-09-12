import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Referrals — Voyager doc's "Creator, Referral and Community Growth
/// Graph" capability. Shows the customer's own invite link (created on
/// first visit if they don't have one yet), lets them share it, and
/// lists who has redeemed it so far.
class ReferralsScreen extends ConsumerWidget {
  const ReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(referralsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Invite Friends'),
      ),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loadInProgress: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        loadFailure: (failure) => SmErrorView(
          message: failure.isNoInternet
              ? 'No internet connection.'
              : 'Failed to load your invite link.',
          onRetry: () => ref.read(referralsNotifierProvider.notifier).load(),
        ),
        loadSuccess: (link, redemptions) {
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () => ref.read(referralsNotifierProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  decoration: DesignTokens.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invite friends, both of you win',
                        style: DesignTokens.sectionInnerTitle,
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      Text(
                        'Share your link — you get credit once they finish '
                        'setting up their account.',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s12,
                          vertical: DesignTokens.s12,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(DesignTokens.s8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                link.shareUrl,
                                style: DesignTokens.mediumSemibold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: DesignTokens.primaryGreen),
                              onPressed: () => _copyLink(context, link.shareUrl),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _shareLink(link.shareUrl),
                          icon: const Icon(Icons.share),
                          label: const Text('Share Invite Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryGreen,
                            foregroundColor: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      if (!link.isActive) ...[
                        const SizedBox(height: DesignTokens.s8),
                        const Text(
                          'This link has expired or reached its redemption limit.',
                          style: TextStyle(color: DesignTokens.colorError, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),
                Text(
                  '${redemptions.length} friend${redemptions.length == 1 ? '' : 's'} joined',
                  style: DesignTokens.sectionInnerTitle,
                ),
                const SizedBox(height: DesignTokens.s8),
                if (redemptions.isEmpty)
                  const SmEmptyState(
                    message: 'No one has used your invite link yet — share it to start earning credit.',
                    icon: Icons.group_add_outlined,
                  )
                else
                  ...redemptions.map(
                    (r) => Container(
                      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                      padding: const EdgeInsets.all(DesignTokens.s12),
                      decoration: DesignTokens.cardDecoration(),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, color: DesignTokens.textMuted),
                          const SizedBox(width: DesignTokens.s8),
                          Expanded(
                            child: Text(
                              'Joined ${_formatDate(r.redeemedAtUtc)}',
                              style: DesignTokens.smallRegular,
                            ),
                          ),
                          const Icon(Icons.check_circle, size: 16, color: DesignTokens.primaryGreen),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _copyLink(BuildContext context, String url) {
    unawaited(Clipboard.setData(ClipboardData(text: url)));
    SmSnackbar.success(context, 'Invite link copied');
  }

  void _shareLink(String url) {
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text: 'Join me on Style Mint — shop, create, and sell in reels! $url',
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }
}
