import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The wizard's "Try-on & sizes" step, shown on Review.
///
/// Size charts and try-on images belong to a product id, so for a product
/// that has never been saved, [ensureProductId] saves the draft first.
class TryOnWizardCard extends ConsumerWidget {
  const TryOnWizardCard({
    required this.productId,
    required this.ensureProductId,
    required this.apparel,
    this.categoryName,
    super.key,
  });

  final String? productId;
  final Future<String?> Function() ensureProductId;
  final bool apparel;
  final String? categoryName;

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final id = productId ?? await ensureProductId();
    if (!context.mounted) return;
    if (id == null) {
      SmSnackbar.error(context, 'Save the draft first, then set up try-on.');
      return;
    }
    await context.push(
      RouteNames.vendorProductTryOnPath(id),
      extra: categoryName,
    );
    ref.invalidate(vendorTryOnReadinessProvider(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    final readiness = id == null
        ? null
        : ref.watch(vendorTryOnReadinessProvider(id)).asData?.value;
    final hasChart = readiness?.hasSizeChart ?? false;
    final hasImage = readiness?.hasTryOnImage ?? false;

    return Container(
      key: const Key('wizard-try-on-card'),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: apparel && !hasChart
              ? DesignTokens.colorWarning
              : DesignTokens.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s8),
              Text(
                'Try-on & sizes',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              const Spacer(),
              if (readiness?.ready ?? false)
                const Chip(
                  label: Text('Ready'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            '${hasChart ? '✓' : '✗'} Size chart${apparel ? ' (required)' : ''}   '
            '${hasImage ? '✓' : '✗'} Try-on image (recommended)',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          TextButton(
            onPressed: () => unawaited(_open(context, ref)),
            child: Text(
              hasChart || hasImage
                  ? 'Edit try-on & sizes'
                  : 'Set up try-on & sizes',
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs before Publish. Apparel without a size chart is blocked with a
/// clear message; a missing try-on image only asks for confirmation.
/// Returns true when publishing may go ahead.
Future<bool> tryOnPublishGate(
  BuildContext context,
  WidgetRef ref, {
  required String? productId,
  required bool apparel,
}) async {
  if (!apparel) return true;
  const blocked =
      'Add a size chart before publishing — buyers of clothing and shoes '
      'need it to pick their size. Open "Try-on & sizes" above.';
  if (productId == null) {
    SmSnackbar.error(context, blocked, seconds: 6);
    return false;
  }
  final result = await ref
      .read(vendorTryOnRepositoryProvider)
      .getReadiness(productId);
  if (!context.mounted) return false;
  final TryOnReadiness? readiness = result.fold((_) => null, (r) => r);
  if (readiness == null) {
    SmSnackbar.error(
      context,
      'Could not check the size chart. Please try again.',
    );
    return false;
  }
  if (!readiness.hasSizeChart) {
    SmSnackbar.error(context, blocked, seconds: 6);
    return false;
  }
  if (readiness.hasTryOnImage) return true;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: const Text(
        'Publish without a try-on image?',
        style: TextStyle(color: DesignTokens.textWhite),
      ),
      content: const Text(
        'Buyers will get size advice but cannot see the item on themselves. '
        'You can add the image later.',
        style: TextStyle(color: DesignTokens.textLight),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Add image first'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Publish anyway'),
        ),
      ],
    ),
  );
  return go ?? false;
}
