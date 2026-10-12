import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// A vendor's opt-in to pay later and pay-now-buy-later, for all their
/// products. EMI stays per product.
///
/// Pay later is guaranteed by StyleMint, which charges a risk fee on what it
/// guarantees. The vendor accepts the fee as it stands today; if StyleMint
/// changes it, pay later stops being offered until the vendor accepts again,
/// and this card says so.
class VendorCreditProgramCard extends ConsumerWidget {
  const VendorCreditProgramCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(vendorCreditProgramProvider);
    return program.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => PlanCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                error is EmiLoadException
                    ? creditFailureMessage(error.failure)
                    : 'Could not load your payment-plan settings.',
                style: DesignTokens.smallRegular,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(vendorCreditProgramProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (value) => _ProgramForm(program: value),
    );
  }
}

/// The tenures each kind may offer, as the backend allows them.
const _payLaterTenureChoices = [3, 6];
const _prepayTenureChoices = [3, 6, 9, 12];

class _ProgramForm extends ConsumerStatefulWidget {
  const _ProgramForm({required this.program});

  final VendorCreditProgram program;

  @override
  ConsumerState<_ProgramForm> createState() => _ProgramFormState();
}

class _ProgramFormState extends ConsumerState<_ProgramForm> {
  late bool _payLater = widget.program.payLaterEnabled;
  late Set<int> _payLaterTenures = {...widget.program.payLaterTenures};
  late int _payLaterFirst = widget.program.payLaterEnabled
      ? widget.program.payLaterDownPaymentPercent
      : 25;
  late bool _prepay = widget.program.prepayEnabled;
  late Set<int> _prepayTenures = {...widget.program.prepayTenures};
  late int _deposit = widget.program.prepayEnabled
      ? widget.program.prepayDepositPercent
      : 10;
  bool _saving = false;
  String? _error;

  double get _fee => widget.program.currentPlatformRiskFeePercent;

  bool get _valid =>
      (!_payLater || _payLaterTenures.isNotEmpty) &&
      (!_prepay || _prepayTenures.isNotEmpty);

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final next = VendorCreditProgram(
      payLaterEnabled: _payLater,
      payLaterTenures: (_payLaterTenures.toList()..sort()),
      payLaterDownPaymentPercent: _payLaterFirst,
      // Saving with pay later on is accepting today's fee, shown above.
      payLaterAcceptedRiskFeePercent: _fee,
      currentPlatformRiskFeePercent: _fee,
      payLaterOffered: false,
      prepayEnabled: _prepay,
      prepayTenures: (_prepayTenures.toList()..sort()),
      prepayDepositPercent: _deposit,
    );
    final result = await ref
        .read(creditRepositoryProvider)
        .putVendorProgram(next, idempotencyKey: const Uuid().v4());
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _saving = false;
        _error = creditFailureMessage(failure);
      }),
      (_) {
        setState(() => _saving = false);
        ref.invalidate(vendorCreditProgramProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment-plan settings saved')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.program;
    return PlanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('vendor-paylater-switch'),
            contentPadding: EdgeInsets.zero,
            value: _payLater,
            onChanged: _saving ? null : (v) => setState(() => _payLater = v),
            title: const Text('Pay later', style: DesignTokens.mediumSemibold),
            subtitle: Text(
              'StyleMint guarantees the plan: you are owed the price, less a '
              '${_fee.toStringAsFixed(_fee == _fee.roundToDouble() ? 0 : 2)}% '
              'risk fee on the amount paid later, whether or not the buyer '
              'pays.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ),
          if (p.payLaterNeedsFeeAcceptance)
            Text(
              "StyleMint's risk fee has changed since you accepted it, so pay "
              "later is paused on your products. Save to accept today's fee.",
              key: const Key('vendor-paylater-fee-changed'),
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.colorWarning,
              ),
            ),
          if (_payLater) ...[
            const SizedBox(height: DesignTokens.s8),
            _Tenures(
              selected: _payLaterTenures,
              choices: _payLaterTenureChoices,
              onChanged: (t) => setState(() => _payLaterTenures = t),
            ),
            _Percent(
              label: 'First payment',
              value: _payLaterFirst,
              min: 0,
              max: 50,
              onChanged: (v) => setState(() => _payLaterFirst = v),
            ),
          ],
          const Divider(color: DesignTokens.borderDefault, height: 24),
          SwitchListTile(
            key: const Key('vendor-prepay-switch'),
            contentPadding: EdgeInsets.zero,
            value: _prepay,
            onChanged: _saving ? null : (v) => setState(() => _prepay = v),
            title: const Text(
              'Pay now, buy later',
              style: DesignTokens.mediumSemibold,
            ),
            subtitle: Text(
              'Buyers pay monthly and you send the item once it is paid in '
              'full. Nothing is lent, so there is no unpaid risk.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ),
          if (_prepay) ...[
            const SizedBox(height: DesignTokens.s8),
            _Tenures(
              selected: _prepayTenures,
              choices: _prepayTenureChoices,
              onChanged: (t) => setState(() => _prepayTenures = t),
            ),
            _Percent(
              label: 'Deposit',
              value: _deposit,
              min: 0,
              max: 90,
              onChanged: (v) => setState(() => _deposit = v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              _error!,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.colorError),
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Buyers see these plans on your products once StyleMint has them '
            'switched on.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: FilledButton(
              key: const Key('vendor-program-save'),
              onPressed: _saving || !_valid ? null : () => unawaited(_save()),
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.buttonPrimaryFill,
                foregroundColor: DesignTokens.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
              ),
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tenures extends StatelessWidget {
  const _Tenures({
    required this.selected,
    required this.choices,
    required this.onChanged,
  });

  final Set<int> selected;
  final List<int> choices;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: DesignTokens.s8,
    runSpacing: DesignTokens.s8,
    children: [
      for (final months in choices)
        FilterChip(
          label: Text('$months months'),
          selected: selected.contains(months),
          selectedColor: DesignTokens.chipsSelectedFill,
          onSelected: (on) {
            final next = {...selected};
            on ? next.add(months) : next.remove(months);
            onChanged(next);
          },
        ),
    ],
  );
}

class _Percent extends StatelessWidget {
  const _Percent({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.s8),
        PlanRow(label: label, value: '$clamped% of the price'),
        Slider(
          value: clamped.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ 5,
          label: '$clamped%',
          activeColor: DesignTokens.primaryGreen,
          onChanged: (v) => onChanged((v / 5).round() * 5),
        ),
      ],
    );
  }
}
