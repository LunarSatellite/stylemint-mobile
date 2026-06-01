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

  void _onScan(String qrCode) {
    if (!_isScanning) return;
    setState(() => _isScanning = false);

    ref.read(dropPartiesNotifierProvider.notifier).scanQr(qrCode).then(
      (either) {
        either.fold(
          (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid QR code: $qrCode')),
              );
              setState(() => _isScanning = true);
            }
          },
          (party) {
            if (mounted) {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DropPartyDetailScreen(partyId: party.id),
                ),
              );
            }
          },
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
        title: const Text('Scan Invite QR',
            style: DesignTokens.sectionInnerTitle),
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
                child: Icon(Icons.qr_code_scanner,
                    size: 120, color: DesignTokens.primaryGreen),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            TextField(
              decoration: DesignTokens.inputDecoration(
                hintText: 'Paste QR code or invite link',
              ),
              style: DesignTokens.oneLinerRegular,
              onSubmitted: _onScan,
            ),
            const SizedBox(height: DesignTokens.s16),
            ElevatedButton(
              onPressed: () {
                _onScan('test-code');
              },
              style: DesignTokens.primaryButtonStyle(),
              child: const Text('Simulate Scan (Dev)'),
            ),
          ],
        ),
      ),
    );
  }
}
