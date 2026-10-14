import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/notifiers/fit_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/measurements_form.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Size & fit": measurements (once) → recommended size, a verdict chip per
/// size, and the notes for the chosen one. Picking a chip re-labels the
/// add-to-cart button through [onSizeSelected].
class FitPanel extends ConsumerStatefulWidget {
  const FitPanel({
    required this.productId,
    required this.onSizeSelected,
    this.selectedSize,
    this.chartSizes = const <String>[],
    super.key,
  });

  final String productId;
  final String? selectedSize;

  /// The chart's sizes, used when the recommendation lists none.
  final List<String> chartSizes;
  final ValueChanged<String> onSizeSelected;

  @override
  ConsumerState<FitPanel> createState() => _FitPanelState();
}

class _FitPanelState extends ConsumerState<FitPanel> {
  String? _saveError;
  bool _autoPicked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          ref.read(fitNotifierProvider(widget.productId).notifier).load(),
        );
      }
    });
  }

  Future<void> _save(BodyMeasurements m) async {
    setState(() => _saveError = null);
    final failure = await ref
        .read(fitNotifierProvider(widget.productId).notifier)
        .save(m);
    if (mounted && failure != null) {
      setState(() => _saveError = failure.displayMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(fitNotifierProvider(widget.productId).notifier);
    // Pre-select the recommendation once, so the add-to-cart button already
    // names the right size.
    ref.listen(fitNotifierProvider(widget.productId), (_, next) {
      next.maybeWhen(
        loadSuccess: (fit, _) {
          final rec = fit.recommendedSize;
          if (!_autoPicked && rec != null && widget.selectedSize == null) {
            _autoPicked = true;
            widget.onSizeSelected(rec);
          }
        },
        orElse: () {},
      );
    });

    final state = ref.watch(fitNotifierProvider(widget.productId));
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      saving: _loader,
      needsMeasurements: () => MeasurementsForm(
        initial: notifier.measurements,
        serverError: _saveError,
        onSubmit: (m) => unawaited(_save(m)),
      ),
      noSizeChart: (_) => _Message(
        "The seller hasn't added a size chart for this item yet, so we "
        "can't recommend a size.",
        action: TextButton(
          onPressed: notifier.edit,
          child: const Text('Edit my measurements'),
        ),
      ),
      loadFailure: (failure) => _Message(
        failure.displayMessage,
        action: TextButton(
          onPressed: () => unawaited(notifier.load()),
          child: const Text('Retry'),
        ),
      ),
      loadSuccess: (fit, measurements) => _FitResult(
        fit: fit,
        selectedSize: widget.selectedSize,
        chartSizes: widget.chartSizes,
        onSizeSelected: widget.onSizeSelected,
        onEdit: notifier.edit,
      ),
    );
  }

  Widget _loader() => const Padding(
    padding: EdgeInsets.all(DesignTokens.s24),
    child: Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    ),
  );
}

class _FitResult extends StatelessWidget {
  const _FitResult({
    required this.fit,
    required this.selectedSize,
    required this.chartSizes,
    required this.onSizeSelected,
    required this.onEdit,
  });

  final FitRecommendation fit;
  final String? selectedSize;
  final List<String> chartSizes;
  final ValueChanged<String> onSizeSelected;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sizes = fit.perSize.isNotEmpty
        ? [for (final s in fit.perSize) s.sizeLabel]
        : chartSizes;
    final selected = selectedSize == null ? null : fit.fitFor(selectedSize!);
    final rec = fit.recommendedSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreenDark,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rec == null
                    ? 'No size is a clear fit'
                    : 'We recommend size $rec',
                key: const Key('fit-recommended'),
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              if (fit.basedOn.isNotEmpty)
                Text(
                  fit.basedOn,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              Text(
                'Confidence: ${_confidenceLabel(fit.confidence)}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (fit.missingMeasurements.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Add ${fit.missingMeasurements.map(_humanField).join(', ')} for a '
            'more confident recommendation.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorWarning,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s12),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: [
            for (final size in sizes)
              _VerdictChip(
                size: size,
                verdict: fit.fitFor(size)?.verdict ?? FitVerdict.unknown,
                selected: size == selectedSize,
                recommended: size == rec,
                onTap: () => onSizeSelected(size),
              ),
          ],
        ),
        if (selected != null && selected.notes.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          for (final note in selected.notes)
            Text(
              '• $note',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
        ],
        const SizedBox(height: DesignTokens.s8),
        TextButton(
          onPressed: onEdit,
          child: const Text('Edit my measurements'),
        ),
      ],
    );
  }

  static String _confidenceLabel(double c) => c >= 0.75
      ? 'high'
      : c >= 0.45
      ? 'medium'
      : 'low';

  /// "chestCm" → "chest".
  static String _humanField(String wire) {
    final base = wire.replaceAll(RegExp(r'(Cm|Kg)$'), '');
    return base
        .replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m[1]!.toLowerCase()}')
        .trim();
  }
}

class _VerdictChip extends StatelessWidget {
  const _VerdictChip({
    required this.size,
    required this.verdict,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  final String size;
  final FitVerdict verdict;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  Color get _color => switch (verdict) {
    FitVerdict.good => DesignTokens.colorSuccess,
    FitVerdict.snug || FitVerdict.loose => DesignTokens.colorWarning,
    FitVerdict.tooSmall || FitVerdict.tooLarge => DesignTokens.colorError,
    FitVerdict.unknown => DesignTokens.textMuted,
  };

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: Key('fit-chip-$size'),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: DesignTokens.chipsSelectedFill,
      backgroundColor: DesignTokens.bgAppBodyLight,
      side: BorderSide(
        color: selected ? DesignTokens.chipsSelectedBorder : _color,
      ),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            recommended ? '$size ★' : size,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(verdict.label, style: DesignTokens.tiny.copyWith(color: _color)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(DesignTokens.s16),
    child: Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        ?action,
      ],
    ),
  );
}
