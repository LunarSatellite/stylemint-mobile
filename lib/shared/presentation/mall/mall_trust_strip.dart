import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_view_models.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Reassurance strip: authenticity, secure checkout, returns and live
/// tracking. Items share the row when they fit, otherwise the strip scrolls
/// horizontally.
class MallTrustStrip extends StatelessWidget {
  const MallTrustStrip({
    super.key,
    this.items = defaultItems,
    this.padding = const EdgeInsetsDirectional.fromSTEB(
      DesignTokens.s16,
      0,
      DesignTokens.s16,
      0,
    ),
  });

  final List<MallTrustItem> items;
  final EdgeInsetsGeometry padding;

  /// English defaults. Pass localised items once l10n lands.
  static const List<MallTrustItem> defaultItems = [
    MallTrustItem(
      icon: Icons.verified_outlined,
      title: 'Authentic products',
      body: 'From verified sellers',
    ),
    MallTrustItem(
      icon: Icons.lock_outline_rounded,
      title: 'Secure checkout',
      body: 'Protected payments',
    ),
    MallTrustItem(
      icon: Icons.assignment_return_outlined,
      title: 'Easy returns',
      body: 'Simple return requests',
    ),
    MallTrustItem(
      icon: Icons.local_shipping_outlined,
      title: 'Live tracking',
      body: 'Follow every delivery',
    ),
  ];

  static const double _itemWidth = 176;
  static const double _gap = 10;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final insets = padding.resolve(Directionality.of(context));
        final needed = items.length * _itemWidth + (items.length - 1) * _gap;
        final fits = constraints.maxWidth - insets.horizontal >= needed;
        final row = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: fits ? MainAxisSize.max : MainAxisSize.min,
            spacing: _gap,
            children: [
              for (final item in items)
                if (fits)
                  Expanded(child: _TrustTile(item: item))
                else
                  SizedBox(
                    width: _itemWidth,
                    child: _TrustTile(item: item),
                  ),
            ],
          ),
        );
        if (fits) return Padding(padding: padding, child: row);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: padding,
          child: row,
        );
      },
    );
  }
}

class _TrustTile extends StatelessWidget {
  const _TrustTile({required this.item});

  final MallTrustItem item;

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: DesignTokens.textMuted,
  );

  @override
  Widget build(BuildContext context) {
    final body = item.body;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryGreenDark,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 34,
                  child: Icon(
                    item.icon,
                    size: 18,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _titleStyle,
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _bodyStyle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
