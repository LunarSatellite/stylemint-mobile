import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AddProductWizardScreen extends ConsumerWidget {
  const AddProductWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addProductNotifierProvider);

    final currentStep = state.maybeWhen(
      loadSuccess: (fs) => fs.currentStep,
      loadInProgress: (fs) => fs.currentStep,
      saveInProgress: (fs) => fs.currentStep,
      saveSuccess: (fs, _) => fs.currentStep,
      saveFailure: (fs, _) => fs.currentStep,
      publishing: (fs) => fs.currentStep,
      publishFailure: (fs, _) => fs.currentStep,
      initial: () => 1,
      loadFailure: (fs, _) => fs.currentStep,
      orElse: () => 1,
    );

    final notifier = ref.read(addProductNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(
          'Add Product',
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              await notifier.saveDraft();
              if (!context.mounted) return;
              final saved = ref.read(addProductNotifierProvider).maybeWhen(
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: WizardStepIndicator(
              currentStep: currentStep,
              totalSteps: 5,
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
                Step5ReviewScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

