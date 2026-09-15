import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum TrackingStepState { done, current, upcoming }

/// Colour family of a step marker: normal progress (green), a negative
/// ending (cancelled / rejected, red) or a return (warning tone).
enum TrackingStepTone { progress, negative, caution }

/// One row of a vertical step list.
class TrackingStepVm {
  const TrackingStepVm({
    required this.title,
    required this.state,
    this.subtitle,
    this.timestamp,
    this.note,
    this.tone = TrackingStepTone.progress,
  });

  final String title;
  final TrackingStepState state;

  /// Short explanation, shown for the current step.
  final String? subtitle;

  /// Already formatted for display.
  final String? timestamp;

  /// Free text from the seller or courier (e.g. a handover note).
  final String? note;
  final TrackingStepTone tone;
}

/// Vertical timeline: a rail of markers joined by a connector, with the
/// title, timestamp and note beside each marker. Done steps are solid, the
/// current step is ringed and emphasised, upcoming steps are hollow and muted.
class TrackingStepList extends StatelessWidget {
  const TrackingStepList({required this.steps, super.key});

  final List<TrackingStepVm> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isLast: i == steps.length - 1,
            connectorLit:
                i < steps.length - 1 &&
                steps[i].state == TrackingStepState.done &&
                steps[i + 1].state != TrackingStepState.upcoming,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.isLast,
    required this.connectorLit,
  });

  final TrackingStepVm step;
  final bool isLast;
  final bool connectorLit;

  static const double _railWidth = 28;

  String get _stateLabel => switch (step.state) {
    TrackingStepState.done => 'done',
    TrackingStepState.current => 'current step',
    TrackingStepState.upcoming => 'upcoming',
  };

  @override
  Widget build(BuildContext context) {
    final isCurrent = step.state == TrackingStepState.current;
    final isUpcoming = step.state == TrackingStepState.upcoming;
    final titleStyle = isCurrent
        ? DesignTokens.mediumSemibold.copyWith(fontSize: 15)
        : isUpcoming
        ? DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
            height: 1.3,
          )
        : DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textLight,
            fontWeight: FontWeight.w500,
          );
    final semanticsLabel = [
      step.title,
      _stateLabel,
      if (step.timestamp != null) step.timestamp!,
      if (isCurrent && step.subtitle != null) step.subtitle!,
      if (step.note != null) step.note!,
    ].join(', ');

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _railWidth,
              child: Column(
                children: [
                  SizedBox(
                    height: 24,
                    child: Center(
                      child: _Marker(state: step.state, tone: step.tone),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: connectorLit
                              ? DesignTokens.primaryGreen.withValues(
                                  alpha: 0.7,
                                )
                              : DesignTokens.borderDefault,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: 2,
                  bottom: isLast ? 0 : DesignTokens.s20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(step.title, style: titleStyle),
                    if (isCurrent && step.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle!,
                        style: DesignTokens.smallDescription.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ],
                    if (step.timestamp != null) ...[
                      const SizedBox(height: 2),
                      Text(step.timestamp!, style: DesignTokens.smallRegular),
                    ],
                    if (step.note != null && step.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.s8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSmall,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 14,
                                color: DesignTokens.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  step.note!.trim(),
                                  style: DesignTokens.smallDescription.copyWith(
                                    color: DesignTokens.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.state, required this.tone});

  final TrackingStepState state;
  final TrackingStepTone tone;

  Color get _toneColor => switch (tone) {
    TrackingStepTone.progress => DesignTokens.primaryGreen,
    TrackingStepTone.negative => DesignTokens.colorError,
    TrackingStepTone.caution => DesignTokens.warning500,
  };

  IconData get _doneIcon => switch (tone) {
    TrackingStepTone.progress => Icons.check_rounded,
    TrackingStepTone.negative => Icons.close_rounded,
    TrackingStepTone.caution => Icons.keyboard_return_rounded,
  };

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case TrackingStepState.done:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: _toneColor, shape: BoxShape.circle),
          child: Icon(
            _doneIcon,
            size: 13,
            color: tone == TrackingStepTone.progress
                ? DesignTokens.buttonPrimaryText
                : DesignTokens.textDark,
          ),
        );
      case TrackingStepState.current:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _toneColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: _toneColor, width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _toneColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      case TrackingStepState.upcoming:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: DesignTokens.borderDefault, width: 1.5),
          ),
        );
    }
  }
}
