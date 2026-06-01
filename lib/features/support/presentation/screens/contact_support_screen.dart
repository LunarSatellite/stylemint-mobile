import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/support/domain/entities/support_category.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/notifiers/support_notifier.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _categoryId;
  late final SupportCategory? _preselectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final route = GoRouterState.of(context);
      if (route.extra is SupportCategory) {
        final cat = route.extra as SupportCategory;
        _preselectedCategory = cat;
        _categoryId = cat.id;
        _subjectCtrl.text = cat.title;
      }
      ref.read(categoriesNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(createTicketNotifierProvider.notifier).submit(
      subject: _subjectCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      categoryId: _categoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createTicketNotifierProvider);
    final categoriesState = ref.watch(categoriesNotifierProvider);

    ref.listen<CreateTicketState>(createTicketNotifierProvider, (prev, next) {
      next.whenOrNull(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ticket submitted successfully')),
          );
          context.pop();
        },
        failure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${failure.toString()}')),
          );
        },
      );
    });

    final isSubmitting = state.maybeWhen(orElse: () => false, submitting: () => true);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Contact Support', style: DesignTokens.sectionInnerTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            // Category dropdown
            categoriesState.maybeWhen(
              loadSuccess: (categories) => Container(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
                decoration: BoxDecoration(
                  color: DesignTokens.inputFieldFill,
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  border: Border.all(color: DesignTokens.inputFieldBorder),
                ),
                child: DropdownButtonFormField<String>(
                  value: _categoryId,
                  dropdownColor: DesignTokens.bgAppBody,
                  style: const TextStyle(color: DesignTokens.textWhite),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: InputBorder.none,
                  ),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.title),
                  )).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              orElse: () => const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen)),
            ),

            const SizedBox(height: DesignTokens.s16),

            TextFormField(
              controller: _subjectCtrl,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(labelText: 'Subject'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
            ),
            const SizedBox(height: DesignTokens.s16),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 5,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(labelText: 'Message'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
            ),
            const SizedBox(height: DesignTokens.s32),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submit,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  isSubmitting ? 'Submitting...' : 'Submit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
