import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/widgets/pending_partnership_card.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
/// Standalone view of pending creator-initiated partnership requests (awaiting
/// the vendor's accept/decline). Reached from two entry points: the vendor
/// dashboard notification badge and the Creator Partnerships item on the
/// dashboard's More menu.
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
                    PendingPartnershipCard(request: pending[i], isBusy: isBusy),
              ),
      ),
    );
  }
}

