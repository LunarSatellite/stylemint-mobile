import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class SendTipScreen extends StatelessWidget {
  const SendTipScreen({super.key, this.creatorId});

  final String? creatorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Send Tip', style: DesignTokens.sectionInnerTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 64,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(height: DesignTokens.s20),
              const Text(
                'Tip payments are coming soon',
                textAlign: TextAlign.center,
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s12),
              const Text(
                'StyleMint is finishing the secure payment handoff for creator tips. No charge has been made.',
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular,
              ),
              const SizedBox(height: DesignTokens.s24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to tips'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
