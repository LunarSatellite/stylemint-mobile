
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/data/vendor_journeys_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/domain/vendor_journey.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Journeys: businesses' reels linked in order, so a buyer swipes sideways
/// from one business to the next. Lists the invites waiting for me, the
/// journeys I run and the ones I am a step of.
class VendorJourneysScreen extends ConsumerWidget {
  const VendorJourneysScreen({super.key});

  static const Key createKey = Key('vendor-journeys-create');
  static Key tileKey(String id) => Key('vendor-journey-tile-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeys = ref.watch(vendorJourneysProvider);
    final unavailable = journeys.hasError && serviceUnavailable(journeys.error);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Journeys'),
      ),
      floatingActionButton: unavailable || !journeys.hasValue
          ? null
          : FloatingActionButton.extended(
              key: createKey,
              onPressed: () async {
                await context.push(JourneyRoutes.create);
                ref.invalidate(vendorJourneysProvider);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('New journey'),
            ),
      body: SafeArea(
        child: journeys.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              ServiceLoadFailureView(
                error: error,
                settingUpTitle: 'Journeys are being set up',
                specific: journeyErrorMessage,
                onRetry: () => ref.invalidate(vendorJourneysProvider),
              ),
            ],
          ),
          data: (all) => RefreshIndicator(
            onRefresh: () => ref.refresh(vendorJourneysProvider.future),
            child: _JourneyList(journeys: all),
          ),
        ),
      ),
    );
  }
}

class _JourneyList extends ConsumerWidget {
  const _JourneyList({required this.journeys});

  final List<VendorJourney> journeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invites = [
      for (final j in journeys)
        if (j.isInvitee && !j.isEnded) j,
    ];
    final owned = [
      for (final j in journeys)
        if (j.isOwner) j,
    ];
    final member = [
      for (final j in journeys)
        if (j.myRole == JourneyRole.member) j,
    ];

    Future<void> open(VendorJourney journey) async {
      await context.push(JourneyRoutes.detailPath(journey.id));
      ref.invalidate(vendorJourneysProvider);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        96,
      ),
      children: [
        Text(
          'Link your reel with other businesses — a bus company, a hotel, an '
          'activity — so buyers swipe from one to the next.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (journeys.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s32),
            child: Column(
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 40,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(height: DesignTokens.s12),
                const Text(
                  'No journeys yet',
                  style: DesignTokens.mediumSemibold,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Start one with one of your published reels, then invite '
                  'the businesses that come next.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        if (invites.isNotEmpty) ...[
          const ServiceSectionTitle('Invites for you'),
          for (final j in invites) _JourneyTile(journey: j, onTap: () => open(j)),
        ],
        if (owned.isNotEmpty) ...[
          const ServiceSectionTitle('Your journeys'),
          for (final j in owned) _JourneyTile(journey: j, onTap: () => open(j)),
        ],
        if (member.isNotEmpty) ...[
          const ServiceSectionTitle("Journeys you're in"),
          for (final j in member) _JourneyTile(journey: j, onTap: () => open(j)),
        ],
      ],
    );
  }
}

class _JourneyTile extends StatelessWidget {
  const _JourneyTile({required this.journey, required this.onTap});

  final VendorJourney journey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final city = journey.city;
    final steps = journey.steps.length;
    final subtitle = [
      if (city != null) city,
      '$steps ${steps == 1 ? 'step' : 'steps'}',
      if (!journey.isOwner) 'by ${journey.ownerName}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Material(
        color: DesignTokens.bgAppBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: const BorderSide(color: DesignTokens.borderDefault),
        ),
        child: InkWell(
          key: VendorJourneysScreen.tileKey(journey.id),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: DesignTokens.textLight),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journey.displayTitle,
                        style: DesignTokens.mediumSemibold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                JourneyStatusPill(journey: journey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Live, not live yet, invited or ended.
class JourneyStatusPill extends StatelessWidget {
  const JourneyStatusPill({required this.journey, super.key});

  final VendorJourney journey;

  @override
  Widget build(BuildContext context) {
    if (journey.isEnded) {
      return const ServicePill('Ended', tone: ServicePillTone.error);
    }
    if (journey.isInvitee) {
      return const ServicePill('Invited', tone: ServicePillTone.info);
    }
    return journey.isLive
        ? const ServicePill('Live', tone: ServicePillTone.success)
        : const ServicePill('Not live yet', tone: ServicePillTone.warning);
  }
}
