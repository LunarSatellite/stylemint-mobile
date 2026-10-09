import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/widgets/style_mint_qr.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/notifiers/courier_job_notifiers.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Proof of delivery, at the door: a QR the recipient scans in their
/// StyleMint app, with the 6-digit code under it for when their camera will
/// not cooperate.
///
/// Watches for the scan by polling (see [DeliveryProofNotifier]). Confirmed
/// shows a big tick and returns `true` to the job screen, which goes back to
/// the dashboard; expired offers "New code". Pops `null` when the rider backs
/// out — the proof stays live, and "Show QR again" brings it back.
class CourierDeliveryQrScreen extends ConsumerStatefulWidget {
  const CourierDeliveryQrScreen({
    required this.hopId,
    this.initialProof,
    this.closeAfter = const Duration(seconds: 2),
    super.key,
  });

  final String hopId;

  /// What "Complete ride" already returned; read from the server when null.
  final DeliveryProof? initialProof;

  /// How long the success state stays up before returning on its own.
  final Duration closeAfter;

  static const newCodeKey = ValueKey<String>('courier-qr-new-code');
  static const doneKey = ValueKey<String>('courier-qr-done');
  static const confirmedText = 'Delivered';
  static const instructionText =
      'Ask the recipient to scan this in their StyleMint app';

  @override
  ConsumerState<CourierDeliveryQrScreen> createState() =>
      _CourierDeliveryQrScreenState();
}

class _CourierDeliveryQrScreenState
    extends ConsumerState<CourierDeliveryQrScreen> {
  Timer? _ticker;
  Timer? _close;

  ({String hopId, DeliveryProof? initial}) get _args =>
      (hopId: widget.hopId, initial: widget.initialProof);

  @override
  void initState() {
    super.initState();
    // Redraws the countdown, and retires the code the second it dies rather
    // than at the next poll.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(deliveryProofNotifierProvider(_args).notifier).checkExpiry();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _close?.cancel();
    super.dispose();
  }

  void _onConfirmed() {
    _ticker?.cancel();
    unawaited(HapticFeedback.heavyImpact());
    _close?.cancel();
    _close = Timer(widget.closeAfter, _finish);
  }

  void _finish() {
    _close?.cancel();
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = deliveryProofNotifierProvider(_args);
    ref.listen<DeliveryProofState>(provider, (previous, next) {
      if (next is DeliveryProofConfirmed && previous is! DeliveryProofConfirmed) {
        _onConfirmed();
      }
    });
    final state = ref.watch(provider);
    // The success state can also be the first one — the recipient scanned
    // before this screen opened — and ref.listen does not fire for that.
    if (state is DeliveryProofConfirmed && _close == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _close == null) _onConfirmed();
      });
    }
    final now = DateTime.now().toUtc();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Proof of delivery'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s24),
            child: switch (state) {
              DeliveryProofLoading(:final renewing) => _Busy(
                label: renewing ? 'Getting a new code…' : 'Getting your code…',
              ),
              DeliveryProofFailed(:final failure) => _Problem(
                message: NetworkExceptions.getMessage(failure),
                onRetry: () => ref.read(provider.notifier).renew(),
              ),
              DeliveryProofShowing(:final proof) =>
                proof.isExpiredAt(now)
                    ? _Expired(
                        proof: proof,
                        onNewCode: () => ref.read(provider.notifier).renew(),
                      )
                    : _Showing(proof: proof, left: proof.remainingAt(now)),
              DeliveryProofExpired(:final proof) => _Expired(
                proof: proof,
                onNewCode: () => ref.read(provider.notifier).renew(),
              ),
              DeliveryProofConfirmed(:final proof) => _Confirmed(
                proof: proof,
                onDone: _finish,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _Showing extends StatelessWidget {
  const _Showing({required this.proof, required this.left});

  final DeliveryProof proof;
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // As big as the screen allows: a recipient's camera reads a large code
    // from arm's length on the first try.
    final size = (width - 2 * DesignTokens.s24 - 2 * DesignTokens.s12).clamp(
      160.0,
      300.0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          CourierDeliveryQrScreen.instructionText,
          textAlign: TextAlign.center,
          style: DesignTokens.mediumSemibold,
        ),
        const SizedBox(height: DesignTokens.s16),
        if (proof.qrPayload.isNotEmpty)
          StyleMintQr(
            data: proof.qrPayload,
            size: size,
            semanticLabel: 'Delivery confirmation QR code',
          ),
        const SizedBox(height: DesignTokens.s16),
        Text(
          'Or they can type this code',
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s4),
        SelectableText(
          _spaced(proof.code),
          textAlign: TextAlign.center,
          style: DesignTokens.h1.copyWith(
            fontSize: 40,
            letterSpacing: 6,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        if (proof.packageNumber.isNotEmpty)
          Text(
            'Package ${proof.packageNumber}',
            style: DesignTokens.smallRegular,
          ),
        if (proof.expiresUtc != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Expires in ${_clock(left)}',
            style: DesignTokens.smallRegular.copyWith(
              color: left.inMinutes < 5
                  ? DesignTokens.colorWarning
                  : DesignTokens.textMuted,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: DesignTokens.s8),
            Text(
              'Waiting for the scan…',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _Expired extends StatelessWidget {
  const _Expired({required this.proof, required this.onNewCode});

  final DeliveryProof? proof;
  final VoidCallback onNewCode;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.timer_off_rounded, size: 48, color: DesignTokens.colorWarning),
      const SizedBox(height: DesignTokens.s12),
      Text('This code has expired', style: DesignTokens.h3),
      const SizedBox(height: DesignTokens.s8),
      Text(
        'Get a new one and show it to the recipient again.',
        textAlign: TextAlign.center,
        style: DesignTokens.smallRegular,
      ),
      const SizedBox(height: DesignTokens.s16),
      FilledButton.icon(
        key: CourierDeliveryQrScreen.newCodeKey,
        onPressed: onNewCode,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('New code'),
      ),
    ],
  );
}

class _Confirmed extends StatelessWidget {
  const _Confirmed({required this.proof, required this.onDone});

  final DeliveryProof proof;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 112,
        height: 112,
        decoration: const BoxDecoration(
          color: DesignTokens.primaryGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 72, color: Colors.white),
      ),
      const SizedBox(height: DesignTokens.s16),
      Text(
        '${CourierDeliveryQrScreen.confirmedText} ✓',
        style: DesignTokens.h1,
      ),
      const SizedBox(height: DesignTokens.s8),
      Text(
        proof.packageNumber.isEmpty
            ? 'The recipient confirmed. Nice run!'
            : 'The recipient confirmed ${proof.packageNumber}. Nice run!',
        textAlign: TextAlign.center,
        style: DesignTokens.smallRegular,
      ),
      const SizedBox(height: DesignTokens.s20),
      FilledButton(
        key: CourierDeliveryQrScreen.doneKey,
        onPressed: onDone,
        child: const Text('Back to deliveries'),
      ),
    ],
  );
}

class _Busy extends StatelessWidget {
  const _Busy({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const SmBrandLoader(),
      const SizedBox(height: DesignTokens.s12),
      Text(label, style: DesignTokens.smallRegular),
    ],
  );
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(message, textAlign: TextAlign.center, style: DesignTokens.smallRegular),
      const SizedBox(height: DesignTokens.s12),
      FilledButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}

/// "482913" → "482 913": easier to read aloud and to type.
String _spaced(String code) => code.length == 6
    ? '${code.substring(0, 3)} ${code.substring(3)}'
    : code;

/// "29:41".
String _clock(Duration left) {
  final minutes = left.inMinutes;
  final seconds = (left.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
