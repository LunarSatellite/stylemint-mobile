import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/delivery_confirm_link.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_confirm_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_confirm_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Scan the rider's code" for a return: the buyer handing the item to the
/// rider, or the seller taking it back from them.
///
/// The same proof as a delivery (return pickup contract §2): the rider shows
/// a QR with a 6-digit code under it, and the person in front of them scans
/// it or types it. `POST /v1/customer/deliveries/confirm` decides whether
/// this account is the one that may confirm.
class ReturnHandoverConfirm extends ConsumerStatefulWidget {
  const ReturnHandoverConfirm({
    required this.confirmKey,
    required this.packageNumber,
    required this.onConfirmed,
    this.seller = false,
    this.scanner = scanRiderDeliveryQr,
    super.key,
  });

  /// Keys the confirmation's progress, so two returns never share one.
  final String confirmKey;
  final String packageNumber;
  final Future<void> Function() onConfirmed;

  /// The seller taking the item back (wording only).
  final bool seller;
  final DeliveryQrScanner scanner;

  static const scanKey = ValueKey<String>('return-handover-scan');
  static const showCodeKey = ValueKey<String>('return-handover-show-code');
  static const scanLabel = "Scan rider's code";

  @override
  ConsumerState<ReturnHandoverConfirm> createState() =>
      _ReturnHandoverConfirmState();
}

class _ReturnHandoverConfirmState extends ConsumerState<ReturnHandoverConfirm> {
  bool _typing = false;

  DeliveryConfirmNotifier get _notifier =>
      ref.read(deliveryConfirmNotifierProvider(widget.confirmKey).notifier);

  Future<void> _scan() async {
    final notifier = _notifier;
    final raw = await widget.scanner(context);
    if (raw == null || !mounted) return;
    if (DeliveryConfirmLink.token(raw) == null) {
      SmSnackbar.error(
        context,
        "That isn't the rider's code. Scan the QR on their phone, or type "
        'the 6 digits instead.',
        seconds: 4,
      );
      return;
    }
    notifier.reset();
    await _finish(await notifier.confirmQr(raw));
  }

  Future<void> _submitCode(String packageNumber, String code) async {
    final notifier = _notifier..reset();
    await _finish(
      await notifier.confirmCode(packageNumber: packageNumber, code: code),
    );
  }

  Future<void> _finish(bool done) async {
    if (!done || !mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    SmSnackbar.success(
      context,
      widget.seller ? 'Return received.' : 'Handed over. Thanks!',
    );
    await widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryConfirmNotifierProvider(widget.confirmKey));
    final busy = state is DeliveryConfirmSubmitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state case DeliveryConfirmFailed(:final failure)) ...[
          Text(
            returnHandoverMessage(failure, seller: widget.seller),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorError,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
        if (state is DeliveryConfirmDone)
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s8),
              Text(
                widget.seller ? 'Received ✓' : 'Handed over ✓',
                style: DesignTokens.mediumSemibold,
              ),
            ],
          )
        else ...[
          SizedBox(
            height: DesignTokens.buttonHeight,
            child: FilledButton.icon(
              key: ReturnHandoverConfirm.scanKey,
              onPressed: busy ? null : _scan,
              icon: busy && !_typing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
              label: Text(
                busy && !_typing ? 'Confirming…' : ReturnHandoverConfirm.scanLabel,
              ),
            ),
          ),
          if (_typing)
            DeliveryCodeForm(
              key: const ValueKey<String>('return-handover-code-form'),
              initialPackageNumber: widget.packageNumber,
              busy: busy,
              submitLabel: widget.seller ? 'Confirm receipt' : 'Hand over',
              packageHint: 'SM-R-00000000',
              onSubmit: _submitCode,
            )
          else
            Center(
              child: TextButton(
                key: ReturnHandoverConfirm.showCodeKey,
                onPressed: busy ? null : () => setState(() => _typing = true),
                child: const Text('Type the code instead'),
              ),
            ),
        ],
      ],
    );
  }
}

/// A failed return handover in plain words.
String returnHandoverMessage(
  DeliveryConfirmFailure failure, {
  required bool seller,
}) => switch (failure) {
  DeliveryConfirmNotRecipient() =>
    seller
        ? "This return isn't for your shop. Check you're signed in to the "
              'right seller account.'
        : "This return isn't on your account. Check you're signed in to the "
              'account that placed the order.',
  DeliveryConfirmExpired() =>
    'That code has expired. Ask the rider for a new one.',
  DeliveryConfirmInvalid() =>
    "That code doesn't match. Check the number and the 6 digits on the "
        "rider's screen.",
  DeliveryConfirmTooManyAttempts() =>
    'Too many wrong codes. Try again in 15 minutes.',
  DeliveryConfirmAlreadyConfirmed() => 'Already confirmed.',
  DeliveryConfirmOtherFailure(offline: true) =>
    "You're offline. Connect and try again.",
  DeliveryConfirmOtherFailure(:final message?) => message,
  DeliveryConfirmOtherFailure() => "Couldn't confirm just now. Try again.",
};
