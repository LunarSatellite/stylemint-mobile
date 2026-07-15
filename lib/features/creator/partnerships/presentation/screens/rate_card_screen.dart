import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Mutable form tier state ───────────────────────────────────────────────────

class _TierEntry {
  _TierEntry({
    String name = '',
    double price = 0,
    int reels = 1,
    String description = '',
  })  : nameCtrl = TextEditingController(text: name),
        priceCtrl =
            TextEditingController(text: price > 0 ? price.toStringAsFixed(0) : ''),
        reelsCtrl = TextEditingController(text: reels.toString()),
        descCtrl = TextEditingController(text: description);

  factory _TierEntry.from(RateTier tier) => _TierEntry(
        name: tier.tierName,
        price: tier.price,
        reels: tier.includedReels,
        description: tier.description ?? '',
      );

  final TextEditingController nameCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController reelsCtrl;
  final TextEditingController descCtrl;

  void dispose() {
    nameCtrl.dispose();
    priceCtrl.dispose();
    reelsCtrl.dispose();
    descCtrl.dispose();
  }

  RateTier? toTier() {
    final name = nameCtrl.text.trim();
    final price = double.tryParse(priceCtrl.text.trim()) ?? -1;
    final reels = int.tryParse(reelsCtrl.text.trim()) ?? -1;
    if (name.isEmpty || price < 0 || reels < 0) return null;
    final desc = descCtrl.text.trim();
    return RateTier(
      tierName: name,
      price: price,
      includedReels: reels,
      description: desc.isEmpty ? null : desc,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RateCardScreen extends ConsumerStatefulWidget {
  const RateCardScreen({super.key});

  @override
  ConsumerState<RateCardScreen> createState() => _RateCardScreenState();
}

class _RateCardScreenState extends ConsumerState<RateCardScreen> {
  bool _editing = false;
  bool _saving = false;

  final _baseRateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final List<_TierEntry> _tiers = [];
  double _commission = 0.10;
  final Set<String> _platforms = {};

  static const _availablePlatforms = [
    'Instagram',
    'TikTok',
    'YouTube',
    'Facebook',
    'Twitter',
  ];

  @override
  void dispose() {
    _baseRateCtrl.dispose();
    _notesCtrl.dispose();
    for (final t in _tiers) {
      t.dispose();
    }
    super.dispose();
  }

  void _startEdit(CreatorRateCard? existing) {
    for (final t in _tiers) {
      t.dispose();
    }
    _tiers.clear();
    setState(() {
      _editing = true;
      if (existing != null) {
        _baseRateCtrl.text = existing.baseRate.toStringAsFixed(0);
        _notesCtrl.text = existing.notes ?? '';
        _tiers.addAll(existing.rates.map(_TierEntry.from));
        _commission = existing.commissionPreference;
        _platforms
          ..clear()
          ..addAll(existing.platformPreferences);
      } else {
        _baseRateCtrl.clear();
        _notesCtrl.clear();
        _tiers.add(_TierEntry());
        _commission = 0.10;
        _platforms.clear();
      }
    });
  }

  Future<void> _save() async {
    final baseRate = double.tryParse(_baseRateCtrl.text.trim());
    if (baseRate == null || baseRate < 0) {
      SmSnackbar.error(context, 'Enter a valid base rate.');
      return;
    }
    if (_tiers.isEmpty) {
      SmSnackbar.error(context, 'Add at least one rate tier.');
      return;
    }
    final tiers = _tiers.map((t) => t.toTier()).toList();
    if (tiers.any((t) => t == null)) {
      SmSnackbar.error(context, 'Complete all tier fields (name, price, reels).');
      return;
    }

    setState(() => _saving = true);
    final result = await ref.read(partnershipsRepositoryProvider).publishRateCard(
          baseRate: baseRate,
          rates: tiers.cast<RateTier>(),
          commissionPreference: _commission,
          platformPreferences: _platforms.toList(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
    if (!mounted) return;
    result.fold(
      (e) => SmSnackbar.error(context, NetworkExceptions.getMessage(e)),
      (_) {
        ref.invalidate(rateCardProvider);
        setState(() => _editing = false);
        SmSnackbar.info(context, 'Rate card published.');
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBodyLight,
        title: Text(
          'Deactivate Rate Card',
          style: DesignTokens.mediumSemibold
              .copyWith(color: DesignTokens.textWhite),
        ),
        content: Text(
          'Brands will no longer see your rate card.',
          style: DesignTokens.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textLight)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final result =
        await ref.read(partnershipsRepositoryProvider).deactivateRateCard();
    if (!mounted) return;
    result.fold(
      (e) => SmSnackbar.error(context, NetworkExceptions.getMessage(e)),
      (_) {
        ref.invalidate(rateCardProvider);
        SmSnackbar.info(context, 'Rate card deactivated.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rateCardAsync = ref.watch(rateCardProvider);
    final bottomPadding =
        MediaQuery.of(context).padding.bottom + DesignTokens.s16;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () {
            if (_editing) {
              setState(() => _editing = false);
            } else {
              context.pop();
            }
          },
        ),
        title: Text(
          _editing ? 'Edit Rate Card' : 'My Rate Card',
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          if (!_editing)
            rateCardAsync.maybeWhen(
              data: (card) => card != null && card.isActive
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 22),
                      onPressed: () => unawaited(_delete()),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: rateCardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (_, __) => Center(
          child: Text('Failed to load rate card.',
              style: DesignTokens.bodyText
                  .copyWith(color: DesignTokens.textMuted)),
        ),
        data: (card) {
          if (_editing) {
            return _EditForm(
              tiers: _tiers,
              baseRateCtrl: _baseRateCtrl,
              notesCtrl: _notesCtrl,
              commission: _commission,
              platforms: _platforms,
              availablePlatforms: _availablePlatforms,
              saving: _saving,
              bottomPadding: bottomPadding,
              onCommissionChanged: (v) => setState(() => _commission = v),
              onPlatformToggled: (p) => setState(() {
                if (_platforms.contains(p)) {
                  _platforms.remove(p);
                } else {
                  _platforms.add(p);
                }
              }),
              onAddTier: () => setState(() => _tiers.add(_TierEntry())),
              onRemoveTier: (i) => setState(() {
                _tiers[i].dispose();
                _tiers.removeAt(i);
              }),
              onSave: () => unawaited(_save()),
            );
          }

          if (card == null || !card.isActive) {
            return _EmptyState(
              onCreatePressed: () => _startEdit(null),
            );
          }

          return _CardView(
            card: card,
            bottomPadding: bottomPadding,
            onEditPressed: () => _startEdit(card),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreatePressed});
  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.price_change_outlined,
                size: 64, color: DesignTokens.textLight),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'No Rate Card Yet',
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.textWhite),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Publish your rate card so brands know what to expect when partnering with you.',
              textAlign: TextAlign.center,
              style:
                  DesignTokens.bodyText.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: onCreatePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius),
                  ),
                ),
                child: Text(
                  'Create Rate Card',
                  style: DesignTokens.oneLinerSemibold
                      .copyWith(color: DesignTokens.buttonPrimaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card view (read-only) ────────────────────────────────────────────────────

class _CardView extends StatelessWidget {
  const _CardView({
    required this.card,
    required this.bottomPadding,
    required this.onEditPressed,
  });
  final CreatorRateCard card;
  final double bottomPadding;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final commissionPct = (card.commissionPreference * 100).toStringAsFixed(0);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        bottomPadding,
      ),
      children: [
        // Version / effective date header
        Row(
          children: [
            _InfoChip(label: 'v${card.version}'),
            const SizedBox(width: DesignTokens.s8),
            Text(
              'Active since ${fmt.format(card.effectiveFromUtc.toLocal())}',
              style:
                  DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),
        const Divider(height: 1, thickness: 1, color: DesignTokens.borderDefault),
        const SizedBox(height: DesignTokens.s16),

        // Base rate
        _RowStat(
          label: 'Base Rate',
          value: 'Rs ${_fmt(card.baseRate)}',
        ),
        const SizedBox(height: DesignTokens.s8),
        _RowStat(
          label: 'Commission Preference',
          value: '$commissionPct%',
        ),
        if (card.platformPreferences.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          _RowStat(
            label: 'Platforms',
            value: card.platformPreferences.join(', '),
          ),
        ],
        const SizedBox(height: DesignTokens.s24),

        // Rate tiers
        Text(
          'Rate Tiers',
          style: DesignTokens.mediumSemibold
              .copyWith(color: DesignTokens.textWhite),
        ),
        const SizedBox(height: DesignTokens.s12),
        for (final tier in card.rates) _TierCard(tier: tier),

        // Notes
        if (card.notes != null && card.notes!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s16),
          Text('Notes',
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.textWhite)),
          const SizedBox(height: DesignTokens.s8),
          Text(card.notes!, style: DesignTokens.bodyText),
        ],

        const SizedBox(height: DesignTokens.s24),
        SizedBox(
          width: double.infinity,
          height: DesignTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: onEditPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
            ),
            child: Text(
              'Edit Rate Card',
              style: DesignTokens.oneLinerSemibold
                  .copyWith(color: DesignTokens.buttonPrimaryText),
            ),
          ),
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier});
  final RateTier tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tier.tierName,
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.textWhite),
                ),
              ),
              Text(
                'Rs ${_fmt(tier.price)}',
                style: DesignTokens.mediumSemibold
                    .copyWith(color: DesignTokens.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${tier.includedReels} reel${tier.includedReels != 1 ? 's' : ''} included',
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textLight),
          ),
          if (tier.description != null && tier.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(tier.description!, style: DesignTokens.bodyText),
          ],
        ],
      ),
    );
  }
}

// ── Edit form ────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.tiers,
    required this.baseRateCtrl,
    required this.notesCtrl,
    required this.commission,
    required this.platforms,
    required this.availablePlatforms,
    required this.saving,
    required this.bottomPadding,
    required this.onCommissionChanged,
    required this.onPlatformToggled,
    required this.onAddTier,
    required this.onRemoveTier,
    required this.onSave,
  });

  final List<_TierEntry> tiers;
  final TextEditingController baseRateCtrl;
  final TextEditingController notesCtrl;
  final double commission;
  final Set<String> platforms;
  final List<String> availablePlatforms;
  final bool saving;
  final double bottomPadding;
  final ValueChanged<double> onCommissionChanged;
  final ValueChanged<String> onPlatformToggled;
  final VoidCallback onAddTier;
  final ValueChanged<int> onRemoveTier;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final commissionPct = (commission * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        bottomPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Base rate
          _SectionLabel(label: 'Base Rate (Rs)'),
          const SizedBox(height: DesignTokens.s8),
          TextField(
            controller: baseRateCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(hintText: 'e.g. 5000'),
          ),
          const SizedBox(height: DesignTokens.s24),

          // Rate tiers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(label: 'Rate Tiers'),
              TextButton.icon(
                onPressed: onAddTier,
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: DesignTokens.primaryGreen),
                label: Text('Add Tier',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.primaryGreen)),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          for (var i = 0; i < tiers.length; i++)
            _TierFormCard(
              entry: tiers[i],
              index: i,
              canRemove: tiers.length > 1,
              onRemove: () => onRemoveTier(i),
            ),
          const SizedBox(height: DesignTokens.s24),

          // Commission preference
          _SectionLabel(
            label: 'Commission Preference ($commissionPct%)',
          ),
          const SizedBox(height: DesignTokens.s8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: DesignTokens.primaryGreen,
              inactiveTrackColor: DesignTokens.borderDefault,
              thumbColor: DesignTokens.primaryGreen,
              overlayColor: DesignTokens.primaryGreen.withOpacity(0.15),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              min: 0,
              max: 0.50,
              divisions: 50,
              value: commission,
              onChanged: onCommissionChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0%',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight)),
                Text('50%',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight)),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s24),

          // Platform preferences
          const _SectionLabel(label: 'Platform Preferences'),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            children: availablePlatforms.map((p) {
              final selected = platforms.contains(p);
              return GestureDetector(
                onTap: () => onPlatformToggled(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? DesignTokens.primaryGreen
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.borderDefault,
                    ),
                  ),
                  child: Text(
                    p,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: DesignTokens.s24),

          // Notes
          const _SectionLabel(label: 'Notes (optional)'),
          const SizedBox(height: DesignTokens.s8),
          TextField(
            controller: notesCtrl,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.inputFieldData,
            ),
            decoration: DesignTokens.inputDecoration(
              hintText: 'Anything brands should know…',
            ),
          ),
          const SizedBox(height: DesignTokens.s32),

          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: saving ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: DesignTokens.textWhite),
                    )
                  : Text(
                      'Publish Rate Card',
                      style: DesignTokens.oneLinerSemibold
                          .copyWith(color: DesignTokens.buttonPrimaryText),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierFormCard extends StatelessWidget {
  const _TierFormCard({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });
  final _TierEntry entry;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tier ${index + 1}',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textMuted),
              ),
              const Spacer(),
              if (canRemove)
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close_rounded,
                      size: 18, color: DesignTokens.textMuted),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          _CompactField(ctrl: entry.nameCtrl, hint: 'Tier name (e.g. Bronze)'),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Expanded(
                child: _CompactField(
                  ctrl: entry.priceCtrl,
                  hint: 'Price (Rs)',
                  numeric: true,
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: _CompactField(
                  ctrl: entry.reelsCtrl,
                  hint: 'Reels included',
                  numeric: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          _CompactField(
            ctrl: entry.descCtrl,
            hint: 'Description (optional)',
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({
    required this.ctrl,
    required this.hint,
    this.numeric = false,
  });
  final TextEditingController ctrl;
  final String hint;
  final bool numeric;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 13,
        color: DesignTokens.inputFieldData,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 13,
          color: DesignTokens.textMuted,
        ),
        filled: true,
        fillColor: DesignTokens.bgAppFoundation,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(DesignTokens.cardRadius / 2),
          borderSide: const BorderSide(color: DesignTokens.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(DesignTokens.cardRadius / 2),
          borderSide: const BorderSide(color: DesignTokens.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(DesignTokens.cardRadius / 2),
          borderSide: const BorderSide(color: DesignTokens.primaryGreen),
        ),
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style:
          DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 3),
      decoration: BoxDecoration(
        color: DesignTokens.chipsSelectedFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: DesignTokens.smallRegular
            .copyWith(color: DesignTokens.primaryGreen),
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  const _RowStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: DesignTokens.bodyText
                  .copyWith(color: DesignTokens.textLight)),
        ),
        Text(value,
            style: DesignTokens.bodyText.copyWith(
                color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final parts = v.toStringAsFixed(0).split('');
  final buf = StringBuffer();
  final len = parts.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(',');
    buf.write(parts[i]);
  }
  return buf.toString();
}
