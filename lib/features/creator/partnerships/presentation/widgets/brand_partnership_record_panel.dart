import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/widgets/brand_partnership_record_view.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Loads a brand's partnership record and hands it to
/// [BrandPartnershipRecordView].
///
/// ## The two ids
///
/// The brand catalog (`GET /v1/brands`) is keyed by the vendor's **account**
/// id, and that is what every brand card carries. The partnership record —
/// like the partnership rows behind it — is keyed by the vendor's
/// **profile** id. The retired trust endpoint documented an account id,
/// accepted whichever id it was handed and created a row for it, so the two
/// never visibly disagreed while both were wrong.
///
/// So this resolves one to the other rather than guessing: the brand detail
/// response carries the profile id as its `id`, and the record is fetched
/// with that. While detail is in flight the record has no id to ask for and
/// this shows the loading state, not an empty one.
class BrandPartnershipRecordPanel extends ConsumerWidget {
  const BrandPartnershipRecordPanel({
    required this.vendorAccountId,
    super.key,
  });

  /// The vendor account id the brand card carried in.
  final String vendorAccountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vendorAccountId.isEmpty) {
      return const _RecordMessage(
        title: 'No brand selected',
        body: 'This screen was opened without a brand, so there is no record '
            'to look up.',
        icon: Icons.fact_check_outlined,
      );
    }

    final detailAsync = ref.watch(brandDetailProvider(vendorAccountId));

    return detailAsync.when(
      loading: () => const _RecordSkeleton(),
      error: (_, _) => _RecordMessage(
        title: "We couldn't load this brand's record",
        body: 'Check your connection and try again.',
        icon: Icons.cloud_off_rounded,
        onRetry: () => ref.invalidate(brandDetailProvider(vendorAccountId)),
      ),
      data: (detail) {
        final vendorProfileId = detail.id;
        if (vendorProfileId.isEmpty) {
          return const _RecordMessage(
            title: 'Nothing recorded yet',
            body: 'StyleMint holds no partnership record for this brand.',
            icon: Icons.fact_check_outlined,
          );
        }
        final recordAsync = ref.watch(
          brandPartnershipRecordProvider(vendorProfileId),
        );
        return recordAsync.when(
          loading: () => const _RecordSkeleton(),
          error: (_, _) => _RecordMessage(
            title: "We couldn't load this brand's record",
            body: 'Check your connection and try again.',
            icon: Icons.cloud_off_rounded,
            onRetry: () => ref.invalidate(
              brandPartnershipRecordProvider(vendorProfileId),
            ),
          ),
          data: (record) => BrandPartnershipRecordView(record: record),
        );
      },
    );
  }
}

/// A calm message, used for both the failure and the no-brand case.
///
/// [MallErrorState] without a retry is the same block minus the action, so
/// one widget covers "this did not load" and "there is nothing to look up"
/// without either borrowing the other's tone.
class _RecordMessage extends StatelessWidget {
  const _RecordMessage({
    required this.title,
    required this.body,
    required this.icon,
    this.onRetry,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
    children: [
      MallErrorState(title: title, body: body, icon: icon, onRetry: onRetry),
    ],
  );
}

/// The shape of the record while it loads, so the block does not jump when
/// the figures land. Announced as loading; the bars themselves are hidden
/// from assistive technology.
class _RecordSkeleton extends StatelessWidget {
  const _RecordSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading the partnership record',
      child: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: const [
          SmSkeleton.line(width: 120, height: 10),
          SizedBox(height: DesignTokens.s12),
          SmSkeleton.line(width: 220, height: 22),
          SizedBox(height: DesignTokens.s20),
          SmSkeleton.line(height: 14),
          SizedBox(height: DesignTokens.s8),
          SmSkeleton.line(width: 260, height: 14),
          SizedBox(height: DesignTokens.s24),
          SmSkeleton.line(height: 14),
          SizedBox(height: DesignTokens.s8),
          SmSkeleton.line(width: 200, height: 14),
          SizedBox(height: DesignTokens.s24),
          SmSkeleton.line(height: 14),
          SizedBox(height: DesignTokens.s8),
          SmSkeleton.line(width: 180, height: 14),
        ],
      ),
    );
  }
}
