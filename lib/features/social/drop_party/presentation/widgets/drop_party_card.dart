import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_detail_screen.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class DropPartyCard extends StatelessWidget {
  const DropPartyCard({super.key, required this.party});

  final DropParty party;

  @override
  Widget build(BuildContext context) {
    final isLive = party.status == DropPartyStatus.live;
    final participation =
        party.currentParticipants / party.maxParticipants.clamp(1, 999);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DropPartyDetailScreen(partyId: party.id),
          ),
        );
      },
      child: Container(
        decoration: DesignTokens.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(party.productImageUrl, fit: BoxFit.cover),
                  Positioned(
                    top: DesignTokens.s8,
                    right: DesignTokens.s8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                          vertical: DesignTokens.s4),
                      decoration: BoxDecoration(
                        color: _statusColor(party.status),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.chipRadius),
                      ),
                      child: Text(
                        _statusLabel(party.status),
                        style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textWhite,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (isLive)
                    Positioned(
                      bottom: DesignTokens.s8,
                      left: DesignTokens.s8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: DesignTokens.s4),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryGreen,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.chipRadius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _pulseDot(),
                            const SizedBox(width: 4),
                            const Text('LIVE',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: DesignTokens.buttonPrimaryText)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.productName,
                        style: DesignTokens.mediumSemibold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(formatMoney(party.dropPrice),
                            style: DesignTokens.mediumSemibold.copyWith(
                                color: DesignTokens.primaryGreen,
                                fontSize: 16)),
                        const SizedBox(width: DesignTokens.s6),
                        Text(formatMoney(party.originalPrice),
                            style: DesignTokens.smallRegular.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: DesignTokens.textMuted)),
                      ],
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.buttonRadius),
                      child: LinearProgressIndicator(
                        value: participation,
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        valueColor: const AlwaysStoppedAnimation(
                            DesignTokens.primaryGreen),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${party.currentParticipants}/${party.maxParticipants} joined',
                        style: DesignTokens.tiny),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(DropPartyStatus status) {
    switch (status) {
      case DropPartyStatus.live:
        return DesignTokens.colorError;
      case DropPartyStatus.upcoming:
        return DesignTokens.colorInfo;
      case DropPartyStatus.soldOut:
        return DesignTokens.colorWarning;
      case DropPartyStatus.ended:
        return DesignTokens.textMuted;
    }
  }

  String _statusLabel(DropPartyStatus status) {
    switch (status) {
      case DropPartyStatus.live:
        return 'LIVE';
      case DropPartyStatus.upcoming:
        return 'Upcoming';
      case DropPartyStatus.soldOut:
        return 'Sold Out';
      case DropPartyStatus.ended:
        return 'Ended';
    }
  }

  Widget _pulseDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.2),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Container(
          width: 8 * value,
          height: 8 * value,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: DesignTokens.textWhite,
          ),
        );
      },
      onEnd: () {},
    );
  }
}
