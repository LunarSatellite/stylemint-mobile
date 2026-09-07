import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/widgets/campaign_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor → Brand Studio → Campaign Briefs list (Vendor §3.1). This is the
/// read surface for the same `/v1/vendor/briefs` resource the invite flow
/// already drafts/patches against — tapping a card opens the lifecycle
/// actions (Lock/Fork/Retire/Recompute ROI) on [CampaignBriefDetailScreen].
class CampaignBriefsScreen extends ConsumerWidget {
  const CampaignBriefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorPartnershipsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: const BackButton(color: DesignTokens.textWhite),
        title: const Text('Campaign Briefs', style: DesignTokens.titleMedium),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: Colors.black,
        onPressed: () => context.push(RouteNames.vendorCreateCampaign),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (_) => SmErrorView(
          message: 'Failed to load campaign briefs.',
          onRetry: () => ref
              .read(vendorPartnershipsNotifierProvider.notifier)
              .loadCampaigns(),
        ),
        loadSuccess: (campaigns) => campaigns.isEmpty
            ? const SmEmptyState(
                message: 'No campaign briefs yet.',
                icon: Icons.description_outlined,
              )
            : RefreshIndicator(
                color: DesignTokens.primaryGreen,
                onRefresh: () => ref
                    .read(vendorPartnershipsNotifierProvider.notifier)
                    .loadCampaigns(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  itemCount: campaigns.length,
                  itemBuilder: (_, i) => CampaignCard(
                    campaign: campaigns[i],
                    onTap: () => context.push(
                      RouteNames.vendorCampaignBriefDetail.replaceFirst(
                        ':briefId',
                        campaigns[i].id,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
