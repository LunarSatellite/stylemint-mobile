import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/delivery_confirm_link.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracking_lookup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/delivery_confirm_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_confirm_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The rider's proof-of-delivery QR opened as a link
/// (`https://<StyleMint host>/dc/{token}`): from the Scan tab, the phone's
/// own camera, or a tapped link.
///
/// Confirms on open — scanning the code *is* the buyer saying "I have it" —
/// then offers the order, which now reads Delivered. On a failure it says
/// why in plain words and offers the 6-digit code as the way through.
class DeliveryConfirmScreen extends ConsumerStatefulWidget {
  const DeliveryConfirmScreen({required this.token, this.qrPayload, super.key});

  /// The opaque token from the link's path.
  final String token;

  /// The exact scanned link, when the caller had it; rebuilt from [token]
  /// on the canonical origin otherwise.
  final String? qrPayload;

  static const viewOrderKey = ValueKey<String>('delivery-confirm-view-order');
  static const retryKey = ValueKey<String>('delivery-confirm-retry');

  @override
  ConsumerState<DeliveryConfirmScreen> createState() =>
      _DeliveryConfirmScreenState();
}

class _DeliveryConfirmScreenState extends ConsumerState<DeliveryConfirmScreen> {
  bool _openingOrder = false;

  String get _key => 'dc:${widget.token}';

  /// Null when the link's token is not a delivery token at all.
  String? get _payload {
    final scanned = widget.qrPayload;
    if (scanned != null && DeliveryConfirmLink.token(scanned) != null) {
      return scanned;
    }
    final token = widget.token.trim();
    final payload = DeliveryConfirmLink.payloadFor(token);
    return DeliveryConfirmLink.token(payload) == null ? null : payload;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirmQr());
  }

  Future<void> _confirmQr() async {
    final payload = _payload;
    if (payload == null || !mounted) return;
    final notifier = ref.read(deliveryConfirmNotifierProvider(_key).notifier)
      ..reset();
    if (await notifier.confirmQr(payload)) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  Future<void> _confirmCode(String packageNumber, String code) async {
    final notifier = ref.read(deliveryConfirmNotifierProvider(_key).notifier)
      ..reset();
    if (await notifier.confirmCode(packageNumber: packageNumber, code: code)) {
      unawaited(HapticFeedback.mediumImpact());
    }
  }

  /// The confirmation names the order by id; the order screen is addressed
  /// by number. The parcel's package number is its tracking number, which
  /// the server resolves to the caller's own order in one call.
  Future<void> _openOrder(String packageNumber) async {
    if (_openingOrder) return;
    setState(() => _openingOrder = true);
    String? orderNumber;
    if (packageNumber.isNotEmpty) {
      try {
        final lookup = await ref.read(
          orderNumberForTrackingProvider(packageNumber).future,
        );
        if (lookup is TrackingLookupResolved) orderNumber = lookup.orderNumber;
      } on Object {
        orderNumber = null;
      }
    }
    if (!mounted) return;
    setState(() => _openingOrder = false);
    final router = GoRouter.of(context);
    if (orderNumber == null) {
      router.go(RouteNames.orders);
    } else {
      router.go('/orders/${Uri.encodeComponent(orderNumber)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryConfirmNotifierProvider(_key));
    final validLink = _payload != null;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.popOrHome(),
        ),
        title: const Text('Confirm delivery'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s24),
            child: switch (state) {
              DeliveryConfirmDone(:final confirmation) => _Delivered(
                packageNumber: confirmation?.packageNumber ?? '',
                opening: _openingOrder,
                onViewOrder: () =>
                    _openOrder(confirmation?.packageNumber ?? ''),
              ),
              DeliveryConfirmSubmitting() => const _Busy(),
              DeliveryConfirmFailed(:final message) => _Problem(
                message: message,
                onRetry: validLink ? _confirmQr : null,
                onSubmitCode: _confirmCode,
              ),
              // Before the first frame's confirm — or a link whose token is
              // not a delivery token at all.
              DeliveryConfirmIdle() =>
                validLink
                    ? const _Busy()
                    : _Problem(
                        message:
                            "This link isn't a working delivery code. Type "
                            "the package number and the 6-digit code from "
                            "the rider's screen instead.",
                        onSubmitCode: _confirmCode,
                      ),
            },
          ),
        ),
      ),
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SmBrandLoader(),
      const SizedBox(height: DesignTokens.s12),
      Text('Confirming your delivery…', style: DesignTokens.smallRegular),
    ],
  );
}

class _Delivered extends StatelessWidget {
  const _Delivered({
    required this.packageNumber,
    required this.opening,
    required this.onViewOrder,
  });

  final String packageNumber;
  final bool opening;
  final VoidCallback onViewOrder;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 104,
        height: 104,
        decoration: const BoxDecoration(
          color: DesignTokens.primaryGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 64, color: Colors.white),
      ),
      const SizedBox(height: DesignTokens.s16),
      Text('Delivered ✓', style: DesignTokens.h1),
      const SizedBox(height: DesignTokens.s8),
      Text(
        packageNumber.isEmpty
            ? 'Thanks for confirming. Enjoy your order!'
            : 'Thanks for confirming $packageNumber. Enjoy your order!',
        textAlign: TextAlign.center,
        style: DesignTokens.smallRegular,
      ),
      const SizedBox(height: DesignTokens.s24),
      SizedBox(
        width: double.infinity,
        height: DesignTokens.buttonHeight,
        child: FilledButton(
          key: DeliveryConfirmScreen.viewOrderKey,
          onPressed: opening ? null : onViewOrder,
          child: Text(opening ? 'Opening…' : 'View order'),
        ),
      ),
    ],
  );
}

class _Problem extends StatelessWidget {
  const _Problem({
    required this.message,
    required this.onSubmitCode,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;
  final Future<void> Function(String packageNumber, String code) onSubmitCode;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(
        Icons.error_outline_rounded,
        size: 48,
        color: DesignTokens.colorWarning,
      ),
      const SizedBox(height: DesignTokens.s12),
      Text(
        "Couldn't confirm the delivery",
        textAlign: TextAlign.center,
        style: DesignTokens.h3,
      ),
      const SizedBox(height: DesignTokens.s8),
      Text(
        message,
        textAlign: TextAlign.center,
        style: DesignTokens.smallRegular,
      ),
      if (onRetry != null) ...[
        const SizedBox(height: DesignTokens.s16),
        FilledButton(
          key: DeliveryConfirmScreen.retryKey,
          onPressed: onRetry,
          child: const Text('Try again'),
        ),
      ],
      const SizedBox(height: DesignTokens.s24),
      Text(
        'Or type the code from the rider’s screen',
        style: DesignTokens.mediumSemibold,
      ),
      DeliveryCodeForm(onSubmit: onSubmitCode),
    ],
  );
}
