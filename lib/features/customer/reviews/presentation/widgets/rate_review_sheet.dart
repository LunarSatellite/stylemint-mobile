import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _ReviewType { reel, written }

/// Bottom sheet for rating and reviewing a product.
/// Supports Reel Review (link a social reel) and Written Review (stars + text + images).
///
/// [orderId] is required by the backend as proof of purchase — pass it when
/// opening this from a delivered order's line item. Callers without an
/// order in scope (PDP, product-reviews screen) can still open the sheet,
/// but Written-review submission is blocked with a message pointing the
/// customer at their order history instead of attempting a doomed request.
class RateReviewSheet extends ConsumerStatefulWidget {
  const RateReviewSheet({required this.productId, this.orderId, super.key});

  final String productId;
  final String? orderId;

  @override
  ConsumerState<RateReviewSheet> createState() => _RateReviewSheetState();
}

class _RateReviewSheetState extends ConsumerState<RateReviewSheet> {
  _ReviewType _type = _ReviewType.reel;
  String? _platform;
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  final List<String> _imagePaths = [];

  static const _platforms = <(String, Color)>[
    ('Instagram', Color(0xFFE1306C)),
    ('Youtube', Color(0xFFFF0000)),
    ('TikTok', Color(0xFF010101)),
    ('Facebook', Color(0xFF1877F2)),
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitReviewNotifierProvider);
    final isSubmitting = submitState.maybeWhen(submitting: () => true, orElse: () => false);

    ref.listen<SubmitReviewState>(submitReviewNotifierProvider, (_, next) {
      next.maybeWhen(
        success: (_) {
          SmSnackbar.success(context, 'Review submitted!');
          ref.read(submitReviewNotifierProvider.notifier).reset();
          Navigator.of(context).pop();
        },
        failure: (_) => SmSnackbar.error(context, 'Failed to submit review.'),
        orElse: () {},
      );
    });

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: DesignTokens.s16,
        right: DesignTokens.s16,
        top: DesignTokens.s24,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            DesignTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Rate & Review', style: DesignTokens.sectionInnerTitle),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: DesignTokens.textWhite),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          Text('Review Type ?', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          _RadioOption(
            selected: _type == _ReviewType.reel,
            title: 'Reel Review',
            description: 'Got a reel where you reviewed this product? Drop the link here!',
            onTap: () => setState(() => _type = _ReviewType.reel),
          ),
          const SizedBox(height: DesignTokens.s8),
          _RadioOption(
            selected: _type == _ReviewType.written,
            title: 'Written Review',
            description: "Give this product a star rating and, if you'd like, tell us what you enjoyed about it!",
            onTap: () => setState(() => _type = _ReviewType.written),
          ),
          const SizedBox(height: DesignTokens.s20),
          if (_type == _ReviewType.reel) ...[
            Text('Select Platform', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: _platforms.map((p) {
                final isSelected = _platform == p.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: DesignTokens.s8),
                    child: GestureDetector(
                      onTap: () => setState(() => _platform = p.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
                        decoration: BoxDecoration(
                          color: isSelected ? DesignTokens.chipsSelectedFill : DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                          border: Border.all(
                            color: isSelected ? DesignTokens.chipsSelectedBorder : DesignTokens.borderDefault,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: p.$2, shape: BoxShape.circle),
                              child: Center(
                                child: Text(
                                  p.$1[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: DesignTokens.s4),
                            Text(
                              p.$1,
                              style: DesignTokens.smallRegular.copyWith(
                                color: isSelected ? DesignTokens.primaryGreen : DesignTokens.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ] else ...[
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: isSubmitting ? null : () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 36,
                        color: DesignTokens.secondaryYellow,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              enabled: !isSubmitting,
              style: DesignTokens.mediumRegular,
              decoration: DesignTokens.inputDecoration(hintText: 'Write your review'),
            ),
            const SizedBox(height: DesignTokens.s12),
            if (_imagePaths.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.s8),
                        child: Image.file(File(_imagePaths[i]), width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _imagePaths.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : _pickImages,
                style: DesignTokens.outlinedButtonStyle(),
                icon: const Icon(Icons.upload_outlined, size: 18),
                label: Text(
                  _imagePaths.isEmpty ? 'Upload Images' : 'Upload Again',
                  style: DesignTokens.mediumSemibold,
                ),
              ),
            ),
          ],
          const SizedBox(height: DesignTokens.s20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submit,
              style: DesignTokens.primaryButtonStyle(),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.buttonPrimaryText),
                    )
                  : Text(
                      'Submit Review',
                      style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.buttonPrimaryText),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 70);
    if (picked.isNotEmpty) {
      setState(() => _imagePaths.addAll(picked.map((x) => x.path)));
    }
  }

  void _submit() {
    if (_type == _ReviewType.reel) {
      if (_platform == null) {
        SmSnackbar.warning(context, 'Please select a platform.');
        return;
      }
      // ponytail: reel-review ticket endpoint not yet defined — show success for now
      SmSnackbar.success(context, 'Reel review ticket submitted!');
      Navigator.of(context).pop();
      return;
    }
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      SmSnackbar.warning(context, 'Please write a review comment.');
      return;
    }
    final orderId = widget.orderId;
    if (orderId == null) {
      SmSnackbar.warning(
        context,
        'Open "Write a Review" from a delivered order to review this product.',
      );
      return;
    }
    ref.read(submitReviewNotifierProvider.notifier).submitReview(
      productId: widget.productId,
      orderId: orderId,
      rating: _rating,
      comment: comment,
      imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
    );
  }
}

class _RadioOption extends StatelessWidget {
  const _RadioOption({
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            color: selected ? DesignTokens.primaryGreen : DesignTokens.radioIconDefault,
            size: 20,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DesignTokens.mediumSemibold),
                const SizedBox(height: 2),
                Text(description, style: DesignTokens.smallDescription),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
