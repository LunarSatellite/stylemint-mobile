import 'package:dio/dio.dart' show Options;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
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

  String? _selectedNiche;
  String? _selectedAudienceGroup;
  final List<TextEditingController> _sampleUrlCtrls = [TextEditingController()];

  /// TODO: replace with API-driven lists once `/v1/creator/niches` and
  /// `/v1/creator/audience-groups` (or equivalent) exist. Hardcoded for
  /// now so the UI matches the design.
  static const _niches = <String>[
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Fitness',
    'Tech',
    'Food',
    'Travel',
    'Gaming',
  ];
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
      SmSnackbar.error(context, 'Brand profile unavailable. Please try again later.');
      return;
    }
    if (!_agreed) {
      SmSnackbar.error(context, 'Please agree to the Partnership Terms.');
      return;
    }
    if (_messageCtrl.text.trim().isEmpty) {
      SmSnackbar.error(context, 'Please explain why this partnership makes sense.');
      return;
    }

    final urls = _sampleUrlCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/v1/creator/partnerships/request',
        data: {
          'vendorProfileId': widget.args.vendorProfileId,
          'commissionMinPercent': _range.start,
          'commissionMaxPercent': _range.end,
          'message': _messageCtrl.text.trim(),
          if (_selectedNiche != null) 'niche': _selectedNiche,
          if (_selectedAudienceGroup != null)
            'audienceGroup': _selectedAudienceGroup,
          if (urls.isNotEmpty) 'sampleReelUrls': urls,
        },
        options: Options(headers: {
          'requiresToken': true,
          'Idempotency-Key': const Uuid().v4(),
        }),
      );
      if (!mounted) return;
      SmSnackbar.info(context, 'Partnership request sent!');
      context.pop();
    } catch (_) {
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
        title: const Text('Send Partnership Request',
            style: DesignTokens.sectionInnerTitle),
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
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.textWhite),
            ),
            const SizedBox(height: DesignTokens.s8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DesignTokens.primaryGreen,
                inactiveTrackColor: DesignTokens.borderDefault,
                thumbColor: DesignTokens.primaryGreen,
                overlayColor:
                    DesignTokens.primaryGreen.withOpacity(0.15),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                    enabledThumbRadius: 8),
              ),
              child: RangeSlider(
                min: args.commissionMin,
                max: args.commissionMax,
                values: _range,
                onChanged: (v) => setState(() => _range = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$minLabel%',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight)),
                  Text('$maxLabel%',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight)),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            // Your Niche
            DropdownButtonFormField<String>(
              value: _selectedNiche,
              isExpanded: true,
              dropdownColor: DesignTokens.inputFieldFill,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: DesignTokens.textLight),
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Your Niche',
              ),
              items: _niches
                  .map((n) => DropdownMenuItem<String>(
                        value: n,
                        child: Text(n,
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textWhite)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedNiche = v),
            ),
            const SizedBox(height: DesignTokens.s16),

            // Your Audience Group
            DropdownButtonFormField<String>(
              value: _selectedAudienceGroup,
              isExpanded: true,
              dropdownColor: DesignTokens.inputFieldFill,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: DesignTokens.textLight),
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                color: DesignTokens.inputFieldData,
              ),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Your Audience Group',
              ),
              items: _audienceGroups
                  .map((g) => DropdownMenuItem<String>(
                        value: g,
                        child: Text(g,
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textWhite)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedAudienceGroup = v),
            ),
            const SizedBox(height: DesignTokens.s24),


            // Sample Content (Optional)
            const Text('Sample Content (Optional)',
                style: DesignTokens.mediumSemibold),
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
                        ? () => setState(() =>
                            _sampleUrlCtrls.add(TextEditingController()))
                        : () => setState(() {
                              _sampleUrlCtrls.removeAt(i).dispose();
                              if (_sampleUrlCtrls.isEmpty) {
                                _sampleUrlCtrls
                                    .add(TextEditingController());
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
          padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
              DesignTokens.s8, DesignTokens.s16, DesignTokens.s16),
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
                        onChanged: (v) =>
                            setState(() => _agreed = v ?? false),
                        side: const BorderSide(
                            color: DesignTokens.borderDefault, width: 1.5),
                        activeColor: DesignTokens.primaryGreen,
                        checkColor: DesignTokens.buttonPrimaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.inputRadius),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('I agree to the ',
                              style: DesignTokens.smallRegular),
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
                  suffixIcon: const Icon(Icons.arrow_forward_rounded,
                      color: DesignTokens.buttonPrimaryText, size: 18),
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
                shape: BoxShape.circle, color: Colors.white),
            clipBehavior: Clip.antiAlias,
            child: args.vendorLogoUrl != null
                ? Image.network(args.vendorLogoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_rounded,
                        color: DesignTokens.textLight,
                        size: 24))
                : const Icon(Icons.store_rounded,
                    color: DesignTokens.textLight, size: 24),
          ),
          const SizedBox(width: DesignTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(args.vendorName,
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.textWhite)),
              const SizedBox(height: 2),
              if (args.vendorRating != null || args.vendorCategory != null)
                Row(
                  children: [
                    if (args.vendorRating != null) ...[
                      const Icon(Icons.star_rounded,
                          size: 14,
                          color: DesignTokens.secondaryYellow),
                      const SizedBox(width: 2),
                      Text(
                        args.vendorRating!.toStringAsFixed(1),
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textWhite),
                      ),
                      if (args.vendorCategory != null)
                        Text(' · ',
                            style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textLight)),
                    ],
                    if (args.vendorCategory != null)
                      Text(
                        args.vendorCategory!,
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textLight),
                      ),
                  ],
                ),
              const SizedBox(height: DesignTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.chipsSelectedFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(commission,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.primaryGreen)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
