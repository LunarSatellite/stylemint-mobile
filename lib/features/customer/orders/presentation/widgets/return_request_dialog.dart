import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_reason_category.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_reason_category_picker.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Picks one photo and returns its local path, or null when the buyer backed
/// out. Overridable so widget tests need no gallery.
typedef ReturnPhotoPicker = Future<String?> Function();

Future<String?> pickReturnPhotoFromGallery() async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1920,
    imageQuality: 80,
  );
  return picked?.path;
}

/// Opens the return request dialog (optionally preselecting [initialItem])
/// and submits the collected return through the order detail notifier.
void startReturnRequest(
  BuildContext context, {
  required OrderDetail order,
  required OrderDetailNotifier notifier,
  OrderDetailItem? initialItem,
}) {
  unawaited(
    showDialog<ReturnRequestResult>(
      context: context,
      builder: (ctx) => ReturnRequestDialog(
        orderNumber: order.orderNumber,
        items: order.items,
        notifier: notifier,
        initialItem: initialItem,
      ),
    ).then((result) {
      if (result != null) {
        unawaited(
          notifier.requestReturn(
            subOrderId: result.item.subOrderId,
            subOrderLineId: result.item.id,
            quantity: result.quantity,
            reason: result.reason,
            photoUrls: result.photoUrls,
            resolution: result.resolution,
            replacementVariantId: result.replacementVariantId,
            reasonCategory: result.category,
          ),
        );
      }
    }),
  );
}

/// What [ReturnRequestDialog] hands back to the caller on Submit.
class ReturnRequestResult {
  const ReturnRequestResult({
    required this.item,
    required this.quantity,
    required this.reason,
    required this.photoUrls,
    required this.resolution,
    required this.category,
    this.replacementVariantId,
  });

  final OrderDetailItem item;
  final int quantity;
  final String reason;
  final List<String> photoUrls;
  final ReturnResolutionChoice resolution;
  final ReturnReasonCategory category;
  final String? replacementVariantId;
}

/// Collects everything the backend's `SubmitReturnVm` requires: which line
/// item, how many units, what is wrong (the category decides who pays the
/// rider), and at least one photo (skill §13.7).
class ReturnRequestDialog extends StatefulWidget {
  const ReturnRequestDialog({
    required this.orderNumber,
    required this.items,
    required this.notifier,
    this.initialItem,
    this.pickPhoto = pickReturnPhotoFromGallery,
    super.key,
  });

  final String orderNumber;
  final List<OrderDetailItem> items;
  final OrderDetailNotifier notifier;

  /// Preselected line (e.g. from the Care & returns card); first item if null.
  final OrderDetailItem? initialItem;
  final ReturnPhotoPicker pickPhoto;

  static const submitKey = ValueKey<String>('return-request-submit');
  static const addPhotoKey = ValueKey<String>('return-request-add-photo');
  static const categoryMissingText = "Choose what's wrong with the item.";

  @override
  State<ReturnRequestDialog> createState() => _ReturnRequestDialogState();
}

class _ReturnRequestDialogState extends State<ReturnRequestDialog> {
  final _controller = TextEditingController();
  late OrderDetailItem _selectedItem;
  int _quantity = 1;
  final List<String> _photoUrls = [];
  bool _uploading = false;
  String? _error;
  ReturnResolutionChoice _resolution = ReturnResolutionChoice.refund;
  List<ReplacementOption> _replacementOptions = const [];
  ReplacementOption? _selectedReplacement;
  bool _loadingReplacements = false;

  ReturnReasonCategory? _category;
  ReturnPickupQuoteView _quote = const ReturnPickupQuoteView.none();

  /// Bumped per quote request, so a slow answer for an earlier line or
  /// quantity never lands over the current one.
  int _quoteGeneration = 0;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialItem ?? widget.items.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final path = await widget.pickPhoto();
    if (path == null || !mounted) return;
    setState(() {
      _uploading = true;
      _error = null;
    });
    final either = await widget.notifier.uploadReturnPhoto(path);
    if (!mounted) return;
    either.fold(
      (failure) => setState(() {
        _uploading = false;
        _error = 'Photo upload failed. Try again.';
      }),
      (url) => setState(() {
        _uploading = false;
        _photoUrls.add(url);
      }),
    );
  }

  Future<void> _setResolution(ReturnResolutionChoice choice) async {
    setState(() {
      _resolution = choice;
      _error = null;
      _selectedReplacement = null;
      _replacementOptions = const [];
      _loadingReplacements = choice == ReturnResolutionChoice.replacement;
    });
    if (choice == ReturnResolutionChoice.refund) return;

    final result = await widget.notifier.getReplacementOptions(
      _selectedItem.productId,
    );
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _loadingReplacements = false;
        _error = 'Could not load replacement options. Try again.';
      }),
      (options) {
        final eligible = options
            .where(
              (option) =>
                  option.price.currency == _selectedItem.unitPrice.currency,
            )
            .toList(growable: false);
        setState(() {
          _loadingReplacements = false;
          _replacementOptions = eligible;
          _selectedReplacement = eligible.isEmpty ? null : eligible.first;
          if (eligible.isEmpty) {
            _error = 'No replacement variant is currently in stock.';
          }
        });
      },
    );
  }

  void _setCategory(ReturnReasonCategory category) {
    setState(() {
      _category = category;
      if (_error == ReturnRequestDialog.categoryMissingText) _error = null;
    });
    unawaited(_refreshQuote());
  }

  /// The fare only matters when the buyer pays it, so it is only asked for
  /// then — and again when the line or the quantity changes.
  Future<void> _refreshQuote() async {
    final generation = ++_quoteGeneration;
    if (_category?.buyerPaysPickup != true) {
      setState(() => _quote = const ReturnPickupQuoteView.none());
      return;
    }
    setState(() => _quote = const ReturnPickupQuoteView.loading());
    final result = await widget.notifier.getReturnPickupQuote(
      widget.orderNumber,
      subOrderId: _selectedItem.subOrderId,
      subOrderLineId: _selectedItem.id,
      quantity: _quantity,
    );
    if (!mounted || generation != _quoteGeneration) return;
    setState(() {
      _quote = result.fold(
        (_) => const ReturnPickupQuoteView.unavailable(),
        ReturnPickupQuoteView.ready,
      );
    });
  }

  void _submit() {
    final category = _category;
    if (category == null) {
      setState(() => _error = ReturnRequestDialog.categoryMissingText);
      return;
    }
    if (_photoUrls.isEmpty) {
      setState(() => _error = 'Please add at least one photo.');
      return;
    }
    if (_resolution == ReturnResolutionChoice.replacement &&
        _selectedReplacement == null) {
      setState(() => _error = 'Choose an available replacement variant.');
      return;
    }
    final note = _controller.text.trim();
    Navigator.pop(
      context,
      ReturnRequestResult(
        item: _selectedItem,
        quantity: _quantity,
        // The category is enough for the server (contract §4); the label
        // keeps an older backend that still wants a reason happy.
        reason: note.isEmpty ? category.label : note,
        photoUrls: _photoUrls,
        resolution: _resolution,
        category: category,
        replacementVariantId: _selectedReplacement?.variantId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: Text('Request Return', style: DesignTokens.sectionInnerTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.items.length > 1) ...[
              Text('Item', style: DesignTokens.smallDescription),
              const SizedBox(height: DesignTokens.s8),
              DropdownButton<OrderDetailItem>(
                isExpanded: true,
                value: _selectedItem,
                dropdownColor: DesignTokens.bgAppBody,
                items: widget.items
                    .map(
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(
                          i.productName,
                          style: DesignTokens.bodyText,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (item) {
                  setState(() {
                    _selectedItem = item ?? _selectedItem;
                    _quantity = 1;
                  });
                  unawaited(_refreshQuote());
                },
              ),
              const SizedBox(height: DesignTokens.s12),
            ],
            Text("What's wrong?", style: DesignTokens.smallDescription),
            const SizedBox(height: DesignTokens.s8),
            ReturnReasonCategoryPicker(
              selected: _category,
              onSelected: _setCategory,
            ),
            if (_category != null) ...[
              const SizedBox(height: DesignTokens.s8),
              ReturnPickupFeeNote(category: _category!, quote: _quote),
            ],
            const SizedBox(height: DesignTokens.s12),
            Text(
              'How should we resolve it?',
              style: DesignTokens.smallDescription,
            ),
            const SizedBox(height: DesignTokens.s8),
            SegmentedButton<ReturnResolutionChoice>(
              segments: const [
                ButtonSegment(
                  value: ReturnResolutionChoice.refund,
                  icon: Icon(Icons.currency_rupee_rounded),
                  label: Text('Refund'),
                ),
                ButtonSegment(
                  value: ReturnResolutionChoice.replacement,
                  icon: Icon(Icons.swap_horiz_rounded),
                  label: Text('Replace'),
                ),
              ],
              selected: {_resolution},
              onSelectionChanged: (values) => _setResolution(values.first),
            ),
            if (_loadingReplacements) ...[
              const SizedBox(height: DesignTokens.s12),
              const LinearProgressIndicator(),
            ] else if (_resolution == ReturnResolutionChoice.replacement &&
                _replacementOptions.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s12),
              DropdownButtonFormField<ReplacementOption>(
                initialValue: _selectedReplacement,
                decoration: DesignTokens.inputDecoration(
                  hintText: 'Replacement variant',
                ),
                dropdownColor: DesignTokens.bgAppBody,
                items: _replacementOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(
                          '${option.label} · ${formatMoney(option.price)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (option) =>
                    setState(() => _selectedReplacement = option),
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Stock is held for 24 hours. Cheaper options refund the difference; higher-priced options collect only the balance.',
                style: DesignTokens.smallDescription,
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                Text('Quantity', style: DesignTokens.smallDescription),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: DesignTokens.iconLight,
                  onPressed: _quantity > 1
                      ? () {
                          setState(() => _quantity--);
                          unawaited(_refreshQuote());
                        }
                      : null,
                ),
                Text('$_quantity', style: DesignTokens.mediumSemibold),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: DesignTokens.iconLight,
                  onPressed: _quantity < _selectedItem.qty
                      ? () {
                          setState(() => _quantity++);
                          unawaited(_refreshQuote());
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: DesignTokens.bodyText,
              decoration: DesignTokens.inputDecoration(
                hintText: 'Tell the seller more (optional)',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            if (_photoUrls.isNotEmpty)
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                    child: SizedBox(
                      width: DesignTokens.thumbCompact,
                      height: DesignTokens.thumbCompact,
                      child: MallNetworkImage(url: _photoUrls[i]),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: DesignTokens.s8),
            OutlinedButton.icon(
              key: ReturnRequestDialog.addPhotoKey,
              onPressed: _uploading ? null : _pickAndUploadPhoto,
              style: DesignTokens.outlinedButtonStyle(),
              icon: _uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                _photoUrls.isEmpty ? 'Add Photo' : 'Add Another Photo',
                style: DesignTokens.mediumSemibold,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                _error!,
                style: DesignTokens.smallRegular.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        TextButton(
          key: ReturnRequestDialog.submitKey,
          onPressed: _uploading ? null : _submit,
          child: Text(
            'Submit',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}
