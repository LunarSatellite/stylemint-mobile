import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/widgets/mission_budget_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Mission shopping: a sentence and a budget become a checklist the shopper
/// works through. Nothing here buys anything — items are marked already-owned
/// or acquired by the shopper, and ordinary browsing and checkout are
/// untouched.
class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  static const Key listKey = Key('missions-list');
  static const Key startKey = Key('missions-start');
  static const Key textFieldKey = Key('missions-text');
  static const Key budgetFieldKey = Key('missions-budget');
  static const Key createKey = Key('missions-create');

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  @override
  Widget build(BuildContext context) {
    final missions = ref.watch(missionListProvider(null));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Shopping missions'),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Start a new shopping mission',
        excludeSemantics: true,
        child: FloatingActionButton.extended(
          key: MissionsScreen.startKey,
          onPressed: _openComposer,
          backgroundColor: DesignTokens.primaryGreen,
          foregroundColor: DesignTokens.bgAppBody,
          icon: const Icon(Icons.flag_outlined),
          label: const Text('New mission'),
        ),
      ),
      body: SafeArea(
        child: missions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => MallErrorState(
            title: "We couldn't load your missions",
            body: 'Check your connection and try again.',
            onRetry: () => ref.invalidate(missionListProvider(null)),
          ),
          data: (list) => list.items.isEmpty
              ? MallEmptyState(
                  icon: Icons.flag_outlined,
                  eyebrow: 'Mission shopping',
                  title: 'Shop by the job, not the item',
                  body:
                      '"Kit out a new flat under 40,000" becomes a checklist '
                      'you can work through — mark what you already own and '
                      'what you have picked up.',
                  actionLabel: 'Start a mission',
                  onAction: _openComposer,
                )
              : ListView.separated(
                  key: MissionsScreen.listKey,
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s12,
                    DesignTokens.s16,
                    DesignTokens.s48 + DesignTokens.s32,
                  ),
                  itemCount: list.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (context, index) =>
                      _MissionRow(mission: list.items[index]),
                ),
        ),
      ),
    );
  }

  Future<void> _openComposer() async {
    final created = await showModalBottomSheet<ShoppingMission>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.surfaceRaised,
      builder: (_) => const _MissionComposerSheet(),
    );
    if (!mounted || created == null) return;
    ref.invalidate(missionListProvider(null));
    await context.push(
      RouteNames.mission.replaceFirst(':missionId', created.id),
    );
    if (mounted) ref.invalidate(missionListProvider(null));
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final ShoppingMission mission;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: missionSpokenSummary(mission),
      excludeSemantics: true,
      child: Material(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          onTap: () => context.push(
            RouteNames.mission.replaceFirst(':missionId', mission.id),
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        mission.missionSummary.trim().isEmpty
                            ? mission.missionText
                            : mission.missionSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    MallStatusPill(
                      label: mission.state.label,
                      tone: missionStateTone(mission.state),
                      icon: missionStateIcon(mission.state),
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                MissionCoverageBar(mission: mission),
                if (mission.overBudgetBy != null) ...[
                  const SizedBox(height: DesignTokens.s12),
                  MissionOverBudgetBanner(mission: mission),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The create form: a sentence, an optional budget, and a cap on how many
/// items the plan may hold.
class _MissionComposerSheet extends ConsumerStatefulWidget {
  const _MissionComposerSheet();

  @override
  ConsumerState<_MissionComposerSheet> createState() =>
      _MissionComposerSheetState();
}

class _MissionComposerSheetState extends ConsumerState<_MissionComposerSheet> {
  final _text = TextEditingController();
  final _budget = TextEditingController();
  int _maxItems = 5;
  bool _busy = false;
  String? _error;
  String? _budgetError;

  @override
  void dispose() {
    _text.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s20,
        DesignTokens.s16,
        MediaQuery.viewInsetsOf(context).bottom + DesignTokens.s20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MallEyebrow('Mission shopping'),
            const SizedBox(height: DesignTokens.s8),
            const Text(
              'What are you trying to get done?',
              style: TextStyle(
                fontFamily: DesignTokens.displayFontFamily,
                fontSize: 22,
                height: 1.25,
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              textField: true,
              label: 'Describe your mission',
              child: TextField(
                key: MissionsScreen.textFieldKey,
                controller: _text,
                maxLength: 500,
                maxLines: 3,
                minLines: 2,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.textWhite,
                ),
                decoration: const InputDecoration(
                  hintText: 'Kit out a new flat under 40,000',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Semantics(
              textField: true,
              label: 'Budget in rupees, optional',
              child: TextField(
                key: MissionsScreen.budgetFieldKey,
                controller: _budget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                ],
                onChanged: (_) {
                  if (_budgetError != null) {
                    setState(() => _budgetError = null);
                  }
                },
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.textWhite,
                ),
                decoration: InputDecoration(
                  labelText: 'Budget (optional)',
                  prefixText: 'Rs ',
                  errorText: _budgetError,
                  errorMaxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              label: 'Most items to plan, $_maxItems',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plan at most $_maxItems items',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  Slider(
                    value: _maxItems.toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: '$_maxItems',
                    activeColor: DesignTokens.primaryGreen,
                    onChanged: (value) =>
                        setState(() => _maxItems = value.round()),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  height: 1.4,
                  color: DesignTokens.colorError,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              button: true,
              enabled: !_busy,
              label: 'Plan this mission',
              excludeSemantics: true,
              child: SizedBox(
                width: double.infinity,
                child: MallPrimaryCta(
                  key: MissionsScreen.createKey,
                  label: _busy ? 'Planning…' : 'Plan this mission',
                  onPressed: _busy ? null : _submit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Tell Minty what you are trying to get done.');
      return;
    }
    // The budget is optional, but a typed one that does not read as a
    // positive amount ("1.2.3", ".") must not be sent as "no budget" — the
    // plan would then come back with no budget verdict and no explanation.
    final budgetText = _budget.text.trim();
    double? budget;
    if (budgetText.isNotEmpty) {
      budget = double.tryParse(budgetText);
      if (budget == null || !budget.isFinite || budget <= 0) {
        setState(
          () => _budgetError =
              'Enter an amount like 40000, or leave it empty for no budget.',
        );
        return;
      }
    }
    setState(() {
      _busy = true;
      _error = null;
      _budgetError = null;
    });
    final result = await ref
        .read(missionsRepositoryProvider)
        .start(
          missionText: text,
          maxItems: _maxItems,
          budgetAmount: budget,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _busy = false;
        _error = missionPlanFailure(failure);
      }),
      (mission) => Navigator.of(context).pop(mission),
    );
  }
}

/// Why a mission could not be planned, in the shopper's words.
///
/// A 4xx carries the server's own reason (RFC 7807 `detail`, else a
/// meaningful `title`, else the per-field errors) and that is what the
/// shopper needs to fix the request — retrying the same sentence would only
/// be refused again. Transport failures get the same plain sentences the
/// mission screen uses.
String missionPlanFailure(NetworkExceptions failure) {
  if (failure.validationCode != null) {
    return NetworkExceptions.getMessage(failure);
  }
  if (failure.isNoInternet) return 'You appear to be offline.';
  if (failure.isServerUnavailable) {
    return 'Missions are unreachable right now. Try again.';
  }
  if (failure.isAuth) return 'Please sign in again.';
  return 'That mission could not be planned. Try again.';
}

MallStatusTone missionStateTone(MissionState state) => switch (state) {
  MissionState.planned => MallStatusTone.info,
  MissionState.active => MallStatusTone.progress,
  MissionState.completed => MallStatusTone.success,
  MissionState.abandoned => MallStatusTone.danger,
};

IconData missionStateIcon(MissionState state) => switch (state) {
  MissionState.planned => Icons.flag_outlined,
  MissionState.active => Icons.play_arrow_rounded,
  MissionState.completed => Icons.check_circle_outline_rounded,
  MissionState.abandoned => Icons.cancel_outlined,
};

String _money(double amount, String currency) =>
    formatMoney(Money(amount: amount, currency: currency), decimalDigits: 0);

/// The whole mission in one spoken sentence, for assistive technology.
String missionSpokenSummary(ShoppingMission mission) {
  final over = mission.overBudgetBy;
  final coverage =
      '${mission.itemsResolvedCount} of ${mission.itemCount} sorted, '
      '${mission.coveragePercent} percent';
  final overshoot = over == null
      ? null
      : 'Over budget by ${_money(over, mission.currency)}';
  return <String>[
    if (mission.missionSummary.trim().isEmpty)
      mission.missionText
    else
      mission.missionSummary,
    mission.state.label,
    coverage,
    ?overshoot,
  ].join('. ');
}
