import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step1_basic_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step2_images_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step3_pricing_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step4_shipping_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/widgets/wizard_step_indicator.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor → Products → ⋮ → Edit Product Details — full field edit on an
/// already-published product. Reuses the wizard's 4 step screens as-is
/// (they read/write via `addProductNotifierProvider`), but swaps the
/// wizard's Draft-only submitDraft/publish flow for
/// `AddProductNotifier.loadForEdit`/`saveEditedDetails`, which hit the
/// `details/*` + `images` endpoints instead — those work regardless of
/// product state (see Product.AssertEditableOutsideWizard on the backend).
class EditProductDetailsScreen extends ConsumerStatefulWidget {
  const EditProductDetailsScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<EditProductDetailsScreen> createState() =>
      _EditProductDetailsScreenState();
}

class _EditProductDetailsScreenState
    extends ConsumerState<EditProductDetailsScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final ok = await ref
        .read(addProductNotifierProvider.notifier)
        .loadForEdit(widget.productId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadFailed = !ok;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await ref
        .read(addProductNotifierProvider.notifier)
        .saveEditedDetails(widget.productId);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Product updated!'
              : 'Failed to save — check all steps are complete.',
        ),
        backgroundColor: ok ? DesignTokens.primaryGreen : DesignTokens.colorError,
      ),
    );
    if (ok) context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductNotifierProvider);
    // The reused step screens' own "Proceed" on step 4 advances to step 5
    // (the wizard's Review/Publish screen), which this edit host doesn't
    // include — clamp the display so that doesn't index out of range.
    final currentStep = state
        .maybeWhen(
          loadSuccess: (fs) => fs.currentStep,
          loadInProgress: (fs) => fs.currentStep,
          orElse: () => 1,
        )
        .clamp(1, 4);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Product Details',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading || _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignTokens.primaryGreen,
                    ),
                  )
                : Text(
                    'Save',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
            )
          : _loadFailed
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Failed to load product details.',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s16,
                        vertical: DesignTokens.s12,
                      ),
                      child: WizardStepIndicator(
                        currentStep: currentStep,
                        totalSteps: 4,
                      ),
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: currentStep - 1,
                        children: const [
                          Step1BasicInfoScreen(),
                          Step2ImagesScreen(),
                          Step3PricingScreen(),
                          Step4ShippingScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
