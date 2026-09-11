import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ScanInviteScreen extends ConsumerStatefulWidget {
  const ScanInviteScreen({super.key});

  @override
  ConsumerState<ScanInviteScreen> createState() => _ScanInviteScreenState();
}

class _ScanInviteScreenState extends ConsumerState<ScanInviteScreen> {
  bool _isScanning = true;

  Future<void> _onScan(String qrCode) async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);

    final either = await ref
        .read(dropPartiesNotifierProvider.notifier)
        .scanQr(qrCode);
    if (!mounted) return;
    either.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid QR code: $qrCode')),
        );
        setState(() => _isScanning = true);
      },
      (party) {
        Navigator.of(context).pop();
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DropPartyDetailScreen(partyId: party.id),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: DesignTokens.textWhite),
        title: const Text(
          'Scan Invite QR',
          style: DesignTokens.sectionInnerTitle,
        ),
        actions: [
          if (!_isScanning)
            TextButton(
              onPressed: () => setState(() => _isScanning = true),
              child: const Text('Scan Again'),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: DesignTokens.primaryGreen, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 120,
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
              ),
              child: TextField(
                key: const Key('drop-party-invite-field'),
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Paste QR code or invite link',
                ),
                style: DesignTokens.oneLinerRegular,
                onSubmitted: _onScan,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: DesignTokens.s16),
              ElevatedButton(
                onPressed: () {
                  unawaited(_onScan('test-code'));
                },
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Simulate Scan (Dev)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
