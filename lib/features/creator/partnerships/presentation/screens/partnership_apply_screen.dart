import 'dart:developer' as developer;
import 'dart:ui' show ImageFilter;

import 'package:dio/dio.dart' show DioException, Options;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/entities/product_form.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// Data passed from BrandDetailScreen via router `extra`.
class PartnershipApplyArgs {
  const PartnershipApplyArgs({
    required this.vendorProfileId,
    required this.vendorName,
    this.vendorLogoUrl,
    this.vendorRating,
    this.vendorCategory,
    required this.commissionMin,
    required this.commissionMax,
  });

  final String vendorProfileId;
  final String vendorName;
  final String? vendorLogoUrl;
  final double? vendorRating;
  final String? vendorCategory;
  final double commissionMin;
  final double commissionMax;
}

class PartnershipRequestScreen extends ConsumerStatefulWidget {
  const PartnershipRequestScreen({super.key, required this.args});

  final PartnershipApplyArgs args;

  @override
  ConsumerState<PartnershipRequestScreen> createState() =>
      _PartnershipRequestScreenState();
}

class _PartnershipRequestScreenState
    extends ConsumerState<PartnershipRequestScreen> {
  late RangeValues _range;
  final _messageCtrl = TextEditingController();
  bool _agreed = false;
  bool _submitting = false;

  final Set<String> _selectedNiches = <String>{};
  final Set<String> _selectedAudienceGroups = <String>{};
  final List<TextEditingController> _sampleUrlCtrls = [TextEditingController()];

  /// Niche options are fetched from `/v1/public/categories` via
  /// [productCategoriesProvider]. Audience groups remain hardcoded -- no
  /// backend endpoint exists yet.
  static const _audienceGroups = <String>[
    'Gen Z',
    'Millennials',
    'Gen X',
    'Boomers',
    'Mixed',
  ];

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      widget.args.commissionMin,
      widget.args.commissionMax,
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    for (final c in _sampleUrlCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.args.vendorProfileId.isEmpty) {
      SmSnackbar.error(
        context,
        'Brand profile unavailable. Please try again later.',
      );
      return;
    }
    if (!_agreed) {
      SmSnackbar.error(context, 'Please agree to the Partnership Terms.');
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      SmSnackbar.error(
        context,
        'Please explain why this partnership makes sense.',
      );
      return;
    }

    final urls = _sampleUrlCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      final categories = ref
          .read(productCategoriesProvider)
          .maybeWhen(
            data: (d) => d,
            orElse: () => const <CategoryOption>[],
          );
      final payload = <String, dynamic>{
        'vendorProfileId': widget.args.vendorProfileId,
        'commissionMinPercent': _range.start / 100,
        'commissionMaxPercent': _range.end / 100,
        'message': _messageCtrl.text.trim(),
        if (_selectedNiches.isNotEmpty)
          'nicheIds': _selectedNiches
              .map(
                (name) => categories
                    .firstWhere(
                      (c) => c.name == name,
                      orElse: () => const CategoryOption(id: '', name: ''),
                    )
                    .id,
              )
              .where((id) => id.isNotEmpty)
              .toList(),
        if (_selectedAudienceGroups.isNotEmpty)
          'audienceGroups': _selectedAudienceGroups.toList(),
        if (urls.isNotEmpty) 'sampleReelUrls': urls,
      };
      final idemKey = const Uuid().v4();
      developer.log(
        'POST /v1/creator/partnerships/request',
        name: 'partnership_apply',
      );
      developer.log('payload: $payload', name: 'partnership_apply');
      developer.log('idempotency-key: $idemKey', name: 'partnership_apply');
      final response = await api.post(
        '/v1/creator/partnerships/request',
        data: payload,
        options: Options(
          headers: {
            'requiresToken': true,
            'Idempotency-Key': idemKey,
          },
        ),
      );
      developer.log('response: $response', name: 'partnership_apply');
      if (!mounted) return;
      SmSnackbar.info(context, 'Partnership request sent!');
      context.pop();
    } catch (e, st) {
      developer.log(
        'request failed',
        name: 'partnership_apply',
        error: e,
        stackTrace: st,
      );
      if (e is DioException) {
        developer.log(
          'status: ${e.response?.statusCode}',
          name: 'partnership_apply',
        );
        developer.log(
          'body: ${e.response?.data}',
          name: 'partnership_apply',
        );
      }
      if (!mounted) return;
      SmSnackbar.error(context, 'Could not send request. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final minLabel = args.commissionMin.toStringAsFixed(0);
    final maxLabel = args.commissionMax.toStringAsFixed(0);
    final startLabel = _range.start.toStringAsFixed(0);
    final endLabel = _range.end.toStringAsFixed(0);

    // Niche options = creator's own specializations (category IDs from
    // /v1/accounts/{accountId}/creator-specializations) joined with names
    // from /v1/public/categories.
    final accountId = ref
        .watch(sessionControllerProvider)
        .maybeWhen(
          authenticated: (id) => id,
          orElse: () => '',
        );
    final categoriesAsync = ref.watch(productCategoriesProvider);
    final specializationIdsAsync = ref.watch(
      creatorSpecializationIdsProvider(accountId),
    );
    final allCategories = categoriesAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <CategoryOption>[],
    );
    final specializationIds = specializationIdsAsync.maybeWhen(
      data: (d) => d,
      orElse: () => const <String>[],
    );
    // Fall back to the full category list when the creator hasn't set any
    // specializations yet — otherwise this picker renders with zero options
    // and no way to proceed.
    final nicheOptions = specializationIds.isEmpty
        ? allCategories.map((c) => c.name).toList()
        : allCategories
              .where((c) => specializationIds.contains(c.id))
              .map((c) => c.name)
              .toList();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Send Partnership Request',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s8,
          DesignTokens.s16,
          DesignTokens.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand mini-card
            _BrandCard(args: args),
            const SizedBox(height: DesignTokens.s16),

            // Message textarea
            TextField(
              controller: _messageCtrl,
              minLines: 4,
              maxLines: 6,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Why this partnership makes sense',
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            // Commission range slider
            Text(
              'Commission Range ($startLabel%-$endLabel%)',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DesignTokens.primaryGreen,
                inactiveTrackColor: DesignTokens.borderDefault,
                thumbColor: DesignTokens.primaryGreen,
                overlayColor: DesignTokens.primaryGreen.withOpacity(0.15),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 8,
                ),
              ),
              child: RangeSlider(
                min: args.commissionMin,
                max: args.commissionMax,
                values: _range,
                onChanged: (v) => setState(() => _range = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$minLabel%',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                  Text(
                    '$maxLabel%',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            // Your Niche (fetched from /v1/public/categories)
            _MultiSelectField(
              hintText: 'Your Niche',
              options: nicheOptions,
              selected: _selectedNiches,
              onChanged: (s) => setState(() {
                _selectedNiches
                  ..clear()
                  ..addAll(s);
              }),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Your Audience Group
            _MultiSelectField(
              hintText: 'Your Audience Group',
              options: _audienceGroups,
              selected: _selectedAudienceGroups,
              onChanged: (s) => setState(() {
                _selectedAudienceGroups
                  ..clear()
                  ..addAll(s);
              }),
            ),
            const SizedBox(height: DesignTokens.s24),

            // Sample Content (Optional)
            const Text(
              'Sample Content (Optional)',
              style: DesignTokens.mediumSemibold,
            ),
            const SizedBox(height: DesignTokens.s4),
            const Text(
              'Share 3-5 of your best performing reels that match our brand',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s12),
            for (int i = 0; i < _sampleUrlCtrls.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sampleUrlCtrls[i],
                      keyboardType: TextInputType.url,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: DesignTokens.inputFieldData,
                      ),
                      decoration: DesignTokens.inputDecoration(
                        hintText: 'Post URL',
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  GestureDetector(
                    onTap: i == _sampleUrlCtrls.length - 1
                        ? () => setState(
                            () => _sampleUrlCtrls.add(TextEditingController()),
                          )
                        : () => setState(() {
                            _sampleUrlCtrls.removeAt(i).dispose();
                            if (_sampleUrlCtrls.isEmpty) {
                              _sampleUrlCtrls.add(TextEditingController());
                            }
                          }),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        i == _sampleUrlCtrls.length - 1
                            ? Icons.add_rounded
                            : Icons.close_rounded,
                        color: DesignTokens.textWhite,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Terms checkbox
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        side: const BorderSide(
                          color: DesignTokens.borderDefault,
                          width: 1.5,
                        ),
                        activeColor: DesignTokens.primaryGreen,
                        checkColor: DesignTokens.buttonPrimaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            DesignTokens.inputRadius,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'I agree to the ',
                            style: DesignTokens.smallRegular,
                          ),
                          Text(
                            'Partnership Terms',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              // Submit button
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: SmPrimaryButton(
                  label: 'Submit Request',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.primaryGreen,
                  labelColor: DesignTokens.buttonPrimaryText,
                  disabled: _submitting,
                  isLoadingInitially: _submitting,
                  onPressed: _submit,
                  suffixIcon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: DesignTokens.buttonPrimaryText,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Brand mini-card ──────────────────────────────────────────────────────────

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.args});
  final PartnershipApplyArgs args;

  @override
  Widget build(BuildContext context) {
    final commission = args.commissionMin == args.commissionMax
        ? '${args.commissionMax.toStringAsFixed(0)}% Commission'
        : '${args.commissionMin.toStringAsFixed(0)}-'
              '${args.commissionMax.toStringAsFixed(0)}% Commissions';

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: args.vendorLogoUrl != null
                ? Image.network(
                    args.vendorLogoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.store_rounded,
                      color: DesignTokens.textLight,
                      size: 24,
                    ),
                  )
                : const Icon(
                    Icons.store_rounded,
                    color: DesignTokens.textLight,
                    size: 24,
                  ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                args.vendorName,
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: 2),
              if (args.vendorRating != null || args.vendorCategory != null)
                Row(
                  children: [
                    if (args.vendorRating != null) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: DesignTokens.secondaryYellow,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        args.vendorRating!.toStringAsFixed(1),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      if (args.vendorCategory != null)
                        Text(
                          ' · ',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                    ],
                    if (args.vendorCategory != null)
                      Text(
                        args.vendorCategory!,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: DesignTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.chipsSelectedFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  commission,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Multi-select dropdown field ───────────────────────────────────────────────

class _MultiSelectField extends StatelessWidget {
  const _MultiSelectField({
    required this.hintText,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String hintText;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  String get _display {
    if (selected.isEmpty) return hintText;
    return selected.join(', ');
  }

  Future<void> _open(BuildContext context) async {
    final next = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => _MultiSelectSheet(
        title: hintText,
        options: options,
        initial: Set<String>.from(selected),
      ),
    );
    if (next != null) onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = selected.isNotEmpty;
    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.inputFieldFill,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          border: Border.all(color: DesignTokens.inputFieldBorder, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: hasValue
                      ? DesignTokens.inputFieldData
                      : DesignTokens.inputFieldPlaceholder,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DesignTokens.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initial,
  });

  final String title;
  final List<String> options;
  final Set<String> initial;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late Set<String> _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets + safeBottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBody.withOpacity(0.92),
            ),
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: DesignTokens.sectionInnerTitle,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(
                        Icons.close_rounded,
                        color: DesignTokens.textWhite,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.options
                          .map(
                            (opt) => _OptionRow(
                              label: opt,
                              value: _picked.contains(opt),
                              onChanged: (v) {
                                setState(() {
                                  if (v) {
                                    _picked.add(opt);
                                  } else {
                                    _picked.remove(opt);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                SizedBox(
                  width: double.infinity,
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_picked),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.buttonPrimaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                side: const BorderSide(
                  color: DesignTokens.borderDefault,
                  width: 1.5,
                ),
                activeColor: DesignTokens.primaryGreen,
                checkColor: DesignTokens.buttonPrimaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
