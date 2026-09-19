import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/notifiers/mission_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/screens/missions_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/widgets/mission_budget_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One mission, as a working checklist.
///
/// Each row is a planned item the shopper can mark already-owned or acquired.
/// Marking is a record of what the shopper did — it buys nothing, reserves
/// nothing and moves no money. The product page is one tap away for ordinary
/// shopping, and this screen never stands between the shopper and it.
///
/// A completed or abandoned mission is closed: the controls are gone and the
/// screen says why rather than offering an action that would 409.
class MissionDetailScreen extends ConsumerStatefulWidget {
  const MissionDetailScreen({required this.missionId, super.key});

  final String missionId;

  static const Key checklistKey = Key('mission-checklist');
  static const Key replanKey = Key('mission-replan');
  static const Key completeKey = Key('mission-complete');
  static const Key abandonKey = Key('mission-abandon');
  static const Key closedNoticeKey = Key('mission-closed-notice');

  static Key ownedKey(String itemId) => Key('mission-item-owned-$itemId');
  static Key acquiredKey(String itemId) => Key('mission-item-acquired-$itemId');

  @override
  ConsumerState<MissionDetailScreen> createState() =>
      _MissionDetailScreenState();
}

class _MissionDetailScreenState extends ConsumerState<MissionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(missionDetailProvider(widget.missionId).notifier).load(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(missionDetailProvider(widget.missionId));
    final mission = state.mission;

    ref.listen(missionDetailProvider(widget.missionId), (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(error)));
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Mission'),
      ),
      body: SafeArea(
        child: mission == null
            ? state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : MallErrorState(
                      title: "We couldn't load this mission",
                      body: state.error,
                      onRetry: () => ref
                          .read(
                            missionDetailProvider(widget.missionId).notifier,
                          )
                          .load(),
                    )
            : _Body(mission: mission, state: state),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.mission, required this.state});

  final ShoppingMission mission;
  final MissionDetailState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closed = mission.isTerminal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        MallStatusSummary(
          eyebrow: 'Mission shopping',
          title: mission.missionSummary.trim().isEmpty
              ? mission.missionText
              : mission.missionSummary,
          tone: missionStateTone(mission.state),
          icon: missionStateIcon(mission.state),
          detail: mission.state.label,
          trailingPillLabel: mission.itemCount == 1
              ? '1 item'
              : '${mission.itemCount} items',
          footnote: 'Plan revision ${mission.planRevision}',
        ),
        const SizedBox(height: DesignTokens.s16),
        MissionCoverageBar(mission: mission),
        const SizedBox(height: DesignTokens.s16),
        if (mission.overBudgetBy != null) ...[
          MissionOverBudgetBanner(mission: mission),
          const SizedBox(height: DesignTokens.s16),
        ],
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceRaised,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: MissionMoneyBlock(mission: mission),
        ),
        const SizedBox(height: DesignTokens.s24),
        const MallSectionHeader(title: 'The checklist'),
        const SizedBox(height: DesignTokens.s8),
        if (mission.items.isEmpty)
          const MallEmptyState(
            icon: Icons.checklist_rtl_outlined,
            title: 'Nothing planned yet',
            body: 'Re-plan to have Minty propose items for this mission.',
          )
        else
          Column(
            key: MissionDetailScreen.checklistKey,
            children: [
              for (final item in mission.items) ...[
                _ItemRow(
                  mission: mission,
                  item: item,
                  busy: state.busyItemId == item.id,
                  closed: closed,
                ),
                const SizedBox(height: DesignTokens.s8),
              ],
            ],
          ),
        const SizedBox(height: DesignTokens.s16),
        if (closed)
          Container(
            key: MissionDetailScreen.closedNoticeKey,
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: Semantics(
              label: mission.terminalReason,
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      0,
                      2,
                      DesignTokens.s12,
                      0,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      mission.terminalReason ?? '',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        height: 1.5,
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _MissionActions(mission: mission, busy: state.busyAction),
      ],
    );
  }
}

class _MissionActions extends ConsumerWidget {
  const _MissionActions({required this.mission, required this.busy});

  final ShoppingMission mission;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(missionDetailProvider(mission.id).notifier);
    return Wrap(
      spacing: DesignTokens.s8,
      runSpacing: DesignTokens.s8,
      children: [
        Semantics(
          button: true,
          enabled: !busy,
          label: 'Re-plan this mission',
          excludeSemantics: true,
          child: OutlinedButton.icon(
            key: MissionDetailScreen.replanKey,
            onPressed: busy ? null : () => unawaited(notifier.replan()),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Re-plan'),
          ),
        ),
        Semantics(
          button: true,
          enabled: !busy,
          label: 'Mark this mission completed',
          excludeSemantics: true,
          child: FilledButton.icon(
            key: MissionDetailScreen.completeKey,
            onPressed: busy ? null : () => unawaited(notifier.complete()),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Complete'),
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              foregroundColor: DesignTokens.bgAppBody,
            ),
          ),
        ),
        Semantics(
          button: true,
          enabled: !busy,
          label: 'Abandon this mission',
          excludeSemantics: true,
          child: TextButton.icon(
            key: MissionDetailScreen.abandonKey,
            onPressed: busy ? null : () => unawaited(notifier.abandon()),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Abandon'),
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
            ),
          ),
        ),
      ],
    );
  }
}

/// One planned item.
///
/// No product photograph: the Mall is video-first, and `thumbnailUrl` on the
/// payload does not override that. The item is named in the display face with
/// its reason under it, the way a Mall type tile carries a product.
class _ItemRow extends ConsumerWidget {
  const _ItemRow({
    required this.mission,
    required this.item,
    required this.busy,
    required this.closed,
  });

  final ShoppingMission mission;
  final MissionItem item;
  final bool busy;
  final bool closed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(missionDetailProvider(mission.id).notifier);
    final price = formatMoney(
      Money(amount: item.priceAmount, currency: mission.currency),
      decimalDigits: 0,
    );
    final resolved = item.state.isResolved;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: '${item.name}, $price. ${item.state.label}. Open product.',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => context.push(
                RouteNames.productDetail.replaceFirst(
                  ':productId',
                  item.productId,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: DesignTokens.displayFontFamily,
                            fontSize: 18,
                            height: 1.25,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        if (item.reason.trim().isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.s4),
                          Text(
                            item.reason,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 12,
                              height: 1.45,
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: DesignTokens.s8),
                        Text(
                          price,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  if (resolved)
                    MallStatusPill(
                      label: item.state.label,
                      tone: item.state == MissionItemState.acquired
                          ? MallStatusTone.success
                          : MallStatusTone.neutral,
                      icon: item.state == MissionItemState.acquired
                          ? Icons.check_circle_outline_rounded
                          : Icons.inventory_2_outlined,
                      dense: true,
                    ),
                ],
              ),
            ),
          ),
          if (!closed) ...[
            const SizedBox(height: DesignTokens.s12),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                _StateChip(
                  itemKey: MissionDetailScreen.ownedKey(item.id),
                  label: 'Already own it',
                  selected: item.state == MissionItemState.alreadyOwned,
                  busy: busy,
                  semanticLabel:
                      'Mark ${item.name} as something you already own',
                  onPressed: () => notifier.setItemState(
                    item,
                    item.state == MissionItemState.alreadyOwned
                        ? MissionItemState.suggested
                        : MissionItemState.alreadyOwned,
                  ),
                ),
                _StateChip(
                  itemKey: MissionDetailScreen.acquiredKey(item.id),
                  label: 'Got it',
                  selected: item.state == MissionItemState.acquired,
                  busy: busy,
                  semanticLabel: 'Mark ${item.name} as acquired',
                  onPressed: () => notifier.setItemState(
                    item,
                    item.state == MissionItemState.acquired
                        ? MissionItemState.suggested
                        : MissionItemState.acquired,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.itemKey,
    required this.label,
    required this.selected,
    required this.busy,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Key itemKey;
  final String label;
  final bool selected;
  final bool busy;
  final String semanticLabel;
  final Future<bool> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: OutlinedButton.icon(
        key: itemKey,
        onPressed: busy ? null : () => unawaited(onPressed()),
        icon: Icon(
          selected
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? DesignTokens.primaryGreen
              : DesignTokens.textLight,
          side: BorderSide(
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
        ),
      ),
    );
  }
}
