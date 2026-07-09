import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class AdjustCommissionArgs {
  const AdjustCommissionArgs({
    required this.partnershipId,
    required this.creatorLabel,
    required this.currentMinPercent,
    required this.currentMaxPercent,
  });

  final String partnershipId;
  final String creatorLabel;

  /// Fractions (0..1), matching the backend convention.
  final double currentMinPercent;
  final double currentMaxPercent;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdjustCommissionScreen extends ConsumerStatefulWidget {
  const AdjustCommissionScreen({super.key, required this.args});

  final AdjustCommissionArgs args;

  @override
  ConsumerState<AdjustCommissionScreen> createState() =>
      _AdjustCommissionScreenState();
}

class _AdjustCommissionScreenState
    extends ConsumerState<AdjustCommissionScreen> {
  late RangeValues _range;
  final _reasonCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      (widget.args.currentMinPercent * 100).clamp(0, 100),
      (widget.args.currentMaxPercent * 100).clamp(0, 100),
    );
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await ref
        .read(partnershipsListNotifierProvider.notifier)
        .adjustCommission(
          widget.args.partnershipId,
          commissionMinPercent: _range.start / 100,
          commissionMaxPercent: _range.end / 100,
          reason: _reasonCtrl.text.trim().isEmpty
              ? null
              : _reasonCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Commission rate updated!' : 'Failed to update commission.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok
            ? DesignTokens.primaryGreen
            : DesignTokens.colorError,
      ),
    );
    if (ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Adjust Commission',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CreatorCard(
                    label: widget.args.creatorLabel,
                    currentMinPercent: widget.args.currentMinPercent,
                    currentMaxPercent: widget.args.currentMaxPercent,
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  _RangeCard(
                    range: _range,
                    onChanged: (v) => setState(() => _range = v),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    decoration: BoxDecoration(
                      color: DesignTokens.bgAppBodyLight,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.cardRadius,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reason (optional)',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        TextField(
                          controller: _reasonCtrl,
                          maxLines: 3,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Why are you adjusting this rate?',
                            hintStyle: const TextStyle(
                              color: DesignTokens.textMuted,
                            ),
                            filled: true,
                            fillColor: DesignTokens.bgAppFoundation,
                            contentPadding: const EdgeInsets.all(
                              DesignTokens.s12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                12,
                DesignTokens.s16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Update Commission Rate',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Creator card ─────────────────────────────────────────────────────────────

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({
    required this.label,
    required this.currentMinPercent,
    required this.currentMaxPercent,
  });

  final String label;
  final double currentMinPercent;
  final double currentMaxPercent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 48,
              height: 48,
              color: DesignTokens.bgAppFoundation,
              alignment: Alignment.center,
              child: Text(
                label.isNotEmpty ? label[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Current: ${(currentMinPercent * 100).round()}%'
                    '–${(currentMaxPercent * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: DesignTokens.primaryGreen,
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
}

// ─── Range card ───────────────────────────────────────────────────────────────

class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.range, required this.onChanged});

  final RangeValues range;
  final ValueChanged<RangeValues> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        12,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Commission Range: '
            '${range.start.round()}%–${range.end.round()}%',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
          RangeSlider(
            values: range,
            min: 0,
            max: 50,
            divisions: 50,
            activeColor: DesignTokens.primaryGreen,
            inactiveColor: DesignTokens.borderDefault,
            onChanged: onChanged,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
                  ),
                ),
                Text(
                  '50%',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: DesignTokens.textMuted,
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
