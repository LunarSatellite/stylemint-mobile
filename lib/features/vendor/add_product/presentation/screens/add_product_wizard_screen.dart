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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 1)
                  TextButton(
                    onPressed: () => notifier.prevStep(),
                    child: Text('Back',
                        style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textMuted)),
                  )
                else
                  const SizedBox(width: 48),
                WizardStepIndicator(
                  currentStep: currentStep,
                  totalSteps: 5,
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          _StepLabel(currentStep: currentStep, totalSteps: 5),
          const SizedBox(height: DesignTokens.s8),
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

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final label = switch (currentStep) {
      1 => 'Basic Info',
      2 => 'Images',
      3 => 'Pricing',
      4 => 'Shipping',
      5 => 'Review',
      _ => '',
    };

    return Text(
      'Step $currentStep of $totalSteps: $label',
      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
    );
  }
}
