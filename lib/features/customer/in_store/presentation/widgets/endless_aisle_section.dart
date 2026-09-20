import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// **The endless aisle** — what a shopper standing in a shop with a scanned
/// code can still do when the shelf in front of them is not the whole story.
///
/// ## What it says, and what it refuses to say
///
/// It says the two things `GET v1/public/codes/{code}/endless-aisle` can
/// honestly report: that the item can be ordered from wherever they are, and
/// where the seller's recorded collection points are.
///
/// It refuses to say what any of those places holds. Stock in this platform
/// is one pool per item, not one per location, so "this shop has one" and
/// "this shop has none" are both inventions. The backend's own note says so
/// in words, and this widget prints that note rather than paraphrasing it.
class EndlessAisleSection extends ConsumerWidget {
  const EndlessAisleSection({required this.code, super.key});

  static const String title = 'Not on the shelf? Still yours';
  static const String failedText =
      "Couldn't check what else is available here.";
  static const String retryLabel = 'Try again';

  /// The scanned code. An empty one draws nothing.
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();
    final provider = endlessAisleNotifierProvider(trimmed);
    final state = ref.watch(provider);

    return switch (state) {
      EndlessAisleLoading() => const _Frame(
        child: SizedBox(height: 64, child: SmPageLoader(size: 32)),
      ),
      // Nothing to show, and nothing went wrong: no shell, no placeholder.
      EndlessAisleUnavailable() => const SizedBox.shrink(),
      EndlessAisleFailed() => _Frame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              failedText,
              key: ValueKey('endless-aisle-failed'),
              style: DesignTokens.smallDescription,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => unawaited(ref.read(provider.notifier).load()),
                style: DesignTokens.textButtonStyle(),
                child: const Text(retryLabel),
              ),
            ),
          ],
        ),
      ),
      EndlessAisleLoaded(:final aisle) => _Loaded(aisle: aisle),
    };
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('endless-aisle-section'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: DesignTokens.cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: const Text(
            EndlessAisleSection.title,
            style: DesignTokens.sectionInnerTitle,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        child,
      ],
    ),
  );
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.aisle});

  final EndlessAisle aisle;

  @override
  Widget build(BuildContext context) => _Frame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Reach. The distinction the backend does draw: whether there is
        //    one orderable item behind this code, or a whole catalogue.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              aisle.canOrderFromAnywhere
                  ? Icons.local_shipping_outlined
                  : Icons.storefront_outlined,
              size: 18,
              color: DesignTokens.primaryGreen,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(
                aisle.reachNote,
                key: const ValueKey('endless-aisle-reach'),
                style: DesignTokens.mediumRegular,
              ),
            ),
          ],
        ),

        // 2. The thing this platform cannot tell them, said out loud rather
        //    than filled in. Absent stays absent.
        if (aisle.inStoreAvailabilityNote.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          _Note(
            key: const ValueKey('endless-aisle-stock-unknown'),
            icon: Icons.help_outline_rounded,
            text: aisle.inStoreAvailabilityNote,
          ),
        ],

        // 3. Collection, when the seller offers it at all.
        if (aisle.pickupNote.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(
            aisle.pickupNote,
            key: const ValueKey('endless-aisle-pickup-note'),
            style: DesignTokens.smallDescription,
          ),
        ],
        for (final location in aisle.pickupLocations) ...[
          const SizedBox(height: DesignTokens.s12),
          _LocationCard(location: location),
        ],
      ],
    ),
  );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final PickupLocation location;

  @override
  Widget build(BuildContext context) {
    final address = location.addressSummary;
    final hours = location.openingHours;
    return Container(
      key: ValueKey('endless-aisle-location-${location.locationId}'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (location.name.isNotEmpty)
            Text(location.name, style: DesignTokens.mediumSemibold),
          if (address.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(address, style: DesignTokens.smallDescription),
          ],
          // Null hours draw nothing. A shop with no hours recorded is not a
          // shop that is always open.
          if (hours != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text('Opening hours: $hours', style: DesignTokens.smallDescription),
          ],
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: MallStatusPill(
              label: _confirmationLabel(location.confirmationState),
              tone: _confirmationTone(location.confirmationState),
              icon: _confirmationIcon(location.confirmationState),
              dense: true,
            ),
          ),
          if (location.confirmationNote.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              location.confirmationNote,
              style: DesignTokens.smallDescription,
            ),
          ],
          if (location.stockAvailabilityNote.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            _Note(
              icon: Icons.help_outline_rounded,
              text: location.stockAvailabilityNote,
            ),
          ],
        ],
      ),
    );
  }

  static String _confirmationLabel(LocationConfirmationState state) =>
      switch (state) {
        LocationConfirmationState.neverConfirmed => 'Never confirmed',
        LocationConfirmationState.confirmed => 'Confirmed by the seller',
        LocationConfirmationState.stale => 'Not confirmed recently',
        LocationConfirmationState.unrecognised => 'Unrecognised state',
      };

  static MallStatusTone _confirmationTone(LocationConfirmationState state) =>
      switch (state) {
        LocationConfirmationState.neverConfirmed => MallStatusTone.caution,
        LocationConfirmationState.confirmed => MallStatusTone.success,
        LocationConfirmationState.stale => MallStatusTone.caution,
        LocationConfirmationState.unrecognised => MallStatusTone.neutral,
      };

  static IconData _confirmationIcon(LocationConfirmationState state) =>
      switch (state) {
        LocationConfirmationState.neverConfirmed => Icons.help_outline_rounded,
        LocationConfirmationState.confirmed =>
          Icons.check_circle_outline_rounded,
        LocationConfirmationState.stale => Icons.schedule_rounded,
        LocationConfirmationState.unrecognised => Icons.help_outline_rounded,
      };
}

/// A muted aside carrying one of the backend's own sentences.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: DesignTokens.textMuted),
      const SizedBox(width: DesignTokens.s8),
      Expanded(child: Text(text, style: DesignTokens.smallDescription)),
    ],
  );
}
