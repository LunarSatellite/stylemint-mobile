import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Same data as the "Pending" tab on VendorPartnershipsScreen (a
/// creator-initiated request awaiting the vendor's accept/decline) — this
/// screen is a standalone entry point for the same real list, reached from
/// elsewhere (e.g. a dashboard notification) rather than from the tab bar.
class CreatorPartnershipRequestsScreen extends ConsumerWidget {
  const CreatorPartnershipRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnershipsListNotifierProvider);

    ref.listen<PartnershipsState>(partnershipsListNotifierProvider, (
      _,
      next,
    ) {
      next.maybeWhen(
        actionFailure: (_, __) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
        orElse: () {},
      );
    });

    final all = state.maybeWhen(
      loadSuccess: (partnerships, _) => partnerships,
      actionInProgress: (partnerships) => partnerships,
      actionFailure: (partnerships, _) => partnerships,
      orElse: () => const <VendorPartnership>[],
    );
    final pending = all
        .where(
          (p) => p.state == PartnershipState.invited && p.initiatedByCreator,
        )
        .toList(growable: false);
    final isBusy = state.maybeWhen(
      actionInProgress: (_) => true,
      orElse: () => false,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Creator Partnership Requests',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: state.maybeWhen(
        loadInProgress: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        loadFailure: (_) => SmErrorView(
          message: 'Failed to load requests.',
          onRetry: () =>
              ref.read(partnershipsListNotifierProvider.notifier).load(),
        ),
        orElse: () => pending.isEmpty
            ? const SmEmptyState(
                message: 'No pending requests from creators.',
                icon: Icons.mail_outline,
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s12,
                ),
                itemCount: pending.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s8),
                itemBuilder: (_, i) =>
                    _RequestCard(request: pending[i], isBusy: isBusy),
              ),
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request, required this.isBusy});

  final VendorPartnership request;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(partnershipsListNotifierProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2C2C2E),
                child: Text(
                  request.creatorLabel[0],
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.creatorLabel,
                      style: DesignTokens.smallRegular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.tagInfoFill,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Requested Commission: '
                        '${(request.commissionMinPercent * 100).round()}%'
                        '–${(request.commissionMaxPercent * 100).round()}%',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 10,
                          color: DesignTokens.tagInfoText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((request.requestMessage ?? '').isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message',
                    style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    request.requestMessage!,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => notifier.declineRequest(request.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DesignTokens.dotSeparator),
                    shape: const StadiumBorder(),
                    foregroundColor: DesignTokens.textLight,
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => notifier.acceptRequest(request.id),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DesignTokens.primaryGreen),
                    shape: const StadiumBorder(),
                    foregroundColor: DesignTokens.primaryGreen,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
