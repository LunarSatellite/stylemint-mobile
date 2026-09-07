import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step1_basic_info_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step2_images_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step3_pricing_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step4_shipping_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/screens/step5_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/widgets/wizard_step_indicator.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Unified Product Form screen — Create and Edit share the same UI.
///
/// When [productId] is null the screen runs in Create mode (used by the
/// "Add Product" FAB on the vendor Products list): 5-step wizard with a
/// Review/Publish step at the end, "Save as Draft" in the AppBar, and a
/// "Create Product" submit on step 5.
///
/// When [productId] is provided the screen runs in Edit mode (reached via
/// `/vendor/products/:productId/edit`): calls `loadForEdit` on mount to
/// fetch the existing product and pre-populate every step, shows the
/// "Edit Product" title with a "Save Changes" action in the AppBar, drops
/// the Review step (4 steps total), and submits via `saveEditedDetails`
/// against the `details/*` + `images` endpoints — not the Draft-only
/// wizard steps.
class AddProductWizardScreen extends ConsumerStatefulWidget {
  const AddProductWizardScreen({this.productId, super.key});

  /// When non-null, the screen runs in Edit mode for an existing product.
  /// When null, the screen runs in Create mode for a new product.
  final String? productId;

  bool get isEditMode => productId != null;

  @override
  ConsumerState<AddProductWizardScreen> createState() =>
      _AddProductWizardScreenState();
}

class _AddProductWizardScreenState
    extends ConsumerState<AddProductWizardScreen> {
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadForEdit());
    } else {
      // No async load — render the empty Create form immediately.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  Future<void> _loadForEdit() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final ok = await ref
        .read(addProductNotifierProvider.notifier)
        .loadForEdit(widget.productId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadFailed = !ok;
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    final ok = await ref
        .read(addProductNotifierProvider.notifier)
        .saveEditedDetails(widget.productId!);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      SmSnackbar.success(context, 'Product updated!');
      context.pop(true);
    } else {
      SmSnackbar.error(
        context,
        'Failed to save — check all steps are complete.',
      );
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(
          'Discard changes?',
          style: TextStyle(
            color: DesignTokens.textWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'You have unsaved changes. Leave without saving?',
          style: TextStyle(color: DesignTokens.textLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Keep editing',
              style: TextStyle(color: DesignTokens.textLight),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(
                color: DesignTokens.colorError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductNotifierProvider);

    final currentStep = state.maybeWhen(
          loadSuccess: (fs) => fs.currentStep,
          loadInProgress: (fs) => fs.currentStep,
          saveInProgress: (fs) => fs.currentStep,
          saveSuccess: (fs, _) => fs.currentStep,
          saveFailure: (fs, _) => fs.currentStep,
          publishing: (fs) => fs.currentStep,
          publishFailure: (fs, _) => fs.currentStep,
          loadFailure: (fs, _) => fs.currentStep,
          orElse: () => 1,
        )
        // Edit mode has 4 steps only (no Review). Clamp so the reused
        // step screens' `nextStep()` calls don't index past the end of
        // the IndexedStack below.
        .clamp(1, _isEditMode ? 4 : 5);

    final notifier = ref.read(addProductNotifierProvider.notifier);

    return PopScope(
      // Always intercept the system back gesture so we can prompt on
      // dirty forms. When the form is clean, `onPopInvokedWithResult`
      // pops immediately (no dialog).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (ref.read(addProductNotifierProvider.notifier).isDirty) {
          final discard = await _confirmDiscardChanges();
          if (!discard || !context.mounted) return;
        }
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/vendor/products');
        }
      },
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          title: Text(
            _isEditMode ? 'Edit Product' : 'Add New Product',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_isEditMode)
              _SaveChangesAction(
                saving: _saving,
                enabled: !_loading && !_loadFailed,
                onPressed: _saveChanges,
              )
            else
              TextButton(
                onPressed: () async {
                  await notifier.saveDraft();
                  if (!context.mounted) return;
                  final saved = ref
                      .read(addProductNotifierProvider)
                      .maybeWhen(
                        saveSuccess: (_, d) => true,
                        orElse: () => false,
                      );
                  if (saved) {
                    SmSnackbar.success(context, 'Draft saved.');
                  } else {
                    SmSnackbar.info(
                      context,
                      'Complete all steps to save as draft.',
                    );
                  }
                },
                child: Text(
                  'Save as Draft',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.primaryGreen),
                ),
              ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              )
            : _loadFailed
                ? _LoadFailedView(onRetry: _loadForEdit)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s16,
                          vertical: DesignTokens.s12,
                        ),
                        child: WizardStepIndicator(
                          currentStep: currentStep,
                          totalSteps: _isEditMode ? 4 : 5,
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: currentStep - 1,
                          children: _isEditMode
                              ? const [
                                  Step1BasicInfoScreen(),
                                  Step2ImagesScreen(),
                                  Step3PricingScreen(),
                                  Step4ShippingScreen(),
                                ]
                              : const [
                                  Step1BasicInfoScreen(),
                                  Step2ImagesScreen(),
                                  Step3PricingScreen(),
                                  Step4ShippingScreen(),
                                  Step5ReviewScreen(),
                                ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _SaveChangesAction extends StatelessWidget {
  const _SaveChangesAction({
    required this.saving,
    required this.enabled,
    required this.onPressed,
  });

  final bool saving;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: (saving || !enabled) ? null : onPressed,
      child: saving
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DesignTokens.primaryGreen,
              ),
            )
          : Text(
              'Save Changes',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _LoadFailedView extends StatelessWidget {
  const _LoadFailedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
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
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}