import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/review_reel_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/presentation/screens/tag_products_screen.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';

class ReelPublishedScreen extends StatelessWidget {
  const ReelPublishedScreen({super.key, required this.args});

  final ReviewReelArgs args;

  String _formatAmount(int amount) {
    if (amount >= 1000) {
      final t = amount ~/ 1000;
      final r = (amount % 1000).toString().padLeft(3, '0');
      return '$t,$r';
    }
    return amount.toString();
  }

  static String _svgAsset(SocialPlatform p) {
    switch (p) {
      case SocialPlatform.instagram:
        return 'assets/icons/instagram.svg';
      case SocialPlatform.tiktok:
        return 'assets/icons/tiktok.svg';
      case SocialPlatform.youtube:
        return 'assets/icons/youtube.svg';
      case SocialPlatform.facebook:
        return 'assets/icons/facebook.svg';
    }
  }

  void _showWhatHappensNow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'What happens now ?',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetCtx).pop(),
                    child: const Icon(
                      Icons.close_rounded,
                      color: DesignTokens.textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (final text in const [
                'Your reel will appear in customer feeds',
                'Tagged products shown at bottom of reel in the order you set',
                'You earn commission on every sale',
                'Track performance in real-time',
              ]) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: DesignTokens.textWhite,
                        fontSize: 14,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: DesignTokens.textWhite,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTaggedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TaggedProductsSheet(
        taggedProducts: args.taggedProducts,
        onUntag: (_) {},
        allowUntag: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reel = args.reel;
    final platform = reel?.platform ?? SocialPlatform.instagram;
    final caption = reel?.caption.isNotEmpty == true
        ? reel!.caption
        : 'New Year calls for rich, delicious cakes to celebrate with your near and dear ones in a get together';
    const projectedSales = 50;
    final projectedEarnings = args.potentialEarningsPerSale * projectedSales;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 32),

                  // ── Done icon ─────────────────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/doneicon.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Title ────────────────────────────────────────────────
                  const Text(
                    'Reel Published Successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Reel Summary card ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: DesignTokens.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reel Summary',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: reel?.thumbnailUrl.isNotEmpty == true
                                    ? Image.network(
                                        reel!.thumbnailUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _thumbnailPlaceholder(),
                                      )
                                    : _thumbnailPlaceholder(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: DesignTokens.fontFamily,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: DesignTokens.textWhite,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: SvgPicture.asset(
                                          _svgAsset(platform),
                                          width: 14,
                                          height: 14,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Imported from ${platform.displayName}',
                                        style: DesignTokens.smallRegular
                                            .copyWith(
                                              color: DesignTokens.textMuted,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const _DashedDivider(),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showTaggedSheet(context),
                          behavior: HitTestBehavior.opaque,
                          child: _StatRow(
                            iconWidget: Image.asset(
                              'assets/images/creatordash/material-symbols_package-2-outline.png',
                              width: 18,
                              height: 18,
                            ),
                            label: 'Total Products Tagged',
                            value: '${args.taggedProducts.length}',
                            labelUnderlined: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _StatRow(
                          iconWidget: Image.asset(
                            'assets/images/creatordash/material-symbols_money-bag-outline-rounded.png',
                            width: 18,
                            height: 18,
                          ),
                          label: 'Potential Earnings',
                          value:
                              'Rs ${_formatAmount(projectedEarnings)} with $projectedSales sales',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── What happens now? ────────────────────────────────────
                  GestureDetector(
                    onTap: () => _showWhatHappensNow(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: DesignTokens.cardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.help_outline_rounded,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'What happens now ?',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: DesignTokens.textWhite,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: DesignTokens.textMuted,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 3 action buttons ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          iconWidget: Image.asset(
                            'assets/images/creatordash/Analytics_icon.png',
                            width: 24,
                            height: 24,
                          ),
                          label: 'View\nAnalytics',
                          onTap: args.publishedReelId?.isNotEmpty == true
                              ? () => context.go(
                                  RouteNames.creatorReelAnalyticsDetail
                                      .replaceFirst(
                                        ':reelId',
                                        args.publishedReelId!,
                                      ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          iconWidget: const Icon(
                            Icons.add_rounded,
                            color: DesignTokens.textMuted,
                            size: 24,
                          ),
                          label: 'Import\nAnother Reel',
                          onTap: () => context.go(RouteNames.reelImport),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          iconWidget: const Icon(
                            Icons.play_circle_outline_rounded,
                            color: DesignTokens.textMuted,
                            size: 24,
                          ),
                          label: 'Watch\nReel',
                          onTap: args.reel?.sourceUrl.isNotEmpty == true
                              ? () async {
                                  final source = Uri.tryParse(
                                    args.reel!.sourceUrl,
                                  );
                                  if (source == null || !source.hasScheme) {
                                    return;
                                  }
                                  await const ReelExternalLauncher().open(
                                    source,
                                  );
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Pro Tip ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: DesignTokens.cardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF59E0B,
                            ).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/creatordash/Pro-Tip_Icon.png',
                            width: 20,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pro Tip',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: DesignTokens.textWhite,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Share your reel on ReelCommerce to your followers on other platforms to drive more traffic and sales!',
                                style: TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: DesignTokens.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Go to Dashboard button ───────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            color: DesignTokens.bgAppFoundation,
            child: SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton.icon(
                onPressed: () => context.go(RouteNames.creatorHome),
                icon: const Icon(Icons.home_rounded, size: 20),
                label: const Text('Go to Dashboard'),
                style: DesignTokens.primaryButtonStyle(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _thumbnailPlaceholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF2A1A0A), Color(0xFF0D0D1A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: const Center(
      child: Icon(
        Icons.play_circle_outline_rounded,
        color: Colors.white38,
        size: 24,
      ),
    ),
  );
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconWidget,
    required this.label,
    this.onTap,
  });

  final Widget iconWidget;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textLight,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
              decoration: labelUnderlined ? TextDecoration.underline : null,
              decorationColor: DesignTokens.textLight,
              decorationStyle: labelUnderlined
                  ? TextDecorationStyle.dotted
                  : null,
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
