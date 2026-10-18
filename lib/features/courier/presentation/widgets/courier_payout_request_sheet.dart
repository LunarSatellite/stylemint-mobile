import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_payout.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/payout_providers.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the request sheet. Resolves to the new payout, or null when the
/// rider closed it without asking.
Future<CourierPayout?> showCourierPayoutRequestSheet(
  BuildContext context, {
  required CourierBalance balance,
  required List<PayoutDestinationDto> destinations,
}) => showModalBottomSheet<CourierPayout>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DesignTokens.bgAppBody,
  builder: (_) => CourierPayoutRequestSheet(
    balance: balance,
    destinations: destinations,
  ),
);

/// What the server's refusal means, in words a rider can act on
/// (rider-payout contract v1 §3, POST request).
String courierPayoutRequestError(
  NetworkExceptions failure,
  CourierBalance balance,
) {
  if (failure.isNotFound) {
    return 'That payout method was not found. Add it again and retry.';
  }
  if (failure.isNoInternet) {
    return 'No connection. Nothing was requested — try again.';
  }
  final field = failure.maybeWhen(
    validation: (_, _, field, _) => field,
    orElse: () => null,
  );
  final code = failure.validationCode;
  switch (field) {
    case 'PAYOUT_IN_FLIGHT':
      return 'A payout is already on its way. You can ask again once it is '
          'paid.';
    case 'rule.insufficient_balance':
      return 'That is more than you can be paid right now '
          '(${formatMoney(balance.money(balance.netPayable))}).';
    case 'CASH_EXCEEDS_EARNINGS':
      return 'The cash you collected is more than your earnings. Hand it in '
          'first, then ask for a payout.';
  }
  if (code == 'validation.out_of_range') {
    final min = balance.onDemandMinAmount;
    final max = balance.onDemandMaxAmount;
    if (min != null && max != null) {
      return 'An on-demand payout must be between '
          '${formatMoney(balance.money(min), decimalDigits: 0)} and '
          '${formatMoney(balance.money(max), decimalDigits: 0)}.';
    }
    return 'That amount is outside what can be paid on demand.';
  }
  final message = failure.maybeWhen(
    validation: (_, message, _, _) => message,
    orElse: () => null,
  );
  return message ?? 'The payout could not be requested. Try again.';
}

/// Ask for a payout: where to, and how much (the whole net payable unless the
/// rider types less). Shows the on-demand fee before they confirm.
class CourierPayoutRequestSheet extends ConsumerStatefulWidget {
  const CourierPayoutRequestSheet({
    required this.balance,
    required this.destinations,
    super.key,
  });

  final CourierBalance balance;
  final List<PayoutDestinationDto> destinations;

  static const Key amountKey = ValueKey<String>('courier-payout-amount');
  static const Key submitKey = ValueKey<String>('courier-payout-submit');
  static const Key errorKey = ValueKey<String>('courier-payout-error');

  @override
  ConsumerState<CourierPayoutRequestSheet> createState() =>
      _CourierPayoutRequestSheetState();
}

class _CourierPayoutRequestSheetState
    extends ConsumerState<CourierPayoutRequestSheet> {
  late String? _destinationId;
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  CourierBalance get _balance => widget.balance;

  @override
  void initState() {
    super.initState();
    final preferred = widget.destinations
        .where((d) => d.isDefault)
        .followedBy(widget.destinations);
    _destinationId = preferred.isEmpty ? null : preferred.first.id;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Null = the whole net payable. A non-number is NaN, caught by [_check].
  double? get _typed {
    final text = _amount.text.trim().replaceAll(',', '');
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? double.nan;
  }

  double get _effective => _typed ?? _balance.netPayable;

  String? _check() {
    if (_destinationId == null) return 'Choose where to send it.';
    final amount = _effective;
    if (amount.isNaN || amount <= 0) return 'Enter an amount above zero.';
    if (amount > _balance.netPayable + 0.001) {
      return 'You can be paid at most '
          '${formatMoney(_balance.money(_balance.netPayable))} right now.';
    }
    final min = _balance.onDemandMinAmount;
    final max = _balance.onDemandMaxAmount;
    if (min != null && amount < min) {
      return 'An on-demand payout starts at '
          '${formatMoney(_balance.money(min), decimalDigits: 0)}. Smaller '
          'balances are paid automatically every Friday.';
    }
    if (max != null && amount > max) {
      return 'An on-demand payout is at most '
          '${formatMoney(_balance.money(max), decimalDigits: 0)}. Enter a '
          'smaller amount.';
    }
    return null;
  }

  Future<void> _submit() async {
    final problem = _check();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(courierPayoutsRepositoryProvider)
        .requestPayout(destinationId: _destinationId!, amount: _typed);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _busy = false;
        _error = courierPayoutRequestError(failure, _balance);
      }),
      (payout) {
        ref
          ..invalidate(courierBalanceProvider)
          ..invalidate(courierPayoutsProvider);
        Navigator.of(context).pop(payout);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = _effective;
    final fee = amount.isNaN || amount <= 0 ? null : _balance.feeFor(amount);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DesignTokens.s20,
          DesignTokens.s20,
          DesignTokens.s20,
          DesignTokens.s20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Request a payout', style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'You can be paid '
                '${formatMoney(_balance.money(_balance.netPayable))} now.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              Text('Send to', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              for (final d in widget.destinations)
                RadioListTile<String>(
                  key: ValueKey<String>('courier-payout-dest-${d.id}'),
                  value: d.id,
                  groupValue: _destinationId,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    d.label.isEmpty ? d.kind.label : d.label,
                    style: DesignTokens.bodyText,
                  ),
                  subtitle: Text(
                    '${d.kind.label} · ${d.accountIdentifierMasked}'
                    '${d.isDefault ? ' · Default' : ''}',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _destinationId = v),
                ),
              const SizedBox(height: DesignTokens.s12),
              TextField(
                key: CourierPayoutRequestSheet.amountKey,
                controller: _amount,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Amount (${_balance.currency})',
                  hintText: _balance.netPayable.toStringAsFixed(2),
                  helperText: 'Leave empty for the full amount',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              if (fee != null) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'On-demand fee ${formatMoney(_balance.money(fee))} · you '
                  'receive ${formatMoney(_balance.money(amount - fee))}',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Finance sends it by bank or wallet transfer after a short '
                'check. You will see the reference here once it is paid.',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: DesignTokens.s12),
                Text(
                  error,
                  key: CourierPayoutRequestSheet.errorKey,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.s16),
              FilledButton(
                key: CourierPayoutRequestSheet.submitKey,
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Requesting…' : 'Request payout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
