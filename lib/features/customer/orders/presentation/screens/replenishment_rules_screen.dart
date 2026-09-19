import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/replenishment_rules_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/replenishment_rules_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/orders_load_error_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Restock rules" (`/orders/refill-plan/rules`) — every rule the customer can
/// set over predictive replenishment, in one place.
///
/// The seven the backend accepts, and how each one appears here:
///
/// | Rule | Control |
/// |---|---|
/// | `automationLevel` | two choices — remind, or prepare a basket |
/// | `steadiness` | three choices — any, fairly even, very even |
/// | `leadTimeDays` | 1–30, a slider that cannot leave the range |
/// | `minDaysBetweenPlans` | 1–90, a slider |
/// | `maxPlanAmount`, `maxPlanCurrency` | an optional amount and currency |
/// | `allowSubstitutions` | a switch, **off** unless the customer turns it on |
/// | pause | a quiet period that lifts itself, plus "resume now" |
///
/// **There is no third automation level and no way to ask for one.** The
/// platform never places an order (§5.9); a backend test fails if a third
/// value is added, and the copy under the choices says so plainly rather than
/// leaving the customer to wonder what the next rung would be.
///
/// **Steadiness is not a confidence figure.** The number behind each choice
/// lives on the backend, is never serialised and is never shown. The customer
/// picks how even a pattern has to look, in words — no percentage, no score,
/// no bar.
///
/// **Substitutions default to off.** Silence is a no: the switch starts off,
/// nothing is pre-selected, and even with it on the customer picks the
/// alternative themselves.
class ReplenishmentRulesScreen extends ConsumerWidget {
  const ReplenishmentRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allowed = ref.watch(personalizationAllowedProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Restock rules'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            semanticLabel: 'Back',
          ),
          onPressed: () => context.popOrHome(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: allowed.when(
          loading: () => const _RulesSkeleton(),
          error: (_, _) => const _PausedView(),
          data: (isAllowed) =>
              isAllowed ? const _RulesForm() : const _PausedView(),
        ),
      ),
    );
  }
}

class _RulesForm extends ConsumerStatefulWidget {
  const _RulesForm();

  @override
  ConsumerState<_RulesForm> createState() => _RulesFormState();
}

class _RulesFormState extends ConsumerState<_RulesForm> {
  /// The edits in progress. Null until the saved rules have been read — a
  /// control drawn over an unknown value would save a guess.
  ReplenishmentRulesRequest? _draft;

  /// Seeded from the saved rules, and re-seeded whenever a save round-trips,
  /// so the fields show what was stored rather than what was typed.
  String? _seededFrom;
  final TextEditingController _limitController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();

  @override
  void dispose() {
    _limitController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  void _seed(ReplenishmentPreferenceDto preference) {
    final stamp = '${preference.updatedUtc}|${preference.automationLevel}|'
        '${preference.steadiness}|${preference.leadTimeDays}|'
        '${preference.minDaysBetweenPlans}|${preference.maxPlanAmount}|'
        '${preference.maxPlanCurrency}|${preference.allowSubstitutions}';
    if (_seededFrom == stamp) return;
    _seededFrom = stamp;
    _draft = preference.toRequest();
    _limitController.text = preference.maxPlanAmount == null
        ? ''
        : _trimAmount(preference.maxPlanAmount!);
    _currencyController.text = preference.maxPlanCurrency ?? '';
  }

  static String _trimAmount(double value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(replenishmentRulesNotifierProvider);

    return switch (state) {
      ReplenishmentRulesLoading() => const _RulesSkeleton(),
      ReplenishmentRulesFailed() => OrdersScrollableState(
        child: MallEmptyState(
          icon: Icons.cloud_off_rounded,
          title: "We couldn't read your rules",
          body:
              "We won't show settings we couldn't load — changing one would "
              'save a guess. Try again in a moment.',
          actionLabel: 'Try again',
          onAction: ref.read(replenishmentRulesNotifierProvider.notifier).load,
        ),
      ),
      ReplenishmentRulesLoaded(
        :final preference,
        :final saving,
        :final error,
      ) =>
        _form(preference, saving: saving, error: error),
    };
  }

  Widget _form(
    ReplenishmentPreferenceDto preference, {
    required bool saving,
    required String? error,
  }) {
    _seed(preference);
    final draft = _draft!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        Text(
          'These rules decide when we estimate a restock and whether we put a '
          "basket together. They're yours to change at any time, and they only "
          'ever affect suggestions — we never order anything on your '
          'behalf.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: DesignTokens.s20),

        // ── Automation level ────────────────────────────────────────────────
        _RuleSection(
          title: 'What we do when something looks due',
          note:
              'There are two settings and there is no third. StyleMint never '
              'places an order on your behalf — the most we ever do is put '
              'a basket together that you look over.',
          child: Column(
            children: [
              for (final level in ReplenishmentAutomationLevel.values)
                _ChoiceRow(
                  key: ValueKey('rule-automation-${level.wire}'),
                  label: switch (level) {
                    ReplenishmentAutomationLevel.remindOnly => 'Just remind me',
                    ReplenishmentAutomationLevel.prepareBasket =>
                      'Prepare a basket I can review',
                  },
                  description: switch (level) {
                    ReplenishmentAutomationLevel.remindOnly =>
                      'A suggestion on a screen you opened. Nothing more.',
                    ReplenishmentAutomationLevel.prepareBasket =>
                      'We check prices and stock and assemble a basket. '
                          'You approve it; nothing is ordered, reserved '
                          'or paid for.',
                  },
                  selected: draft.automationLevel == level,
                  enabled: !saving,
                  onSelect: () => setState(
                    () => _draft = draft.copyWith(automationLevel: level),
                  ),
                ),
            ],
          ),
        ),

        // ── Steadiness ──────────────────────────────────────────────────────
        _RuleSection(
          title: 'How regular a pattern has to be',
          note:
              "We don't rate your rhythm with a number — you choose how "
              'even it has to look before we say anything.',
          child: Column(
            children: [
              for (final steadiness in ReplenishmentSteadiness.values)
                _ChoiceRow(
                  key: ValueKey('rule-steadiness-${steadiness.wire}'),
                  label: switch (steadiness) {
                    ReplenishmentSteadiness.any => 'Any rhythm we can read',
                    ReplenishmentSteadiness.steady => 'A fairly even rhythm',
                    ReplenishmentSteadiness.verySteady => 'A very even rhythm',
                  },
                  description: switch (steadiness) {
                    ReplenishmentSteadiness.any =>
                      'The most suggestions, including looser patterns.',
                    ReplenishmentSteadiness.steady =>
                      'Fewer suggestions, for things you buy on a fairly '
                          'regular cycle.',
                    ReplenishmentSteadiness.verySteady =>
                      'The fewest suggestions, for things you buy like '
                          'clockwork.',
                  },
                  selected: draft.steadiness == steadiness,
                  enabled: !saving,
                  onSelect: () => setState(
                    () => _draft = draft.copyWith(steadiness: steadiness),
                  ),
                ),
            ],
          ),
        ),

        // ── Lead time ───────────────────────────────────────────────────────
        _RuleSection(
          title: 'How far ahead to look',
          note:
              'Between ${ReplenishmentRulesRequest.minLeadTimeDays} and '
              '${ReplenishmentRulesRequest.maxLeadTimeDays} days.',
          child: _DaysSlider(
            sliderKey: const ValueKey('rule-lead-time'),
            label: 'Lead time',
            value: draft.leadTimeDays,
            min: ReplenishmentRulesRequest.minLeadTimeDays,
            max: ReplenishmentRulesRequest.maxLeadTimeDays,
            valueLabel: (days) =>
                days == 1 ? '1 day ahead' : '$days days ahead',
            enabled: !saving,
            onChanged: (days) =>
                setState(() => _draft = draft.copyWith(leadTimeDays: days)),
          ),
        ),

        // ── Frequency limit ─────────────────────────────────────────────────
        _RuleSection(
          title: 'How often at most',
          note:
              'We leave at least this long between one basket and the next.',
          child: _DaysSlider(
            sliderKey: const ValueKey('rule-frequency'),
            label: 'Days between baskets',
            value: draft.minDaysBetweenPlans,
            min: ReplenishmentRulesRequest.minFrequencyDays,
            max: ReplenishmentRulesRequest.maxFrequencyDays,
            valueLabel: (days) => days == 1
                ? 'At most once a day'
                : 'At most once every $days days',
            enabled: !saving,
            onChanged: (days) => setState(
              () => _draft = draft.copyWith(minDaysBetweenPlans: days),
            ),
          ),
        ),

        // ── Spending limit ──────────────────────────────────────────────────
        _RuleSection(
          title: 'Spending limit for one basket',
          note:
              'Leave it empty for no limit. Anything that would take a '
              'basket '
              'over the limit is left out, with a reason you can read.',
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  key: const ValueKey('rule-limit-amount'),
                  controller: _limitController,
                  enabled: !saving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: DesignTokens.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'No limit',
                  ),
                  onChanged: (_) => setState(_applyLimit),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: TextField(
                  key: const ValueKey('rule-limit-currency'),
                  controller: _currencyController,
                  enabled: !saving,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(color: DesignTokens.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    hintText: 'NPR',
                  ),
                  onChanged: (_) => setState(_applyLimit),
                ),
              ),
            ],
          ),
        ),

        // ── Substitutions ───────────────────────────────────────────────────
        _RuleSection(
          title: 'Showing alternatives',
          note:
              'Off unless you turn it on. Even on, we only show you other '
              'options — we never swap one thing for another.',
          child: SwitchListTile.adaptive(
            key: const ValueKey('rule-substitutions'),
            contentPadding: EdgeInsets.zero,
            value: draft.allowSubstitutions,
            onChanged: saving
                ? null
                : (value) => setState(
                    () => _draft = draft.copyWith(allowSubstitutions: value),
                  ),
            activeThumbColor: DesignTokens.primaryGreen,
            title: const Text(
              'Show me alternatives when an option is unavailable',
              style: TextStyle(color: DesignTokens.textWhite, fontSize: 14),
            ),
          ),
        ),

        if (error != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              key: const ValueKey('rule-error'),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('rule-save'),
            onPressed: saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              foregroundColor: DesignTokens.bgAppFoundation,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
            ),
            child: Semantics(
              button: true,
              label: saving ? 'Saving your rules' : 'Save these rules',
              excludeSemantics: true,
              child: Text(
                saving ? 'Saving' : 'Save rules',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.s24),
        _PauseSection(
          preference: preference,
          saving: saving,
          onPause: _pauseFor,
          onResume: () => _setPause(null),
        ),
      ],
    );
  }

  /// A blank amount means no limit, and clears the currency with it — the
  /// backend keeps the two together and so does this.
  void _applyLimit() {
    final draft = _draft;
    if (draft == null) return;
    final raw = _limitController.text.trim();
    final amount = raw.isEmpty ? null : double.tryParse(raw);
    _draft = draft.copyWith(
      maxPlanAmount: amount,
      maxPlanCurrency: amount == null
          ? null
          : _currencyController.text.trim().toUpperCase(),
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final saved = await ref
        .read(replenishmentRulesNotifierProvider.notifier)
        .save(draft);
    if (!mounted) return;
    if (saved) SmSnackbar.success(context, 'Your restock rules are saved');
  }

  /// A quiet period the customer picks in whole days. It lifts itself when it
  /// ends — nothing has to be switched back on.
  Future<void> _pauseFor(int days) =>
      _setPause(DateTime.now().toUtc().add(Duration(days: days)));

  Future<void> _setPause(DateTime? until) async {
    final saved = await ref
        .read(replenishmentRulesNotifierProvider.notifier)
        .setPause(until);
    if (!mounted || !saved) return;
    SmSnackbar.success(
      context,
      until == null ? 'Restock is running again' : 'Restock is paused',
    );
  }
}

/// The pause, and the fact that it ends by itself.
class _PauseSection extends StatelessWidget {
  const _PauseSection({
    required this.preference,
    required this.saving,
    required this.onPause,
    required this.onResume,
  });

  final ReplenishmentPreferenceDto preference;
  final bool saving;
  final Future<void> Function(int days) onPause;
  final Future<void> Function() onResume;

  @override
  Widget build(BuildContext context) {
    final until = preference.pausedUntilUtc?.toLocal();

    return _RuleSection(
      title: 'Take a break',
      note:
          'A pause stops estimates and baskets for a while, and lifts itself '
          'when it ends. Your rules above are kept exactly as they are.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preference.paused && until != null) ...[
            MallStatusPill(
              label: 'Paused until ${_dayMonth(until)}',
              tone: MallStatusTone.info,
              semanticLabel: 'Paused until ${_dayMonth(until)}',
            ),
            const SizedBox(height: DesignTokens.s12),
            OutlinedButton(
              key: const ValueKey('rule-resume'),
              onPressed: saving ? null : onResume,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.textWhite,
                side: const BorderSide(color: DesignTokens.borderDefault),
              ),
              child: Semantics(
                button: true,
                label: 'End the pause now',
                excludeSemantics: true,
                child: const Text('Resume now'),
              ),
            ),
          ] else
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final days in const [7, 30, 90])
                  OutlinedButton(
                    key: ValueKey('rule-pause-$days'),
                    onPressed: saving ? null : () => onPause(days),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.textWhite,
                      side: const BorderSide(
                        color: DesignTokens.borderDefault,
                      ),
                    ),
                    child: Semantics(
                      button: true,
                      label: 'Pause restock for $days days',
                      excludeSemantics: true,
                      child: Text('$days days'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  static String _dayMonth(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]}';
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.title,
    required this.note,
    required this.child,
  });

  final String title;
  final String note;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: DesignTokens.sectionInnerTitle.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          note,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        child,
      ],
    ),
  );
}

/// One option in a set where exactly one is chosen. A radio in everything but
/// paint: it announces itself as selected or not, and one tap picks it.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    super.key,
  });

  final String label;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    inMutuallyExclusiveGroup: true,
    selected: selected,
    enabled: enabled,
    label: '$label. $description',
    // The row's own tap has to live on the node that carries the label:
    // `excludeSemantics` drops the InkWell's, and a button a screen reader
    // can read but cannot activate is worse than an unlabelled one.
    onTap: enabled ? onSelect : null,
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          onTap: enabled ? onSelect : null,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              border: Border.all(
                color: selected
                    ? DesignTokens.primaryGreen
                    : DesignTokens.borderDefault,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected
                      ? DesignTokens.primaryGreen
                      : DesignTokens.textMuted,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A whole-day slider that **cannot** leave its range: the control's own
/// bounds are the rule's bounds, and the notifier refuses anything outside
/// them as well, so neither a gesture nor a call can carry an illegal value.
class _DaysSlider extends StatelessWidget {
  const _DaysSlider({
    required this.sliderKey,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.enabled,
    required this.onChanged,
  });

  final Key sliderKey;
  final String label;
  final int value;
  final int min;
  final int max;
  final String Function(int days) valueLabel;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          valueLabel(clamped),
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        // The Slider keeps its own semantics — that is where the increase
        // and decrease actions live — and only gains a name and a spoken
        // value in whole days.
        MergeSemantics(
          child: Semantics(
            container: true,
            label: label,
            value: valueLabel(clamped),
            child: Slider(
              key: sliderKey,
              value: clamped.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              activeColor: DesignTokens.primaryGreen,
              semanticFormatterCallback: (v) => valueLabel(v.round()),
              onChanged: enabled ? (v) => onChanged(v.round()) : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _PausedView extends StatelessWidget {
  const _PausedView();

  @override
  Widget build(BuildContext context) => OrdersScrollableState(
    child: MallEmptyState(
      icon: Icons.pause_circle_outline_rounded,
      title: 'Restock estimates are paused',
      body:
          "You've paused being remembered, so there's nothing here to set. You "
          'can change that in your Memory Vault whenever you like.',
      actionLabel: 'Open Memory Vault',
      onAction: () => context.push(RouteNames.settingsMemory),
    ),
  );
}

class _RulesSkeleton extends StatelessWidget {
  const _RulesSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(DesignTokens.s16),
    children: [
      for (var i = 0; i < 5; i++)
        const Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.s16),
          child: SmSkeleton.box(height: 72),
        ),
    ],
  );
}
