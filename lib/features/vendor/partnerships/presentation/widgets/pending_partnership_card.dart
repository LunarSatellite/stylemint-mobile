import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/vendor_partnerships_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/message_creator_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Card for a creator-initiated partnership request awaiting the vendor's
/// Accept/Decline decision. Pixel-matched to the Figma `Figma_hFuCl9R1t2.png`
/// "Pending" reference: avatar + creator label, blue "Requested Commission"
/// chip, optional Message body, Decline + Accept outlined buttons, and a
/// full-width Message action to open the chat thread.
///
/// Shared between [CreatorPartnershipRequestsScreen] (standalone view from
/// the dashboard notification + More menu) and the Pending tab inside
/// [VendorPartnershipsScreen], so both surfaces render the exact same card.
class PendingPartnershipCard extends ConsumerWidget {
  const PendingPartnershipCard({
    super.key,
    required this.request,
    required this.isBusy,
  });

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
          const SizedBox(height: DesignTokens.s8),
          OutlinedButton(
            onPressed: () {
              // Prefer the backend-populated creator account id so the
              // chat can open directly without the by-profile lookup,
              // which only resolves RoleProfile.Id and 404s on the
              // CreatorProfile.Id we get from partnership listings.
              final otherParticipantId =
                  (request.creatorAccountId == null ||
                          request.creatorAccountId!.isEmpty)
                      ? null
                      : request.creatorAccountId;
              context.push(
                RouteNames.vendorMessageCreator,
                extra: MessageCreatorArgs(
                  creatorName: request.creatorLabel,
                  handle: request.creatorHandle,
                  avatarAsset: request.creatorLogoUrl ?? "",
                  otherParticipantId: otherParticipantId,
                  profileId: otherParticipantId == null
                      ? request.creatorProfileId
                      : null,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: DesignTokens.borderDefault),
              shape: const StadiumBorder(),
              foregroundColor: DesignTokens.textWhite,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Message'),
          ),
        ],
      ),
    );
  }
}