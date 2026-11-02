import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/data/composed_screen_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/domain/composed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/ask_once_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/presentation/why_strings.dart';
import 'package:stylemint_mobile_frontend/features/customer/composed_screens/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The composer's sections for [request], or nothing.
///
/// The composer is an optional source: while it loads, when it is disabled
/// (`404`), fails, or returns nothing, this draws an empty box and the host
/// screen stays exactly as it was.
class ComposedScreenSlot extends ConsumerWidget {
  const ComposedScreenSlot({required this.request, super.key});

  final ComposedScreenRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composed = ref.watch(composedScreenProvider(request)).value;
    if (composed == null) return const SizedBox.shrink();
    return ComposedSectionsColumn(screen: request.screen, composed: composed);
  }
}

/// Every section of [composed] as horizontal rails, plus the ask-once card
/// when the mall home carries a question.
class ComposedSectionsColumn extends StatelessWidget {
  const ComposedSectionsColumn({
    required this.screen,
    required this.composed,
    super.key,
  });

  final ComposedScreenName screen;
  final ComposedScreen composed;

  @override
  Widget build(BuildContext context) {
    final question = composed.question;
    return Column(
      key: const ValueKey('composed-sections'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question != null && screen == ComposedScreenName.mallHome)
          AskOnceCard(question: question),
        for (final section in composed.sections)
          ComposedSectionRail(
            key: ValueKey('composed-section-${section.sectionId}'),
            screen: screen,
            requestId: composed.requestId,
            section: section,
          ),
        if (screen == ComposedScreenName.mallHome) const _ForYouLinks(),
      ],
    );
  }
}

/// Entry points to the composer-only lists, shown only when the composer is
/// live (this column is never drawn otherwise).
class _ForYouLinks extends StatelessWidget {
  const _ForYouLinks();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesignTokens.s16,
      DesignTokens.s16,
      DesignTokens.s16,
      0,
    ),
    child: Wrap(
      spacing: DesignTokens.s8,
      runSpacing: DesignTokens.s8,
      children: [
        for (final (label, route) in const [
          ('Creators for you', RouteNames.creatorsForYou),
          ('Shops for you', RouteNames.shopsForYou),
          ('Brands for you', RouteNames.brandsForYou),
        ])
          ActionChip(
            label: Text(label),
            onPressed: () => unawaited(context.push(route)),
          ),
      ],
    ),
  );
}

/// Shows why [reasonKey] put something on screen.
Future<void> showWhySheet(BuildContext context, String? reasonKey) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s20,
            0,
            DesignTokens.s20,
            DesignTokens.s20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                WhyStrings.of(sheetContext, 'why.title')!,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignTokens.s12),
              Text(
                WhyStrings.reason(sheetContext, reasonKey),
                key: const ValueKey('why-reason'),
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                WhyStrings.of(sheetContext, 'prefs.privacy')!,
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: DesignTokens.s8),
              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(context.push(RouteNames.settingsPreferences));
                },
                child: Text(WhyStrings.of(sheetContext, 'why.manage')!),
              ),
            ],
          ),
        ),
      ),
    );

/// One composer section: a titled rail drawn with the app's card widgets.
class ComposedSectionRail extends ConsumerWidget {
  const ComposedSectionRail({
    required this.screen,
    required this.section,
    super.key,
    this.requestId,
  });

  final ComposedScreenName screen;
  final ComposedSection section;
  final String? requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = section.title.isEmpty ? 'From the Mall' : section.title;
    final why = WhyStrings.of(context, 'why.title')!;
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onLongPress: () =>
                unawaited(showWhySheet(context, section.reasonKey)),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                DesignTokens.s16,
                0,
                DesignTokens.s4,
                DesignTokens.s8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: ValueKey('why-${section.sectionId}'),
                    tooltip: why,
                    icon: const Icon(Icons.info_outline, size: 20),
                    onPressed: () =>
                        unawaited(showWhySheet(context, section.reasonKey)),
                  ),
                ],
              ),
            ),
          ),
          _rail(context, ref, title),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, ComposedItem item, Widget child) =>
      GestureDetector(
        key: ValueKey('composed-item-${section.sectionId}-${item.id}'),
        onLongPress: () => unawaited(
          showWhySheet(context, item.reasonKey ?? section.reasonKey),
        ),
        child: child,
      );

  void _openProduct(BuildContext context, WidgetRef ref, ComposedItem item) {
    ref
        .read(engagementTrackerProvider)
        .screenItemOpened(
          productId: item.id,
          screen: screen.wire,
          requestId: requestId,
          position: item.position,
          sectionId: section.sectionId,
        );
    unawaited(context.push(MallRoutes.product(item.id)));
  }

  Widget _rail(BuildContext context, WidgetRef ref, String title) {
    final items = section.items;
    switch (section.kind) {
      case ComposedSectionKind.products:
        const width = MallProductTile.compactWidth;
        return MallRail<ComposedItem>(
          items: items,
          itemWidth: width,
          height: MallProductTile.heightFor(
            context,
            width: width,
            size: MallCardSize.compact,
          ),
          semanticLabel: title,
          itemBuilder: (context, item, _) => _item(
            context,
            item,
            MallProductTile(
              product: (item.card as HomeProduct).toVm(),
              size: MallCardSize.compact,
              onTap: () => _openProduct(context, ref, item),
            ),
          ),
        );
      case ComposedSectionKind.reels:
        return MallRail<ComposedItem>(
          items: items,
          itemWidth: MallReelCard.compactWidth,
          height: MallReelCard.heightFor(MallReelCard.compactWidth),
          semanticLabel: title,
          itemBuilder: (context, item, _) {
            final reel = item.card as HomeReel;
            return _item(
              context,
              item,
              MallReelCard(
                reel: reel.toVm(),
                onTap: () =>
                    unawaited(openMallReelWindow(context, reel.toRef())),
              ),
            );
          },
        );
      case ComposedSectionKind.creators:
        return MallRail<ComposedItem>(
          items: items,
          itemWidth: MallCreatorCard.defaultWidth,
          height: MallCreatorCard.heightFor(context, hasFollowAction: false),
          semanticLabel: title,
          itemBuilder: (context, item, _) {
            final creator = item.card as HomeCreator;
            return _item(
              context,
              item,
              MallCreatorCard(
                creator: creator.toVm(),
                onTap: () => unawaited(
                  context.push(MallRoutes.creator(creator.accountId)),
                ),
              ),
            );
          },
        );
      case ComposedSectionKind.vendors || ComposedSectionKind.brands:
        return MallRail<ComposedItem>(
          items: items,
          itemWidth: MallBrandCard.defaultWidth,
          height: MallBrandCard.heightFor(
            context,
            width: MallBrandCard.defaultWidth,
          ),
          semanticLabel: title,
          itemBuilder: (context, item, _) {
            final brand = item.card as HomeBrand;
            return _item(
              context,
              item,
              MallBrandCard(
                brand: brand.toVm(),
                onTap: () => unawaited(
                  context.push(
                    MallRoutes.brand(brand.vendorAccountId, brand.name),
                  ),
                ),
              ),
            );
          },
        );
    }
  }
}
