import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class SendTipScreen extends ConsumerStatefulWidget {
  const SendTipScreen({super.key, this.creatorId});

  final String? creatorId;

  @override
  ConsumerState<SendTipScreen> createState() => _SendTipScreenState();
}

class _SendTipScreenState extends ConsumerState<SendTipScreen> {
  final _creatorController = TextEditingController();
  final _messageController = TextEditingController();
  double _selectedAmount = 50;

  static const _quickAmounts = [50.0, 100.0, 200.0, 500.0];

  @override
  void dispose() {
    _creatorController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Send Tip', style: DesignTokens.sectionInnerTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Creator', style: DesignTokens.oneLinerSemibold),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _creatorController,
              decoration: DesignTokens.inputDecoration(
                hintText: 'Search or enter creator name',
              ),
              style: DesignTokens.oneLinerRegular,
            ),
            const SizedBox(height: DesignTokens.s24),
            const Text('Amount', style: DesignTokens.oneLinerSemibold),
            const SizedBox(height: DesignTokens.s12),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: _quickAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text('Rs ${amount.toInt()}'),
                  selected: isSelected,
                  selectedColor: DesignTokens.primaryGreen,
                  backgroundColor: DesignTokens.bgAppBodyLight,
                  labelStyle: DesignTokens.mediumSemibold.copyWith(
                    color: isSelected
                        ? DesignTokens.buttonPrimaryText
                        : DesignTokens.textWhite,
                  ),
                  onSelected: (_) => setState(() => _selectedAmount = amount),
                );
              }).toList(),
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: DesignTokens.inputDecoration(
                      hintText: 'Custom amount (NPR)',
                    ),
                    style: DesignTokens.oneLinerRegular,
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null) {
                        setState(() => _selectedAmount = parsed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s24),
            const Text('Message (optional)',
                style: DesignTokens.oneLinerSemibold),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: DesignTokens.inputDecoration(
                hintText: 'Write a message...',
              ),
              style: DesignTokens.oneLinerRegular,
            ),
            const SizedBox(height: DesignTokens.s32),
            Container(
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: DesignTokens.cardDecoration(),
              child: Column(
                children: [
                  const Text('You are sending',
                      style: DesignTokens.smallRegular),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    'Rs ${_selectedAmount.toStringAsFixed(0)}',
                    style: DesignTokens.titleLarge.copyWith(
                        color: DesignTokens.primaryGreen),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            SizedBox(
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  final creator = _creatorController.text.trim();
                  if (creator.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a creator')),
                    );
                    return;
                  }
                  ref
                      .read(tipsNotifierProvider.notifier)
                      .sendTip(
                        creatorId: creator,
                        amount: Money(
                            amount: _selectedAmount, currency: 'NPR'),
                        message: _messageController.text.trim(),
                      );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: DesignTokens.buttonPrimaryText,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius)),
                ),
                child: Text(
                  'Send Tip - Rs ${_selectedAmount.toStringAsFixed(0)}',
                  style: DesignTokens.oneLinerSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
