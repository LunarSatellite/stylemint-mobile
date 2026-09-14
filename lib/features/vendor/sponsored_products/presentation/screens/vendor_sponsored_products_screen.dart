import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/presentation/widgets/sponsor_product_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

const sponsoredProductsIntro =
    'Sponsored products can appear once per search, labelled Sponsored, only '
    'when they match what the shopper searched for and are in stock.';

/// Voyager "Transparent Sponsored Product Boosting" for vendors: each
/// sponsored product with how often search showed it and how its sales moved,
/// plus Pause, Change and Restart. Backed by `/v1/vendor/store/sponsored`.
class VendorSponsoredProductsScreen extends ConsumerWidget {
  const VendorSponsoredProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sponsoredProductsNotifierProvider);
    final notifier = ref.read(sponsoredProductsNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 18,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Sponsored products',
          style: DesignTokens.oneLinerSemibold,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          SponsoredProductsLoading() => const SmPageLoader(),
          SponsoredProductsFailed() => SmErrorView(
            message: 'Could not load your sponsored products.',
            onRetry: notifier.load,
          ),
          SponsoredProductsLoaded(:final listings, :final pausing) =>
            RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: notifier.refresh,
              child: _SponsoredList(
                listings: listings,
                pausing: pausing,
                onSponsor: () => _openForm(context, notifier),
                onChange: (listing) =>
                    _openForm(context, notifier, existing: listing),
                onPause: (listing) => _pause(context, notifier, listing),
              ),
            ),
        },
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    SponsoredProductsNotifier notifier, {
    SponsoredListing? existing,
  }) async {
    final result = await showSponsorProductSheet(
      context,
      onSubmit: notifier.sponsor,
      existing: existing,
    );
    if (result == null || !context.mounted) return;
    _showMessage(context, sponsorFormResultMessage(result));
  }

  Future<void> _pause(
    BuildContext context,
    SponsoredProductsNotifier notifier,
    SponsoredListing listing,
  ) async {
    final failure = await notifier.pause(listing.productId);
    if (failure == null || !context.mounted) return;
    _showMessage(context, sponsoredProductsErrorMessage(failure));
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SponsoredList extends StatelessWidget {
  const _SponsoredList({
    required this.listings,
    required this.pausing,
    required this.onSponsor,
    required this.onChange,
    required this.onPause,
  });

  final List<SponsoredListing> listings;
  final Set<String> pausing;
  final VoidCallback onSponsor;
  final ValueChanged<SponsoredListing> onChange;
  final ValueChanged<SponsoredListing> onPause;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      children: [
        Text(
          sponsoredProductsIntro,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        if (listings.isEmpty)
          _EmptyState(onSponsor: onSponsor)
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onSponsor,
              style: DesignTokens.outlinedButtonStyle(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Sponsor a product',
                style: DesignTokens.smallRegular.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          for (final listing in listings) ...[
            const SizedBox(height: DesignTokens.s12),
            SponsoredListingCard(
              key: ValueKey('sponsored-listing-${listing.productId}'),
              listing: listing,
              isPausing: pausing.contains(listing.productId),
              onPause: () => onPause(listing),
              onChange: () => onChange(listing),
            ),
          ],
        ],
      ],
    );
  }
}

class SponsoredListingCard extends StatelessWidget {
  const SponsoredListingCard({
    required this.listing,
    required this.isPausing,
    required this.onPause,
    required this.onChange,
    super.key,
  });

  final SponsoredListing listing;
  final bool isPausing;
  final VoidCallback onPause;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final status = listing.status;
    final schedule = sponsorshipScheduleLine(listing);
    final note = listing.salesComparisonNote;
    final disclosure = listing.disclosure;
    final bodyStyle = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textLight,
    );
    final mutedStyle = DesignTokens.smallRegular.copyWith(
      color: DesignTokens.textMuted,
    );

    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  listing.productName.isEmpty
                      ? 'Unnamed product'
                      : listing.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              SponsorshipStatusChip(status: status),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(sponsoredViewsLine(listing), style: bodyStyle),
          const SizedBox(height: DesignTokens.s4),
          Text(sponsoredSalesLine(listing), style: bodyStyle),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
          if (schedule != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(schedule, style: mutedStyle),
          ],
          if (disclosure.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(disclosure, style: mutedStyle),
          ],
          const SizedBox(height: DesignTokens.s12),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: [
              if (status == SponsorshipStatus.live) ...[
                _CardButton(
                  label: isPausing ? 'Pausing…' : 'Pause',
                  onPressed: isPausing ? null : onPause,
                ),
                _CardButton(label: 'Change', onPressed: onChange),
              ] else
                _CardButton(label: 'Restart', onPressed: onChange),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: DesignTokens.outlinedButtonStyle(),
      child: Text(
        label,
        style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class SponsorshipStatusChip extends StatelessWidget {
  const SponsorshipStatusChip({required this.status, super.key});

  final SponsorshipStatus status;

  @override
  Widget build(BuildContext context) {
    final color = sponsorshipStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        sponsorshipStatusLabel(status),
        style: DesignTokens.smallRegular.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSponsor});

  final VoidCallback onSponsor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s32),
      child: Column(
        children: [
          const Icon(
            Icons.campaign_outlined,
            size: 56,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            "You aren't sponsoring any products yet.",
            textAlign: TextAlign.center,
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          ElevatedButton(
            onPressed: onSponsor,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              foregroundColor: Colors.black,
              elevation: 0,
              minimumSize: const Size(0, DesignTokens.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
            ),
            child: const Text('Sponsor a product'),
          ),
        ],
      ),
    );
  }
}

final _countFormat = NumberFormat.decimalPattern('en');

String _count(int value) => _countFormat.format(value);

/// "Shown 3 times today · 41 this week".
String sponsoredViewsLine(SponsoredListing listing) {
  final today = listing.impressionsToday;
  return 'Shown ${_count(today)} ${today == 1 ? 'time' : 'times'} today · '
      '${_count(listing.impressionsLast7Days)} this week';
}

/// "Sold 12 in the last 7 days (8 the week before)".
String sponsoredSalesLine(SponsoredListing listing) =>
    'Sold ${_count(listing.unitsSoldLast7Days)} in the last 7 days '
    '(${_count(listing.unitsSoldPrevious7Days)} the week before)';

/// When it stops, for live and ended sponsorships; null when paused.
String? sponsorshipScheduleLine(SponsoredListing listing) {
  final ends = listing.endsUtc;
  return switch (listing.status) {
    SponsorshipStatus.live when ends == null => 'Runs until you pause it',
    SponsorshipStatus.live =>
      'Runs through ${formatSponsorshipDay(sponsorshipLastDay(ends!))}',
    SponsorshipStatus.ended when ends != null =>
      'Ran through ${formatSponsorshipDay(sponsorshipLastDay(ends))}',
    _ => null,
  };
}

String sponsorshipStatusLabel(SponsorshipStatus status) => switch (status) {
  SponsorshipStatus.live => 'Live',
  SponsorshipStatus.paused => 'Paused',
  SponsorshipStatus.ended => 'Ended',
};

Color sponsorshipStatusColor(SponsorshipStatus status) => switch (status) {
  SponsorshipStatus.live => DesignTokens.primaryGreen,
  SponsorshipStatus.paused => DesignTokens.warning500,
  SponsorshipStatus.ended => DesignTokens.textMuted,
};
