import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PendingCustomerInquiriesScreen extends StatelessWidget {
  const PendingCustomerInquiriesScreen({super.key});

  static final _inquiries = [
    _Inquiry(
      id: '1',
      question: 'What is the warranty period for this product?',
      orderId: '#3434543',
      orderLabel: 'Order No.',
      customerName: 'Alex Lama',
      timeRemaining: '19:43',
    ),
    _Inquiry(
      id: '2',
      question: 'Do you have a 12gb Ram variant of this product and do you sell it in pink/purple c...',
      orderId: '#3434543',
      orderLabel: 'Product ID',
      customerName: 'Suresh Lama',
      timeRemaining: '00:43',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Pending Customer Inquiries', style: DesignTokens.oneLinerSemibold),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        itemCount: _inquiries.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
        itemBuilder: (context, index) => _InquiryCard(
          inquiry: _inquiries[index],
          onReply: () => _showReplySheet(context, _inquiries[index]),
        ),
      ),
    );
  }

  void _showReplySheet(BuildContext context, _Inquiry inquiry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ReplySheet(inquiry: inquiry),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({required this.inquiry, required this.onReply});

  final _Inquiry inquiry;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inquiry.question,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.s6),
                Text(
                  '${inquiry.orderLabel} : ${inquiry.orderId}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),
                // Customer chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E6FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline, size: 13, color: Color(0xFF0D1B2A)),
                      const SizedBox(width: 4),
                      Text(
                        'Customer: ${inquiry.customerName}',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1B2A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),
                // Response time
                Builder(builder: (context) {
                  final urgent = inquiry.timeRemaining.startsWith('00:');
                  const timeColor = Color(0xFFD4D4D8);
                  return Row(
                    children: [
                      Icon(Icons.access_time, size: 13, color: timeColor),
                      const SizedBox(width: 4),
                      Text(
                        'Response Time Remaining: ${inquiry.timeRemaining}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: timeColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 16),
            onPressed: onReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ReplySheet extends StatefulWidget {
  const _ReplySheet({required this.inquiry});

  final _Inquiry inquiry;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reply to Enquiry', style: DesignTokens.mediumSemibold),
                IconButton(
                  icon: const Icon(Icons.close, color: DesignTokens.textWhite, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            // Question
            Text('Question', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              widget.inquiry.question,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Product ID
            Text('Product ID', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              widget.inquiry.orderId,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Customer Name
            Text('Customer Name', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              widget.inquiry.customerName,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: DesignTokens.s16),
            // Reply text area
            TextField(
              controller: _replyController,
              maxLines: 4,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
              decoration: InputDecoration(
                hintText: 'Write Reply for Enquiry',
                hintStyle: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(DesignTokens.s12),
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            // Reply button
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'Reply to Customer',
                  style: DesignTokens.smallRegular.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Inquiry {
  const _Inquiry({
    required this.id,
    required this.question,
    required this.orderId,
    required this.orderLabel,
    required this.customerName,
    required this.timeRemaining,
  });

  final String id;
  final String question;
  final String orderId;
  final String orderLabel;
  final String customerName;
  final String timeRemaining;
}
