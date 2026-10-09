import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/delivery_confirm_link.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_confirm_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/parcel_code_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the camera for the rider's proof-of-delivery QR and returns the
/// scanned value, or null when the buyer backed out. Overridable so widget
/// tests need no camera.
typedef DeliveryQrScanner = Future<String?> Function(BuildContext context);

Future<String?> scanRiderDeliveryQr(BuildContext context) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ParcelCodeScanScreen(
          expectedTrackingNumber: '',
          title: "Scan the rider's QR",
          prompt: "Point your camera at the QR on the rider's phone.",
          squareFrame: true,
        ),
      ),
    );

/// "Your parcel is at the door — confirm delivery."
///
/// Shown while a StyleMint rider is standing at the buyer's door showing a
/// proof-of-delivery QR (the order's `delivery.awaitingConfirmation`). Two
/// ways to confirm, because cameras fail: scan the rider's QR, or type the
/// package number and the 6-digit code under it.
///
/// Only the order's buyer can confirm; the server enforces that, and the
/// card says so in plain words when it refuses. `already_confirmed` counts
/// as success. On success [onConfirmed] reloads the order, which then shows
/// Delivered and drops this card.
class DeliveryConfirmCard extends ConsumerStatefulWidget {
  const DeliveryConfirmCard({
    required this.order,
    required this.onConfirmed,
    this.scanner = scanRiderDeliveryQr,
    super.key,
  });

  final OrderDetail order;
  final Future<void> Function() onConfirmed;
  final DeliveryQrScanner scanner;

  static const scanKey = ValueKey<String>('delivery-confirm-scan');
  static const showCodeKey = ValueKey<String>('delivery-confirm-show-code');
  static const title = 'Your parcel is at the door — confirm delivery';

  /// While the rider is waiting at the door. Not once the order is closed —
  /// a stale flag must not ask the buyer to confirm a delivered parcel.
  static bool isOfferedFor(OrderDetail order) =>
      order.delivery?.awaitingConfirmation == true &&
      order.status != OrderTrackStatus.delivered &&
      order.status != OrderTrackStatus.cancelled;

  @override
  ConsumerState<DeliveryConfirmCard> createState() =>
      _DeliveryConfirmCardState();
}

class _DeliveryConfirmCardState extends ConsumerState<DeliveryConfirmCard> {
  bool _typing = false;

  String get _key => widget.order.orderNumber;

  Future<void> _scan() async {
    final notifier = ref.read(deliveryConfirmNotifierProvider(_key).notifier);
    final raw = await widget.scanner(context);
    if (raw == null || !mounted) return;
    if (DeliveryConfirmLink.token(raw) == null) {
      SmSnackbar.error(
        context,
        "That isn't the rider's delivery QR. Scan the code on their phone, "
        'or type the 6-digit code instead.',
        seconds: 4,
      );
      return;
    }
    notifier.reset();
    await _finish(await notifier.confirmQr(raw));
  }

  Future<void> _submitCode(String packageNumber, String code) async {
    final notifier = ref.read(deliveryConfirmNotifierProvider(_key).notifier)
      ..reset();
    await _finish(
      await notifier.confirmCode(packageNumber: packageNumber, code: code),
    );
  }

  Future<void> _finish(bool delivered) async {
    if (!delivered || !mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    SmSnackbar.success(context, 'Delivered — thanks for confirming!');
    await widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.order.delivery;
    final state = ref.watch(deliveryConfirmNotifierProvider(_key));
    final busy = state is DeliveryConfirmSubmitting;
    final rider = delivery?.riderName;
    final package = delivery?.packageNumber ?? '';

    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.primaryGreen, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.doorbell_rounded,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(DeliveryConfirmCard.title, style: DesignTokens.h3),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            '${rider ?? 'Your StyleMint rider'} is at your door'
            '${package.isEmpty ? '' : ' with $package'}. '
            "Scan the QR on the rider's phone to confirm you have it.",
            style: DesignTokens.smallRegular,
          ),
          if (state case DeliveryConfirmFailed(:final message)) ...[
            const SizedBox(height: DesignTokens.s12),
            _ErrorNote(message: message),
          ],
          const SizedBox(height: DesignTokens.s12),
          if (state is DeliveryConfirmDone)
            const _DeliveredNote()
          else ...[
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: FilledButton.icon(
                key: DeliveryConfirmCard.scanKey,
                onPressed: busy ? null : _scan,
                icon: busy && !_typing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_scanner_rounded),
                label: Text(
                  busy && !_typing ? 'Confirming…' : "Scan rider's QR",
                ),
              ),
            ),
            if (_typing)
              DeliveryCodeForm(
                // Keyed so the typed code survives the error note appearing
                // above it.
                key: const ValueKey<String>('delivery-confirm-code-form'),
                initialPackageNumber: package,
                busy: busy,
                onSubmit: _submitCode,
              )
            else
              Center(
                child: TextButton(
                  key: DeliveryConfirmCard.showCodeKey,
                  onPressed: busy ? null : () => setState(() => _typing = true),
                  child: const Text('Type the code instead'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The fallback to scanning: the package number (prefilled when known) and
/// the 6-digit code from the rider's screen.
class DeliveryCodeForm extends StatefulWidget {
  const DeliveryCodeForm({
    required this.onSubmit,
    this.initialPackageNumber = '',
    this.busy = false,
    super.key,
  });

  final String initialPackageNumber;
  final bool busy;
  final Future<void> Function(String packageNumber, String code) onSubmit;

  static const packageFieldKey = ValueKey<String>('delivery-code-package');
  static const codeFieldKey = ValueKey<String>('delivery-code-digits');
  static const submitKey = ValueKey<String>('delivery-code-submit');

  @override
  State<DeliveryCodeForm> createState() => _DeliveryCodeFormState();
}

class _DeliveryCodeFormState extends State<DeliveryCodeForm> {
  late final TextEditingController _package = TextEditingController(
    text: widget.initialPackageNumber,
  );
  final TextEditingController _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _package.addListener(_changed);
    _code.addListener(_changed);
  }

  @override
  void dispose() {
    _package.dispose();
    _code.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  bool get _ready =>
      _package.text.trim().isNotEmpty &&
      RegExp(r'^\d{6}$').hasMatch(_code.text.replaceAll(RegExp(r'\s'), ''));

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: DesignTokens.s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: DeliveryCodeForm.packageFieldKey,
          controller: _package,
          enabled: !widget.busy,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.next,
          style: DesignTokens.mediumRegular,
          decoration: const InputDecoration(
            labelText: 'Package number',
            hintText: 'SM-D-00000000',
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        TextField(
          key: DeliveryCodeForm.codeFieldKey,
          controller: _code,
          enabled: !widget.busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: DesignTokens.h3.copyWith(letterSpacing: 6),
          decoration: const InputDecoration(
            labelText: '6-digit code',
            counterText: '',
          ),
          onSubmitted: (_) {
            if (_ready && !widget.busy) {
              unawaited(widget.onSubmit(_package.text, _code.text));
            }
          },
        ),
        const SizedBox(height: DesignTokens.s12),
        SizedBox(
          height: DesignTokens.buttonHeight,
          child: OutlinedButton(
            key: DeliveryCodeForm.submitKey,
            onPressed: _ready && !widget.busy
                ? () => widget.onSubmit(_package.text, _code.text)
                : null,
            child: Text(widget.busy ? 'Confirming…' : 'Confirm delivery'),
          ),
        ),
      ],
    ),
  );
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.colorError.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: DesignTokens.colorError,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(message, style: DesignTokens.smallRegular)),
      ],
    ),
  );
}

class _DeliveredNote extends StatelessWidget {
  const _DeliveredNote();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(Icons.check_circle_rounded, color: DesignTokens.primaryGreen),
      const SizedBox(width: DesignTokens.s8),
      Expanded(
        child: Text('Delivered ✓', style: DesignTokens.mediumSemibold),
      ),
    ],
  );
}
