import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class MissionShoppingScreen extends ConsumerStatefulWidget {
  const MissionShoppingScreen({super.key});
  static const fieldKey = ValueKey<String>('mission-shopping-field');
  static const submitKey = ValueKey<String>('mission-shopping-submit');
  static const resultKey = ValueKey<String>('mission-shopping-result');

  @override
  ConsumerState<MissionShoppingScreen> createState() =>
      _MissionShoppingScreenState();
}

class _MissionShoppingScreenState extends ConsumerState<MissionShoppingScreen> {
  static const examples = <(String, String, IconData)>[
    (
      'Wedding guest',
      'Style a complete elegant wedding guest look',
      Icons.celebration_outlined,
    ),
    (
      'Work reset',
      'Build a polished workwear capsule for the new season',
      Icons.work_outline_rounded,
    ),
    (
      'Weekend away',
      'Pack versatile outfits for a three-day weekend trip',
      Icons.luggage_outlined,
    ),
    (
      'Thoughtful gift',
      'Find a memorable fashion gift that feels personal',
      Icons.card_giftcard_rounded,
    ),
  ];
  final mission = TextEditingController();
  final budget = TextEditingController();
  final focus = FocusNode();
  double? selectedBudget;
  String? occasion;
  String? aesthetic;
  String? priority;
  bool loading = false;
  bool addingAll = false;
  bool addedAll = false;
  String? error;
  MissionShoppingPlan? plan;

  @override
  void initState() {
    super.initState();
    mission.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    mission
      ..removeListener(_changed)
      ..dispose();
    budget.dispose();
    focus.dispose();
    super.dispose();
  }

  void useExample(String value) {
    mission.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    focus.requestFocus();
  }

  void chooseBudget(double? value) {
    setState(() {
      selectedBudget = value;
      budget.text = value?.toStringAsFixed(0) ?? '';
    });
  }

  Future<void> submit() async {
    final text = mission.text.trim();
    if (text.isEmpty || loading) {
      focus.requestFocus();
      return;
    }
    final raw = budget.text.trim();
    final amount = raw.isEmpty ? null : double.tryParse(raw);
    if (raw.isNotEmpty && (amount == null || amount <= 0)) {
      setState(() => error = 'Enter a valid budget, or choose Flexible.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      plan = null;
    });
    final enrichedMission = [
      text,
      if (occasion != null) 'Occasion: $occasion',
      if (aesthetic != null) 'Aesthetic: $aesthetic',
      if (priority != null) 'Priority: $priority',
    ].join('. ');
    final response = await ref
        .read(discoveryRepositoryProvider)
        .getMissionShoppingPlan(
          missionText: enrichedMission,
          budgetAmount: amount,
        );
    if (!mounted) return;
    response.fold(
      (_) => setState(() {
        loading = false;
        error = 'We could not curate this mission right now. Please try again.';
      }),
      (value) => setState(() {
        loading = false;
        plan = value;
      }),
    );
  }

  Future<void> addCompleteEdit() async {
    final currentPlan = plan;
    if (currentPlan == null || addingAll) return;
    setState(() => addingAll = true);
    var added = 0;
    for (final item in currentPlan.items) {
      final result = await ref
          .read(discoveryRepositoryProvider)
          .addToCart(
            productId: item.productId,
            qty: 1,
          );
      if (result.isRight()) added++;
    }
    if (!mounted) return;
    if (added > 0) {
      unawaited(ref.read(cartNotifierProvider.notifier).fetchCart());
    }
    setState(() {
      addingAll = false;
      addedAll = added == currentPlan.items.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == currentPlan.items.length
              ? 'Complete edit added to your bag.'
              : 'Added $added of ${currentPlan.items.length} pieces. '
                    'Review the rest individually.',
        ),
        backgroundColor: added > 0
            ? DesignTokens.primaryGreen
            : DesignTokens.colorError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: Stack(
        children: [
          const Positioned(
            top: -120,
            right: -100,
            child: _Glow(280, Color(0x2932D477)),
          ),
          SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _TopBar(onBack: context.pop)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : DesignTokens.motionMedium,
                      child: plan == null
                          ? _composer()
                          : _Result(
                              key: MissionShoppingScreen.resultKey,
                              plan: plan!,
                              occasion: occasion,
                              aesthetic: aesthetic,
                              priority: priority,
                              addingAll: addingAll,
                              addedAll: addedAll,
                              onAddAll: addCompleteEdit,
                              onRefine: () => setState(() {
                                plan = null;
                                addedAll = false;
                              }),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() => Column(
    key: const ValueKey('mission-composer'),
    children: [
      const _Hero(),
      const SizedBox(height: 18),
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Heading(
              Icons.chat_bubble_outline_rounded,
              'YOUR MISSION',
              'What do you want to achieve?',
            ),
            const SizedBox(height: 14),
            TextField(
              key: MissionShoppingScreen.fieldKey,
              controller: mission,
              focusNode: focus,
              minLines: 3,
              maxLines: 5,
              maxLength: 220,
              textCapitalization: TextCapitalization.sentences,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textWhite,
                height: 1.45,
              ),
              decoration: _inputDecoration(
                'e.g. I need a confident dinner look for Friday — minimal, '
                'comfortable and not too formal…',
              ),
            ),
            const Text(
              'NEED INSPIRATION?',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in examples) ...[
                    ActionChip(
                      onPressed: () => useExample(item.$2),
                      avatar: Icon(
                        item.$3,
                        size: 16,
                        color: DesignTokens.textLight,
                      ),
                      label: Text(item.$1),
                      labelStyle: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.textLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: const Color(0xFF242629),
                      side: const BorderSide(color: DesignTokens.borderDefault),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _PreferenceStudio(
        occasion: occasion,
        aesthetic: aesthetic,
        priority: priority,
        onOccasion: (value) => setState(() => occasion = value),
        onAesthetic: (value) => setState(() => aesthetic = value),
        onPriority: (value) => setState(() => priority = value),
      ),
      const SizedBox(height: 14),
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Heading(
              Icons.account_balance_wallet_outlined,
              'YOUR RANGE',
              'Set a comfortable budget',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in <double?>[null, 5000, 10000, 25000])
                  ChoiceChip(
                    selected: selectedBudget == value,
                    showCheckmark: false,
                    onSelected: (_) => chooseBudget(value),
                    label: Text(
                      value == null
                          ? 'Flexible'
                          : 'Rs ${(value / 1000).toStringAsFixed(0)}k',
                    ),
                    selectedColor: DesignTokens.primaryGreenLight,
                    backgroundColor: const Color(0xFF242629),
                    side: BorderSide(
                      color: selectedBudget == value
                          ? DesignTokens.primaryGreen
                          : DesignTokens.borderDefault,
                    ),
                    labelStyle: TextStyle(
                      color: selectedBudget == value
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budget,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
              decoration: _inputDecoration('Enter another amount').copyWith(
                prefixText: 'Rs  ',
                prefixStyle: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
                counterText: '',
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Row(
        children: [
          Expanded(child: _Promise(Icons.inventory_2_outlined, 'In stock')),
          SizedBox(width: 8),
          Expanded(child: _Promise(Icons.tune_rounded, 'Matched')),
          SizedBox(width: 8),
          Expanded(child: _Promise(Icons.verified_outlined, 'Explained')),
        ],
      ),
      if (error != null) ...[const SizedBox(height: 14), _Error(error!)],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          key: MissionShoppingScreen.submitKey,
          onPressed: loading || mission.text.trim().isEmpty ? null : submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryGreen,
            disabledBackgroundColor: const Color(0xFF26312B),
            foregroundColor: const Color(0xFF07170D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            loading ? 'Curating your look…' : 'Curate my look →',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'You stay in control — review every item before buying.',
        textAlign: TextAlign.center,
        style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
      ),
    ],
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: DesignTokens.mediumRegular.copyWith(
      color: DesignTokens.textMuted,
      height: 1.45,
    ),
    counterStyle: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
    filled: true,
    fillColor: const Color(0xFF111315),
    contentPadding: const EdgeInsets.all(15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: DesignTokens.borderDefault),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: DesignTokens.primaryGreen),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STYLEMINT CONCIERGE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: DesignTokens.primaryGreen,
                ),
              ),
              Text(
                'Shop by mission',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x1418D875),
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: const Color(0x3432D477)),
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 3.5,
                backgroundColor: DesignTokens.primaryGreen,
              ),
              SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: DesignTokens.textLight,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0x3832D477)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1C2B22), Color(0xFF151718), Color(0xFF101112)],
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2032D477),
          blurRadius: 34,
          offset: Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF07170D),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Don’t search products.\nDescribe the outcome.',
          style: TextStyle(
            fontSize: 29,
            height: 1.08,
            letterSpacing: -.8,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tell us the moment, your taste and your budget. We’ll build a '
          'complete, compatible look from items available now.',
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textLight,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        const _Steps(),
      ],
    ),
  );
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      children: [
        _step('1', 'Share', true),
        const SizedBox(
          width: 16,
          child: Divider(color: DesignTokens.borderDefault),
        ),
        _step('2', 'Curate', false),
        const SizedBox(
          width: 16,
          child: Divider(color: DesignTokens.borderDefault),
        ),
        _step('3', 'Choose', false),
      ],
    ),
  );

  Widget _step(String n, String text, bool active) => Row(
    children: [
      CircleAvatar(
        radius: 11,
        backgroundColor: active
            ? DesignTokens.primaryGreen
            : const Color(0xFF2A2E2B),
        child: Text(
          n,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active ? const Color(0xFF07170D) : DesignTokens.textLight,
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        text,
        style: const TextStyle(
          color: DesignTokens.textLight,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _PreferenceStudio extends StatelessWidget {
  const _PreferenceStudio({
    required this.occasion,
    required this.aesthetic,
    required this.priority,
    required this.onOccasion,
    required this.onAesthetic,
    required this.onPriority,
  });

  final String? occasion;
  final String? aesthetic;
  final String? priority;
  final ValueChanged<String> onOccasion;
  final ValueChanged<String> onAesthetic;
  final ValueChanged<String> onPriority;

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Heading(
          Icons.tune_rounded,
          'MAKE IT YOURS',
          'Shape the recommendation',
        ),
        const SizedBox(height: 8),
        Text(
          'A few signals help us choose pieces that belong together.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        _PreferenceRow(
          label: 'Occasion',
          values: const ['Everyday', 'Work', 'Event', 'Travel'],
          selected: occasion,
          onSelected: onOccasion,
        ),
        const SizedBox(height: 13),
        _PreferenceRow(
          label: 'Aesthetic',
          values: const ['Minimal', 'Classic', 'Street', 'Bold'],
          selected: aesthetic,
          onSelected: onAesthetic,
        ),
        const SizedBox(height: 13),
        _PreferenceRow(
          label: 'Priority',
          values: const ['Comfort', 'Versatile', 'Premium', 'Best value'],
          selected: priority,
          onSelected: onPriority,
        ),
      ],
    ),
  );
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: DesignTokens.textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 7),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final value in values) ...[
              ChoiceChip(
                key: ValueKey('mission-pref-$label-$value'),
                selected: selected == value,
                showCheckmark: false,
                onSelected: (_) => onSelected(value),
                label: Text(value),
                selectedColor: DesignTokens.primaryGreenLight,
                backgroundColor: const Color(0xFF242629),
                side: BorderSide(
                  color: selected == value
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
                ),
                labelStyle: TextStyle(
                  color: selected == value
                      ? DesignTokens.primaryGreen
                      : DesignTokens.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
            ],
          ],
        ),
      ),
    ],
  );
}

class _MissionBrief extends StatelessWidget {
  const _MissionBrief({
    required this.occasion,
    required this.aesthetic,
    required this.priority,
  });

  final String? occasion;
  final String? aesthetic;
  final String? priority;

  @override
  Widget build(BuildContext context) {
    final signals = [
      occasion,
      aesthetic,
      priority,
    ].whereType<String>().toList();
    if (signals.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF17191A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3432D477)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.psychology_alt_outlined,
            color: DesignTokens.primaryGreen,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WHAT WE UNDERSTOOD',
                  style: TextStyle(
                    color: DesignTokens.primaryGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  signals.join('  •  '),
                  style: const TextStyle(
                    color: DesignTokens.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({
    required this.plan,
    required this.occasion,
    required this.aesthetic,
    required this.priority,
    required this.addingAll,
    required this.addedAll,
    required this.onAddAll,
    required this.onRefine,
    super.key,
  });
  final MissionShoppingPlan plan;
  final String? occasion;
  final String? aesthetic;
  final String? priority;
  final bool addingAll;
  final bool addedAll;
  final VoidCallback onAddAll;
  final VoidCallback onRefine;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFF153822), Color(0xFF101A14)],
          ),
          border: Border.all(color: const Color(0x5232D477)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: DesignTokens.primaryGreen,
                  child: Icon(Icons.check_rounded, color: Color(0xFF07170D)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR MISSION IS READY',
                        style: TextStyle(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 1.4,
                        ),
                      ),
                      Text(
                        'A complete edit, made for you',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (plan.missionSummary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                plan.missionSummary,
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textLight,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      _MissionBrief(
        occasion: occasion,
        aesthetic: aesthetic,
        priority: priority,
      ),
      const SizedBox(height: 20),
      if (plan.items.isEmpty)
        _Error(
          plan.missionSummary.isEmpty
              ? 'No available pieces matched this mission yet.'
              : plan.missionSummary,
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: Text(
                'Your curated edit',
                style: DesignTokens.displaySection.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '${plan.items.length} PIECES',
              style: const TextStyle(
                color: DesignTokens.primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Chosen to work together — tap any piece for full details.',
          style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < plan.items.length; i++) ...[
          _Item(plan.items[i], i),
          const SizedBox(height: 10),
        ],
        _Summary(plan),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            key: const ValueKey('mission-add-complete-edit'),
            onPressed: addingAll || addedAll ? null : onAddAll,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              foregroundColor: const Color(0xFF07170D),
              disabledBackgroundColor: addedAll
                  ? DesignTokens.primaryGreenDark
                  : const Color(0xFF26312B),
              disabledForegroundColor: addedAll
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: addingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    addedAll
                        ? Icons.check_rounded
                        : Icons.shopping_bag_outlined,
                  ),
            label: Text(
              addingAll
                  ? 'Building your bag…'
                  : addedAll
                  ? 'Complete edit added'
                  : 'Add complete edit to bag',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onRefine,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: DesignTokens.borderDefault),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Refine this mission'),
        ),
      ),
    ],
  );
}

class _Item extends StatelessWidget {
  const _Item(this.item, this.index);
  final MissionShoppingItem item;
  final int index;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(
      RouteNames.productDetail.replaceFirst(':productId', item.productId),
    ),
    borderRadius: BorderRadius.circular(20),
    child: Ink(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xF21A1C1D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4047474D)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  width: 88,
                  height: 108,
                  child: item.thumbnailUrl?.isNotEmpty == true
                      ? Image.network(
                          item.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              Positioned(
                top: 7,
                left: 7,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: const Color(0xE6090A0B),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 13,
                      color: DesignTokens.primaryGreen,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        item.reason.isEmpty
                            ? 'Completes your mission'
                            : item.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rs ${item.priceAmount.toStringAsFixed(0)}',
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: DesignTokens.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary(this.plan);
  final MissionShoppingPlan plan;
  @override
  Widget build(BuildContext context) {
    final value = plan.budgetAmount == null
        ? null
        : (plan.totalEstimatedCost / plan.budgetAmount!).clamp(0.0, 1.0);
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estimated total',
                  style: TextStyle(
                    color: DesignTokens.textLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${plan.currency} '
                '${plan.totalEstimatedCost.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: 13),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: value,
                backgroundColor: const Color(0xFF303438),
                color: plan.withinBudget
                    ? DesignTokens.primaryGreen
                    : DesignTokens.colorWarning,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.withinBudget
                  ? 'Within your budget'
                  : 'Above budget — refine to rebalance',
              style: TextStyle(
                color: plan.withinBudget
                    ? DesignTokens.textLight
                    : DesignTokens.colorWarning,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xE61A1B1E),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x3447474D)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.icon, this.eyebrow, this.title);
  final IconData icon;
  final String eyebrow;
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x182ECC71),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 19, color: DesignTokens.primaryGreen),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: DesignTokens.primaryGreen,
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Promise extends StatelessWidget {
  const _Promise(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xB21A1C1D),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x244F5651)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: DesignTokens.primaryGreen),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: DesignTokens.textLight,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0x24FF6467),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x55FF6467)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: DesignTokens.colorError),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF25282A),
    child: Center(
      child: Icon(
        Icons.checkroom_rounded,
        color: DesignTokens.textMuted,
        size: 30,
      ),
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow(this.size, this.color);
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}
