import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the caller hands this screen: which line is being tagged, how far it
/// has travelled, and what to call it on screen.
typedef UnitMarkerBindArgs = ({
  String subOrderLineId,
  OrderLineFulfilmentStage stage,
  String? lineLabel,
});

/// Surface 2 — **binding at pack or handover**.
///
/// Three outcomes share this screen and none of them is dressed as another:
///
/// * **Bound.** The tag now identifies that unit.
/// * **Refused (409).** The marker already carries a live binding. The
///   backend will not overwrite it, and neither does the app: it shows the
///   server's sentence and offers the *correction* form, which is a different
///   operation with a different requirement.
/// * **Refused by a rule (400).** The stage, the variant or the line's
///   quantity will not allow it. The server's own sentence says which and is
///   rendered verbatim.
///
/// Correction closes at Delivered. When it is closed the control stays on
/// screen, disabled, with the reason beside it — a control that quietly
/// vanishes teaches a packer nothing.
class UnitMarkerBindScreen extends ConsumerStatefulWidget {
  const UnitMarkerBindScreen({required this.args, super.key});

  final UnitMarkerBindArgs args;

  static const String title = 'Tag this unit';
  static const String markerFieldLabel = 'Tag code';
  static const String markerFieldHint = 'Scan or type the 26-character code';
  static const String bindLabel = 'Bind tag';
  static const String correctLabel = 'Correct binding';
  static const String correctionHeading = 'Correct an existing binding';
  static const String reasonFieldLabel = 'Why was the first binding wrong?';
  static const String reasonRequired =
      'A correction has to say why. The superseded binding keeps this '
      'sentence for good, so it is the record of what happened — write what '
      'actually went wrong.';
  static const String malformedBody =
      'That is not a StyleMint tag code. A code is 26 characters from the tag '
      'itself.';
  static const String boundHeading = 'Bound';
  static const String correctedHeading = 'Correction recorded';
  static const String correctedBody =
      'The earlier binding is kept with your reason attached, and this new '
      'one points back at it. Nothing was erased.';
  static const String alreadyBoundHeading = 'Already bound';
  static const String ruleRefusedHeading = 'Not allowed on this line';
  static const String notFoundHeading = 'Not found';
  static const String correctionClosedLabel = 'Correction is closed';

  @override
  ConsumerState<UnitMarkerBindScreen> createState() =>
      _UnitMarkerBindScreenState();
}

class _UnitMarkerBindScreenState extends ConsumerState<UnitMarkerBindScreen> {
  final TextEditingController _marker = TextEditingController();
  final TextEditingController _reason = TextEditingController();
  UnitBindingStage _stage = UnitBindingStage.pack;
  bool _correcting = false;

  @override
  void dispose() {
    _marker.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = (
      subOrderLineId: widget.args.subOrderLineId,
      stage: widget.args.stage,
    );
    final provider = unitMarkerBindNotifierProvider(target);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final closedReason = notifier.closedReason;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: const SmAppBar(title: UnitMarkerBindScreen.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.args.lineLabel case final label?
                  when label.trim().isNotEmpty) ...[
                Text(label, style: DesignTokens.h3),
                const SizedBox(height: DesignTokens.s12),
              ],
              if (closedReason case final reason?) ...[
                _Banner(
                  icon: Icons.lock_outline_rounded,
                  tone: _BannerTone.neutral,
                  heading:
                      widget.args.stage.bindingClosedHeading ??
                      UnitMarkerBindScreen.correctionClosedLabel,
                  body: reason,
                ),
                const SizedBox(height: DesignTokens.s16),
              ],
              _MarkerField(controller: _marker, enabled: notifier.isOpen),
              const SizedBox(height: DesignTokens.s16),
              _StagePicker(
                value: _stage,
                enabled: notifier.isOpen,
                onChanged: (value) => setState(() => _stage = value),
              ),
              const SizedBox(height: DesignTokens.s20),
              if (_correcting) ...[
                const Text(
                  UnitMarkerBindScreen.correctionHeading,
                  style: DesignTokens.mediumSemibold,
                ),
                const SizedBox(height: DesignTokens.s8),
                _ReasonField(controller: _reason, enabled: notifier.isOpen),
                const SizedBox(height: DesignTokens.s16),
              ],
              if (state is UnitMarkerBindInProgress)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
                  child: Center(
                    child: SmBrandLoader(semanticLabel: 'Recording'),
                  ),
                )
              else ...[
                SmPrimaryButton(
                  label: _correcting
                      ? UnitMarkerBindScreen.correctLabel
                      : UnitMarkerBindScreen.bindLabel,
                  disabled: !notifier.isOpen,
                  onPressed: () async => _submit(notifier),
                ),
                const SizedBox(height: DesignTokens.s12),
                if (!_correcting)
                  SmOutlinedButton(
                    label: UnitMarkerBindScreen.correctLabel,
                    // Closed rather than hidden: the packer is told the
                    // control exists and why it will not work.
                    onPressed: notifier.isOpen
                        ? () => setState(() => _correcting = true)
                        : () {},
                    labelColor: notifier.isOpen
                        ? DesignTokens.textWhite
                        : DesignTokens.textMuted,
                    borderColor: notifier.isOpen
                        ? DesignTokens.borderDefault
                        : DesignTokens.sectionOnBase,
                  ),
              ],
              const SizedBox(height: DesignTokens.s20),
              _Outcome(state: state),
              const SizedBox(height: DesignTokens.s24),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(UnitMarkerBindNotifier notifier) {
    if (!notifier.isOpen) return;
    if (_correcting) {
      unawaited(
        notifier.correct(_marker.text, stage: _stage, reason: _reason.text),
      );
      return;
    }
    unawaited(notifier.bind(_marker.text, stage: _stage));
  }
}

/// The cleartext tag code, held in a controller for exactly as long as this
/// screen lives and handed straight to the repository. It is never put in the
/// state, never in a route, never logged.
class _MarkerField extends StatelessWidget {
  const _MarkerField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        UnitMarkerBindScreen.markerFieldLabel,
        style: DesignTokens.mediumSemibold,
      ),
      const SizedBox(height: DesignTokens.s8),
      TextField(
        controller: controller,
        enabled: enabled,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        style: DesignTokens.body.copyWith(fontFamily: 'monospace'),
        decoration: InputDecoration(
          hintText: UnitMarkerBindScreen.markerFieldHint,
          hintStyle: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.inputFieldPlaceholder,
          ),
          filled: true,
          fillColor: DesignTokens.inputFieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
    ],
  );
}

class _ReasonField extends StatelessWidget {
  const _ReasonField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        UnitMarkerBindScreen.reasonFieldLabel,
        style: DesignTokens.mediumSemibold,
      ),
      const SizedBox(height: DesignTokens.s8),
      TextField(
        controller: controller,
        enabled: enabled,
        maxLines: 3,
        maxLength: UnitMarkerBindNotifier.reasonMaxLength,
        style: DesignTokens.body,
        decoration: InputDecoration(
          filled: true,
          fillColor: DesignTokens.inputFieldFill,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          ),
        ),
      ),
    ],
  );
}

class _StagePicker extends StatelessWidget {
  const _StagePicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final UnitBindingStage value;
  final bool enabled;
  final ValueChanged<UnitBindingStage> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'When was the tag attached?',
        style: DesignTokens.mediumSemibold,
      ),
      const SizedBox(height: DesignTokens.s8),
      Wrap(
        spacing: DesignTokens.s8,
        runSpacing: DesignTokens.s8,
        children: [
          for (final stage in UnitBindingStage.selectable)
            ChoiceChip(
              label: Text(stage.label),
              selected: stage == value,
              onSelected: enabled ? (_) => onChanged(stage) : null,
            ),
        ],
      ),
    ],
  );
}

/// Renders exactly one outcome, each in its own words.
class _Outcome extends StatelessWidget {
  const _Outcome({required this.state});

  final UnitMarkerBindState state;

  @override
  Widget build(BuildContext context) => switch (state) {
    UnitMarkerBindIdle() ||
    UnitMarkerBindInProgress() => const SizedBox.shrink(),
    UnitMarkerBindSucceeded(:final binding, :final wasCorrection) => _Banner(
      icon: Icons.check_circle_outline_rounded,
      tone: _BannerTone.good,
      heading: wasCorrection
          ? UnitMarkerBindScreen.correctedHeading
          : UnitMarkerBindScreen.boundHeading,
      body: wasCorrection
          ? UnitMarkerBindScreen.correctedBody
          : 'Tag ${binding.markerReference} now identifies this unit.',
    ),
    // The server's sentence, untouched. It already names the case —
    // "already bound to another order line. Record a correction if the first
    // binding was wrong." — and rewriting it is how a screen starts saying
    // something the backend never said.
    UnitMarkerBindRefusedState(:final refusal) => _Banner(
      icon: switch (refusal.kind) {
        UnitMarkerBindRefusalKind.alreadyBound => Icons.link_rounded,
        UnitMarkerBindRefusalKind.ruleRefused => Icons.block_rounded,
        UnitMarkerBindRefusalKind.notFound => Icons.search_off_rounded,
      },
      tone: _BannerTone.refused,
      heading: switch (refusal.kind) {
        UnitMarkerBindRefusalKind.alreadyBound =>
          UnitMarkerBindScreen.alreadyBoundHeading,
        UnitMarkerBindRefusalKind.ruleRefused =>
          UnitMarkerBindScreen.ruleRefusedHeading,
        UnitMarkerBindRefusalKind.notFound =>
          UnitMarkerBindScreen.notFoundHeading,
      },
      body: refusal.message,
    ),
    UnitMarkerBindMalformed() => const _Banner(
      icon: Icons.qr_code_scanner_rounded,
      tone: _BannerTone.refused,
      heading: 'Not a tag code',
      body: UnitMarkerBindScreen.malformedBody,
    ),
    UnitMarkerCorrectionNeedsReason() => const _Banner(
      icon: Icons.edit_note_rounded,
      tone: _BannerTone.refused,
      heading: 'Reason required',
      body: UnitMarkerBindScreen.reasonRequired,
    ),
    UnitMarkerBindFailed(:final failure) => _Banner(
      icon: Icons.cloud_off_rounded,
      tone: _BannerTone.bad,
      heading: "We couldn't reach StyleMint",
      body: NetworkExceptions.getMessage(failure),
    ),
  };
}

enum _BannerTone { neutral, good, refused, bad }

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.tone,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final _BannerTone tone;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _BannerTone.neutral => DesignTokens.textLight,
      _BannerTone.good => DesignTokens.colorSuccess,
      _BannerTone.refused => DesignTokens.warning300,
      _BannerTone.bad => DesignTokens.colorError,
    };
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: DesignTokens.s20, color: color),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: DesignTokens.mediumSemibold.copyWith(color: color),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  body,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
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
