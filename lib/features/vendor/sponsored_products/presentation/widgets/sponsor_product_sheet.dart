import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/entities/sponsored_listing.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/domain/sponsored_products_errors.dart';
import 'package:stylemint_mobile_frontend/features/vendor/sponsored_products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Saves a sponsorship: the notifier's `sponsor` on the Sponsored products
/// screen, or the repository's straight from a product's actions.
typedef SponsorProductSubmit =
    Future<Either<NetworkExceptions, SponsoredListing>> Function({
      required String productId,
      required int dailyImpressionCap,
      DateTime? endsUtc,
    });

/// How the sponsor form closed.
sealed class SponsorFormResult {
  const SponsorFormResult();
}

final class SponsorFormSaved extends SponsorFormResult {
  const SponsorFormSaved(this.listing);

  final SponsoredListing listing;
}

/// Someone else started sponsoring the product first (HTTP 409). The form
/// closes so the vendor sees the list as it is now.
final class SponsorFormConflict extends SponsorFormResult {
  const SponsorFormConflict(this.message);

  final String message;
}

const dailyImpressionCapRangeMessage =
    'Choose between 10 and 10,000 sponsored views a day.';
const dailyImpressionCapRequiredMessage = 'Enter the most views a day.';
const chooseProductToSponsorMessage = 'Choose a product to sponsor.';
const sponsorEndDateInPastMessage = 'The end date must be in the future.';

/// Client-side check for "Most views a day", matching the backend's 10 to
/// 10,000 rule.
String? validateDailyImpressionCap(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return dailyImpressionCapRequiredMessage;
  final value = int.tryParse(text);
  if (value == null ||
      value < minDailyImpressionCap ||
      value > maxDailyImpressionCap) {
    return dailyImpressionCapRangeMessage;
  }
  return null;
}

/// "20 Sep 2026".
String formatSponsorshipDay(DateTime day) => DateFormat('d MMM y').format(day);

/// The snackbar line after the form closes.
String sponsorFormResultMessage(SponsorFormResult result) => switch (result) {
  SponsorFormSaved(:final listing) =>
    listing.productName.isEmpty
        ? 'Saved. Your product is sponsored.'
        : 'Saved. ${listing.productName} is sponsored.',
  SponsorFormConflict(:final message) => message,
};

/// Opens the sponsor form. With [existing] it changes or restarts that
/// sponsorship, prefilled; with [product] it sponsors that product; with
/// neither the vendor picks one of their live products.
Future<SponsorFormResult?> showSponsorProductSheet(
  BuildContext context, {
  required SponsorProductSubmit onSubmit,
  SponsorProductTarget? product,
  SponsoredListing? existing,
}) {
  return showModalBottomSheet<SponsorFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DesignTokens.bgAppBodyLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => SponsorProductSheet(
      onSubmit: onSubmit,
      product: product,
      existing: existing,
    ),
  );
}

class SponsorProductSheet extends ConsumerStatefulWidget {
  const SponsorProductSheet({
    required this.onSubmit,
    this.product,
    this.existing,
    super.key,
  });

  final SponsorProductSubmit onSubmit;
  final SponsorProductTarget? product;
  final SponsoredListing? existing;

  @override
  ConsumerState<SponsorProductSheet> createState() =>
      _SponsorProductSheetState();
}

class _SponsorProductSheetState extends ConsumerState<SponsorProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cap;

  /// Picked in the product picker when the form isn't for a set product.
  SponsorProductTarget? _picked;

  /// The last full day it runs, in the vendor's time zone; null runs it
  /// until paused.
  DateTime? _lastDay;
  SponsorFormErrors _errors = const SponsorFormErrors();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _cap = TextEditingController(
      text: existing == null ? '' : '${existing.dailyImpressionCap}',
    );
    final ends = existing?.endsUtc;
    // An end date that has already passed can't be saved again, so an ended
    // sponsorship restarts with no end date until the vendor picks one.
    if (ends != null && ends.isAfter(DateTime.now())) {
      _lastDay = sponsorshipLastDay(ends);
    }
  }

  @override
  void dispose() {
    _cap.dispose();
    super.dispose();
  }

  SponsorProductTarget? get _fixedProduct {
    final existing = widget.existing;
    if (existing != null) {
      return SponsorProductTarget(
        productId: existing.productId,
        productName: existing.productName,
      );
    }
    return widget.product;
  }

  String get _title {
    final existing = widget.existing;
    if (existing == null) return 'Sponsor a product';
    return existing.status == SponsorshipStatus.live
        ? 'Change sponsorship'
        : 'Restart sponsorship';
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _lastDay;
    var lastDate = DateTime(today.year + 1, today.month, today.day);
    if (current != null && current.isAfter(lastDate)) lastDate = current;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(today.year, today.month, today.day + 6),
      firstDate: today,
      lastDate: lastDate,
      helpText: 'Last day it runs',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _lastDay = DateTime(picked.year, picked.month, picked.day);
      _errors = _errors.withoutEndsUtc();
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _errors = const SponsorFormErrors());
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final target = _fixedProduct ?? _picked;
    if (target == null) {
      setState(
        () => _errors = const SponsorFormErrors(
          general: chooseProductToSponsorMessage,
        ),
      );
      return;
    }

    final lastDay = _lastDay;
    final endsUtc = lastDay == null
        ? null
        : sponsorshipEndsAfter(lastDay).toUtc();
    if (endsUtc != null && !endsUtc.isAfter(DateTime.now().toUtc())) {
      setState(
        () => _errors = const SponsorFormErrors(
          endsUtc: sponsorEndDateInPastMessage,
        ),
      );
      return;
    }

    final result = await widget.onSubmit(
      productId: target.productId,
      dailyImpressionCap: int.parse(_cap.text.trim()),
      endsUtc: endsUtc,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        if (isSponsorshipConflict(failure)) {
          Navigator.of(context).pop(
            SponsorFormConflict(sponsoredProductsErrorMessage(failure)),
          );
          return;
        }
        setState(() => _errors = SponsorFormErrors.from(failure));
      },
      (listing) => Navigator.of(context).pop(SponsorFormSaved(listing)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixed = _fixedProduct;
    final general = _errors.general;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DesignTokens.borderDefault,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                Text(
                  _title,
                  style: DesignTokens.titleLarge.copyWith(fontSize: 20),
                ),
                const SizedBox(height: DesignTokens.s16),
                if (fixed != null)
                  _FixedProduct(product: fixed)
                else
                  _ProductPicker(
                    selected: _picked,
                    onChanged: (product) => setState(() {
                      _picked = product;
                      _errors = const SponsorFormErrors();
                    }),
                  ),
                const SizedBox(height: DesignTokens.s16),
                TextFormField(
                  key: const ValueKey('sponsor-daily-cap'),
                  controller: _cap,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                  decoration:
                      DesignTokens.inputDecoration(
                        labelText: 'Most views a day',
                        hintText: 'For example, 500',
                      ).copyWith(
                        helperText: 'Between 10 and 10,000',
                        errorText: _errors.dailyImpressionCap,
                        errorMaxLines: 3,
                      ),
                  validator: validateDailyImpressionCap,
                  onChanged: (_) {
                    if (_errors.dailyImpressionCap != null) {
                      setState(
                        () => _errors = _errors.withoutDailyImpressionCap(),
                      );
                    }
                  },
                ),
                const SizedBox(height: DesignTokens.s16),
                _EndDateField(
                  lastDay: _lastDay,
                  error: _errors.endsUtc,
                  onPick: _pickEndDate,
                  onClear: () => setState(() {
                    _lastDay = null;
                    _errors = _errors.withoutEndsUtc();
                  }),
                ),
                const SizedBox(height: DesignTokens.s16),
                Text(
                  'Shoppers always see the Sponsored label.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                if (general != null) ...[
                  const SizedBox(height: DesignTokens.s12),
                  Text(
                    general,
                    key: const ValueKey('sponsor-form-error'),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorError,
                    ),
                  ),
                ],
                const SizedBox(height: DesignTokens.s16),
                SmPrimaryButton(
                  label: 'Save',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FixedProduct extends StatelessWidget {
  const _FixedProduct({required this.product});

  final SponsorProductTarget product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          product.productName.isEmpty ? 'This product' : product.productName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

/// The vendor's live products. Loading, failure and "no live products" each
/// show a line instead of the dropdown; Save then asks for a product.
class _ProductPicker extends ConsumerWidget {
  const _ProductPicker({required this.selected, required this.onChanged});

  final SponsorProductTarget? selected;
  final ValueChanged<SponsorProductTarget> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void retry() => ref.invalidate(sponsorableProductsProvider);
    const loadFailed = "Couldn't load your live products.";

    return ref
        .watch(sponsorableProductsProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.s12),
            child: Center(
              child: SmBrandLoader(
                size: 32,
                semanticLabel: 'Loading your live products',
              ),
            ),
          ),
          error: (_, _) => _PickerMessage(text: loadFailed, onRetry: retry),
          data: (result) => result.fold(
            (_) => _PickerMessage(text: loadFailed, onRetry: retry),
            (products) => products.isEmpty
                ? const _PickerMessage(
                    text: "You don't have any live products to sponsor yet.",
                  )
                : _ProductDropdown(
                    products: products,
                    selected: selected,
                    onChanged: onChanged,
                  ),
          ),
        );
  }
}

class _ProductDropdown extends StatelessWidget {
  const _ProductDropdown({
    required this.products,
    required this.selected,
    required this.onChanged,
  });

  final List<SponsorProductTarget> products;
  final SponsorProductTarget? selected;
  final ValueChanged<SponsorProductTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedId = products.any((p) => p.productId == selected?.productId)
        ? selected?.productId
        : null;

    return FormField<String>(
      key: const ValueKey('sponsor-product-picker'),
      initialValue: selectedId,
      validator: (value) =>
          value == null ? chooseProductToSponsorMessage : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: DesignTokens.inputFieldFill,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              border: Border.all(
                color: field.hasError
                    ? DesignTokens.colorError
                    : DesignTokens.inputFieldBorder,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: field.value,
                isExpanded: true,
                hint: Text(
                  'Choose a live product',
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                dropdownColor: DesignTokens.bgAppBodyLight,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: DesignTokens.textMuted,
                ),
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
                items: [
                  for (final product in products)
                    DropdownMenuItem(
                      value: product.productId,
                      child: Text(
                        product.productName.isEmpty
                            ? 'Unnamed product'
                            : product.productName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  field.didChange(id);
                  onChanged(products.firstWhere((p) => p.productId == id));
                },
              ),
            ),
          ),
          if (field.errorText != null)
            Padding(
              padding: const EdgeInsets.only(
                top: DesignTokens.s6,
                left: DesignTokens.s12,
              ),
              child: Text(
                field.errorText!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickerMessage extends StatelessWidget {
  const _PickerMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try again',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _EndDateField extends StatelessWidget {
  const _EndDateField({
    required this.lastDay,
    required this.error,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? lastDay;
  final String? error;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final day = lastDay;
    final message = error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'End date (optional)',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s6),
        InkWell(
          key: const ValueKey('sponsor-end-date'),
          onTap: onPick,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          child: Container(
            padding: const EdgeInsets.only(left: DesignTokens.s12),
            constraints: const BoxConstraints(minHeight: 48),
            decoration: BoxDecoration(
              color: DesignTokens.inputFieldFill,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              border: Border.all(
                color: message != null
                    ? DesignTokens.colorError
                    : DesignTokens.inputFieldBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: DesignTokens.iconLight,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    day == null
                        ? 'No end date. Runs until you pause it.'
                        : 'Runs through ${formatSponsorshipDay(day)}',
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                if (day != null)
                  TextButton(
                    onPressed: onClear,
                    child: Text(
                      'Remove',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(
              top: DesignTokens.s6,
              left: DesignTokens.s12,
            ),
            child: Text(
              message,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
      ],
    );
  }
}
