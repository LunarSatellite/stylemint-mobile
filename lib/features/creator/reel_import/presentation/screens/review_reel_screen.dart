import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/notifiers/reel_import_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReviewReelArgs {
  const ReviewReelArgs({
    required this.reel,
    required this.taggedProducts,
    required this.potentialEarningsPerSale,
  });

  final ImportableReel? reel;
  final List<TaggedProductForImport> taggedProducts;
  final int potentialEarningsPerSale;
}

class ReviewReelScreen extends ConsumerStatefulWidget {
  const ReviewReelScreen({super.key, required this.args});

  final ReviewReelArgs args;

  @override
  ConsumerState<ReviewReelScreen> createState() => _ReviewReelScreenState();
}

class _ReviewReelScreenState extends ConsumerState<ReviewReelScreen> {
  late final List<TaggedProductForImport> _taggedProducts;

  @override
  void initState() {
    super.initState();
    _taggedProducts = List.from(widget.args.taggedProducts);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listenManual<ReelSubmitState>(
      reelSubmitNotifierProvider,
      (previous, next) {
        if (next is ReelSubmitSuccess) {
          context.pushReplacement(RouteNames.reelPublished, extra: widget.args);
        } else if (next is ReelSubmitFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      final t = amount ~/ 1000;
      final r = (amount % 1000).toString().padLeft(3, '0');
      return '$t,$r';
    }
    return amount.toString();
  }

  void _showTaggedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaggedProductsSheet(
        taggedProducts: List.from(_taggedProducts),
        onUntag: (_) {},
        allowUntag: false,
      ),
    );
  }

  static String _svgAsset(SocialPlatform p) {
    switch (p) {
      case SocialPlatform.instagram: return 'assets/icons/instagram.svg';
      case SocialPlatform.tiktok:    return 'assets/icons/tiktok.svg';
      case SocialPlatform.youtube:   return 'assets/icons/youtube.svg';
      case SocialPlatform.facebook:  return 'assets/icons/facebook.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.args.reel;
    final totalDuration = reel?.videoDuration ?? 55;
    final elapsed = (totalDuration * 0.78).toInt();
    final caption = reel?.caption.isNotEmpty == true
        ? reel!.caption
        : 'New Year calls for rich, delicious cakes to celebrate with your near and dear ones in a get together';
    final platform = reel?.platform ?? SocialPlatform.instagram;
    const projectedSales = 50;
    final projectedEarnings = widget.args.potentialEarningsPerSale * projectedSales;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Review Details', style: DesignTokens.titleMedium),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16, DesignTokens.s8,
                DesignTokens.s16, DesignTokens.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Video thumbnail ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: _VideoThumbnail(
                      thumbnailUrl: reel?.thumbnailUrl ?? '',
                      elapsed: elapsed,
                      total: totalDuration,
                      formatDuration: _formatDuration,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s16),

                  // ── Reel details card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    decoration: DesignTokens.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reel Details',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        Text(
                          caption,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textWhite,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s12),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SvgPicture.asset(
                                _svgAsset(platform),
                                width: 20,
                                height: 20,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.s8),
                            Text(
                              'Imported from ${platform.displayName}',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.s16),
                        const _DashedDivider(),
                        const SizedBox(height: DesignTokens.s16),
                        // Total Products Tagged — tappable
                        GestureDetector(
                          onTap: _showTaggedSheet,
                          behavior: HitTestBehavior.opaque,
                          child: _StatRow(
                            iconWidget: Image.asset(
                              'assets/images/creatordash/material-symbols_package-2-outline.png',
                              width: 18,
                              height: 18,
                            ),
                            label: 'Total Products Tagged',
                            value: '${_taggedProducts.length}',
                            labelUnderlined: true,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s12),
                        _StatRow(
                          iconWidget: Image.asset(
                            'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
                            width: 18,
                            height: 18,
                          ),
                          label: 'Potential Earnings',
                          value: 'Rs ${_formatAmount(projectedEarnings)} with $projectedSales sales',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Share Reel button ────────────────────────────────────────────
          Consumer(
            builder: (context, ref, _) {
              final submitState = ref.watch(reelSubmitNotifierProvider);
              final isLoading = submitState is ReelSubmitInProgress;
              return Container(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s8,
                  DesignTokens.s16, DesignTokens.s24,
                ),
                color: DesignTokens.bgAppFoundation,
                child: SizedBox(
                  width: double.infinity,
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            final reel = widget.args.reel;
                            if (reel == null) return;
                            ref
                                .read(reelSubmitNotifierProvider.notifier)
                                .submit(reel, _taggedProducts);
                          },
                    style: DesignTokens.primaryButtonStyle(),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Share Reel'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Video thumbnail ───────────────────────────────────────────────────────────

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({
    required this.thumbnailUrl,
    required this.elapsed,
    required this.total,
    required this.formatDuration,
  });

  final String thumbnailUrl;
  final int elapsed;
  final int total;
  final String Function(int) formatDuration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            thumbnailUrl.isNotEmpty
                ? Image.network(thumbnailUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _bg())
                : _bg(),
            // Duration badge
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${formatDuration(elapsed)} / ${formatDuration(total)}',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bg() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2A1A0A), Color(0xFF0D0D1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 56,
          ),
        ),
      );
}

// ── Stat row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.iconWidget,
    required this.label,
    required this.value,
    this.labelUnderlined = false,
  });

  final Widget iconWidget;
  final String label;
  final String value;
  final bool labelUnderlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        iconWidget,
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
              decoration: labelUnderlined ? TextDecoration.underline : null,
              decorationColor: DesignTokens.textLight,
              decorationStyle: labelUnderlined ? TextDecorationStyle.dotted : null,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

// ── Dashed divider ────────────────────────────────────────────────────────────

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedPainter()),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 1;
    const dashW = 6.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashW, 0), paint);
      x += dashW + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
