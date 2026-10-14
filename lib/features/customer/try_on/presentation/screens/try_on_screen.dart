import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/size_variant_matcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/fit_panel.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/live_try_on_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/photo_try_on_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Virtual try-on for one product: LIVE selfie camera or a PHOTO, the
/// "Size & fit" panel, and "Add to cart in size X".
class TryOnScreen extends ConsumerStatefulWidget {
  const TryOnScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends ConsumerState<TryOnScreen> {
  TryOnMode _mode = TryOnMode.liveCamera;
  String? _size;
  final Set<TryOnMode> _recorded = {};
  bool _adding = false;

  /// Usage log, once per mode per visit. Best effort: a failed log never
  /// interrupts the try-on.
  void _recordSession(TryOnMode mode) {
    if (!_recorded.add(mode)) return;
    unawaited(
      ref
          .read(tryOnRepositoryProvider)
          .recordSession(
            productId: widget.productId,
            mode: mode,
            chosenSize: _size,
            idempotencyKey: const Uuid().v4(),
          ),
    );
  }

  Future<void> _openPaywall() async {
    final unlocked = await context.push<bool>(RouteNames.tryOnPaywall);
    if (unlocked ?? false)
      ref.invalidate(tryOnProductProvider(widget.productId));
  }

  void _openFit(TryOnProduct? product) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: DesignTokens.bgAppBody,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (ctx, setSheet) => Padding(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: SingleChildScrollView(
              child: FitPanel(
                productId: widget.productId,
                selectedSize: _size,
                chartSizes: product?.sizeChart?.sizeLabels ?? const [],
                onSizeSelected: (s) {
                  setState(() => _size = s);
                  setSheet(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    final size = _size;
    if (size == null) return;
    final detail = ref
        .read(productDetailNotifierProvider(widget.productId))
        .maybeWhen(loadSuccess: (p) => p, orElse: () => null);
    final variantId = detail == null ? null : variantIdForSize(detail, size);
    if (variantId == null) {
      SmSnackbar.error(
        context,
        'Size $size is not available to buy right now.',
      );
      return;
    }
    setState(() => _adding = true);
    final ok = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .addToCart(productId: widget.productId, qty: 1, variantId: variantId);
    if (!mounted) return;
    setState(() => _adding = false);
    if (ok) {
      unawaited(ref.read(cartNotifierProvider.notifier).fetchCart());
      SmSnackbar.success(context, 'Added size $size to your cart');
    } else {
      SmSnackbar.error(context, "Couldn't add this item. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(tryOnProductProvider(widget.productId));
    final product = productAsync.asData?.value;
    final failure = switch (productAsync.error) {
      final TryOnLoadException e => e.failure,
      null => null,
      _ => const TryOnFailure(TryOnFailureKind.unknown),
    };

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: Text(
          product?.name ?? 'Try it on',
          style: DesignTokens.sectionInnerTitle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: productAsync.isLoading && product == null
          ? const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            )
          : failure != null
          ? _FailureView(
              failure: failure,
              onUnlock: _openPaywall,
              onFitOnly: () => _openFit(null),
              onRetry: () =>
                  ref.invalidate(tryOnProductProvider(widget.productId)),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s8,
                  ),
                  child: SegmentedButton<TryOnMode>(
                    segments: const [
                      ButtonSegment(
                        value: TryOnMode.liveCamera,
                        icon: Icon(Icons.videocam_outlined),
                        label: Text('Live'),
                      ),
                      ButtonSegment(
                        value: TryOnMode.photo,
                        icon: Icon(Icons.photo_outlined),
                        label: Text('Photo'),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                ),
                Expanded(
                  child: _mode == TryOnMode.liveCamera
                      ? LiveTryOnView(
                          key: const ValueKey('live'),
                          product: product!,
                          onStarted: () => _recordSession(TryOnMode.liveCamera),
                        )
                      : PhotoTryOnView(
                          key: const ValueKey('photo'),
                          product: product!,
                          onStarted: () => _recordSession(TryOnMode.photo),
                        ),
                ),
                if (product.disclaimer.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                    ),
                    child: Text(
                      product.disclaimer,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
                _BottomBar(
                  size: _size,
                  adding: _adding,
                  onFit: () => _openFit(product),
                  onAdd: () => unawaited(_addToCart()),
                ),
              ],
            ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.size,
    required this.adding,
    required this.onFit,
    required this.onAdd,
  });

  final String? size;
  final bool adding;
  final VoidCallback onFit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onFit,
                icon: const Icon(Icons.straighten_rounded),
                label: Text(size == null ? 'Size & fit' : 'Size: $size'),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: adding ? null : (size == null ? onFit : onAdd),
                child: Text(
                  size == null ? 'Find my size' : 'Add to cart in size $size',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.failure,
    required this.onUnlock,
    required this.onFitOnly,
    required this.onRetry,
  });

  final TryOnFailure failure;
  final VoidCallback onUnlock;
  final VoidCallback onFitOnly;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final (
      String message,
      String label,
      VoidCallback action,
    ) = switch (failure.kind) {
      TryOnFailureKind.noAccess => (
        failure.displayMessage,
        'See plans',
        onUnlock,
      ),
      TryOnFailureKind.notFound => (
        "Try-on isn't available for this item yet, but we can still help "
            'you pick a size.',
        'Find my size',
        onFitOnly,
      ),
      _ => (failure.displayMessage, 'Retry', onRetry),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
            if (failure.kind != TryOnFailureKind.disabled) ...[
              const SizedBox(height: DesignTokens.s16),
              ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: action,
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
