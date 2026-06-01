import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/notifiers/drop_party_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/widgets/countdown_timer.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:flutter/services.dart';

class DropPartyDetailScreen extends ConsumerWidget {
  const DropPartyDetailScreen({super.key, required this.partyId});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dropPartyDetailNotifierProvider(partyId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Drop Party', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (party) => _buildContent(context, ref, party),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load drop party',
                  style: DesignTokens.mediumRegular),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                onPressed: () => ref
                    .read(dropPartyDetailNotifierProvider(partyId).notifier)
                    .loadParty(partyId),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, DropParty party) {
    final isActive = party.status == DropPartyStatus.live ||
        party.status == DropPartyStatus.upcoming;
    final participation =
        party.currentParticipants / party.maxParticipants.clamp(1, 999);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(party.productImageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          Text(party.title, style: DesignTokens.titleMedium),
          const SizedBox(height: DesignTokens.s4),
          Text(party.description, style: DesignTokens.bodyText),
          const SizedBox(height: DesignTokens.s24),
          if (isActive)
            Center(
              child: CountdownTimer(
                  startsAt: party.startsAt, endsAt: party.endsAt),
            ),
          const SizedBox(height: DesignTokens.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(formatMoney(party.originalPrice),
                      style: DesignTokens.mediumRegular.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: DesignTokens.textMuted)),
                  const SizedBox(height: 4),
                  Text(formatMoney(party.dropPrice),
                      style: DesignTokens.titleLarge.copyWith(
                          color: DesignTokens.primaryGreen)),
                ],
              ),
              const SizedBox(width: DesignTokens.s32),
              Column(
                children: [
                  const Text('SAVE', style: DesignTokens.tiny),
                  const SizedBox(height: 4),
                  Text(
                    '${((party.originalPrice.amount - party.dropPrice.amount) / party.originalPrice.amount * 100).toStringAsFixed(0)}%',
                    style: DesignTokens.sectionInnerTitle.copyWith(
                        color: DesignTokens.primaryGreen),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
          const Text('Participants', style: DesignTokens.oneLinerSemibold),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Container(
                width: DesignTokens.avatarSmall,
                height: DesignTokens.avatarSmall,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: NetworkImage(party.hostAvatarUrl),
                      fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Text('Hosted by ${party.hostName}',
                  style: DesignTokens.mediumRegular),
              const Spacer(),
              Text(
                  '${party.currentParticipants}/${party.maxParticipants}',
                  style: DesignTokens.mediumSemibold),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
            child: LinearProgressIndicator(
              value: participation,
              backgroundColor: DesignTokens.bgAppBodyLight,
              valueColor: const AlwaysStoppedAnimation(DesignTokens.primaryGreen),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed:
                  isActive
                      ? () async {
                          final result = await ref
                              .read(dropPartyDetailNotifierProvider(partyId)
                                  .notifier)
                              .join(partyId);
                          result.fold(
                            (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Failed to join drop party')),
                                );
                              }
                            },
                            (_) {},
                          );
                        }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius)),
              ),
              child: Text(
                party.isJoined
                    ? 'Joined'
                    : party.status == DropPartyStatus.soldOut
                        ? 'Sold Out'
                        : party.status == DropPartyStatus.ended
                            ? 'Ended'
                            : 'Join Now',
                style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Share Invite',
                    style: DesignTokens.oneLinerSemibold),
                const SizedBox(height: DesignTokens.s8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s12,
                            vertical: DesignTokens.s12),
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppFoundation,
                          borderRadius: BorderRadius.circular(
                              DesignTokens.inputRadius),
                        ),
                        child: Text(party.inviteCode,
                            style: DesignTokens.oneLinerRegular),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    IconButton(
                      icon: const Icon(Icons.copy,
                          color: DesignTokens.primaryGreen),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: party.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Invite code copied!')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share,
                          color: DesignTokens.primaryGreen),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add),
                    label: const Text('Invite Friends'),
                    style: DesignTokens.outlinedButtonStyle(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
