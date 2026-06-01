import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/data/models/product_inquiry_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/presentation/notifiers/inquiries_controller.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Pending Customer Inquiries + Reply (vendor).
/// Pixel-matched to Brand 'Pending Customer Inquiries - Reply to Enquiry.pdf'.
/// Backend: GET `/v1/product-inquiries/vendor`, POST `/{id}/reply`.
class VendorInquiriesScreen extends ConsumerWidget {
  const VendorInquiriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inquiriesControllerProvider);

    ref.listen<InquiriesState>(inquiriesControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Customer Inquiries',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen))
          : RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: () => ref.read(inquiriesControllerProvider.notifier).load(),
              child: state.items.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Center(
                          child: Text('No pending inquiries.',
                              style: DesignTokens.bodyText)),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(DesignTokens.s16),
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: DesignTokens.s12),
                      itemBuilder: (_, i) => _InquiryCard(
                        inquiry: state.items[i],
                        replying: state.replyingId == state.items[i].id,
                        onReply: (text) => ref
                            .read(inquiriesControllerProvider.notifier)
                            .reply(state.items[i].id, text),
                      ),
                    ),
            ),
    );
  }
}

class _InquiryCard extends StatefulWidget {
  const _InquiryCard({
    required this.inquiry,
    required this.replying,
    required this.onReply,
  });

  final ProductInquiryDto inquiry;
  final bool replying;
  final Future<bool> Function(String) onReply;

  @override
  State<_InquiryCard> createState() => _InquiryCardState();
}

class _InquiryCardState extends State<_InquiryCard> {
  final _replyCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inq = widget.inquiry;
    final answered = inq.state == ProductInquiryState.replied;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StateBadge(state: inq.state),
              const Spacer(),
              if (inq.responseDeadlineUtc != null && !answered)
                Text('Reply by ${_date(inq.responseDeadlineUtc!)}',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted)),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(inq.question, style: DesignTokens.bodyText),
          if (answered && inq.reply != null) ...[
            const SizedBox(height: DesignTokens.s12),
            Container(
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppFoundation,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply, size: 16, color: DesignTokens.primaryGreen),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(child: Text(inq.reply!, style: DesignTokens.smallRegular)),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: DesignTokens.s12),
            if (!_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Text('Reply',
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.primaryGreen)),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _replyCtrl,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1000,
                    style: DesignTokens.bodyText,
                    cursorColor: DesignTokens.primaryGreen,
                    decoration: InputDecoration(
                      hintText: 'Type your reply…',
                      hintStyle: DesignTokens.bodyText
                          .copyWith(color: DesignTokens.textMuted),
                      filled: true,
                      fillColor: DesignTokens.inputFieldFill,
                      counterText: '',
                      contentPadding: const EdgeInsets.all(DesignTokens.s12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.inputRadius),
                        borderSide: const BorderSide(
                            color: DesignTokens.inputFieldBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  widget.replying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DesignTokens.primaryGreen),
                        )
                      : TextButton(
                          onPressed: () async {
                            final ok = await widget.onReply(_replyCtrl.text);
                            if (ok && mounted) {
                              setState(() => _expanded = false);
                            }
                          },
                          child: Text('Send reply',
                              style: DesignTokens.mediumSemibold
                                  .copyWith(color: DesignTokens.primaryGreen)),
                        ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day}/${d.month}';
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final ProductInquiryState state;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      ProductInquiryState.open => (DesignTokens.statusOngoingBg, DesignTokens.colorInfo),
      ProductInquiryState.replied => (
          DesignTokens.statusCompletedBg,
          DesignTokens.colorSuccess
        ),
      ProductInquiryState.expired => (
          DesignTokens.statusRemainingBg,
          DesignTokens.textMuted
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(state.label, style: DesignTokens.tiny.copyWith(color: fg)),
    );
  }
}
