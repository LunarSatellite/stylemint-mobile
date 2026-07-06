import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/entities/product_inquiry.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PendingCustomerInquiriesScreen extends ConsumerWidget {
  const PendingCustomerInquiriesScreen({super.key});

  // Fallback shown while there are genuinely no real inquiries yet — same
  // pattern used on Ready to Ship / Waiting Tracking / Recent Activity.
  // NOTE: the backend's inquiry list endpoint (GET /v1/product-inquiries/
  // vendor) doesn't return customer name or order/product id, so those
  // fields are omitted here too (not just for the sample) to keep the
  // preview honest about what real data will actually look like.
  static final _sampleInquiries = [
    ProductInquiry(
      id: '_sample-1',
      question: 'What is the warranty period for this product?',
      status: InquiryStatus.open,
      responseDeadlineAt: DateTime.now().toUtc().add(const Duration(hours: 19, minutes: 43)),
    ),
    ProductInquiry(
      id: '_sample-2',
      question: 'Do you have a 12gb Ram variant of this product and do you sell it in pink/purple color?',
      status: InquiryStatus.open,
      responseDeadlineAt: DateTime.now().toUtc().add(const Duration(minutes: 43)),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inquiriesControllerProvider);
    final realOpen = state.items.where((i) => i.status == InquiryStatus.open).toList(growable: false);
    final isSample = !state.isLoading && state.items.isEmpty;
    final inquiries = isSample ? _sampleInquiries : realOpen;

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
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
            )
          : Column(
              children: [
                if (isSample)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF2C2C2E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s8,
                    ),
                    child: Text(
                      'Sample preview — no real inquiries yet. This will switch to live inquiries automatically once you have some.',
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11),
                    ),
                  ),
                Expanded(
                  child: inquiries.isEmpty
                      ? Center(
                          child: Text(
                            'No pending inquiries.',
                            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16,
                            vertical: DesignTokens.s12,
                          ),
                          itemCount: inquiries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s8),
                          itemBuilder: (context, index) => _InquiryCard(
                            inquiry: inquiries[index],
                            actionsEnabled: !isSample,
                            isReplying: state.replyingId == inquiries[index].id,
                            onReply: () => _showReplySheet(context, ref, inquiries[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  void _showReplySheet(BuildContext context, WidgetRef ref, ProductInquiry inquiry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ReplySheet(
        inquiry: inquiry,
        onSubmit: (text) async {
          final ok = await ref.read(inquiriesControllerProvider.notifier).reply(inquiry.id, text);
          if (!context.mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ok ? 'Reply sent.' : 'Failed to send reply.')),
          );
        },
      ),
    );
  }
}

class _InquiryCard extends StatelessWidget {
  const _InquiryCard({
    required this.inquiry,
    required this.onReply,
    required this.isReplying,
    this.actionsEnabled = true,
  });

  final ProductInquiry inquiry;
  final VoidCallback onReply;
  final bool isReplying;
  final bool actionsEnabled;

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
                if (inquiry.responseDeadlineAt != null)
                  Builder(builder: (context) {
                    final remaining = _formatRemaining(inquiry.responseDeadlineAt!);
                    final urgent = remaining.startsWith('00:') || remaining == 'Expired';
                    final timeColor = urgent ? DesignTokens.colorError : const Color(0xFFD4D4D8);
                    return Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: timeColor),
                        const SizedBox(width: 4),
                        Text(
                          'Response Time Remaining: $remaining',
                          style: DesignTokens.smallRegular.copyWith(color: timeColor, fontSize: 11),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          if (actionsEnabled)
            IconButton(
              icon: isReplying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.primaryGreen),
                    )
                  : const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 16),
              onPressed: isReplying ? null : onReply,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  static String _formatRemaining(DateTime deadlineUtc) {
    final remaining = deadlineUtc.difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'Expired';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

class _ReplySheet extends StatefulWidget {
  const _ReplySheet({required this.inquiry, required this.onSubmit});

  final ProductInquiry inquiry;
  final Future<void> Function(String text) onSubmit;

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _replyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    await widget.onSubmit(text);
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
            Text('Question', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              widget.inquiry.question,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
            ),
            const SizedBox(height: DesignTokens.s16),
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
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(
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
