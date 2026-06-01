import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/marketing_consents_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class MarketingConsentsScreen extends ConsumerStatefulWidget {
  const MarketingConsentsScreen({super.key});

  @override
  ConsumerState<MarketingConsentsScreen> createState() =>
      _MarketingConsentsScreenState();
}

class _MarketingConsentsScreenState extends ConsumerState<MarketingConsentsScreen> {
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final session = ref.read(sessionControllerProvider);
    _accountId = session.maybeWhen(
      authenticated: (id) => id,
      orElse: () => null,
    );
    if (_accountId != null) {
      ref.read(marketingConsentsProvider.notifier).load(_accountId!);
    }
  }

  Future<void> _toggle(String category, bool currentValue) async {
    if (_accountId == null) return;
    await ref.read(marketingConsentsProvider.notifier).toggle(
      accountId: _accountId!,
      category: category,
      consented: !currentValue,
    );
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'email':
        return 'Email Marketing';
      case 'push':
        return 'Push Notifications';
      case 'sms':
        return 'SMS Marketing';
      default:
        return category;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'email':
        return Icons.email_outlined;
      case 'push':
        return Icons.notifications_outlined;
      case 'sms':
        return Icons.sms_outlined;
      default:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketingConsentsProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded,
              color: DesignTokens.textWhite, size: DesignTokens.iconMedium),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Marketing Preferences',
            style: TextStyle(color: DesignTokens.textWhite)),
      ),
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (consents) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(DesignTokens.s16),
                    children: [
                      Text(
                        'Choose how you want to hear from us',
                        style: DesignTokens.bodyText,
                      ),
                      const SizedBox(height: DesignTokens.s24),
                      ...consents.map((c) {
                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: DesignTokens.s8),
                          padding: const EdgeInsets.all(DesignTokens.s16),
                          decoration: BoxDecoration(
                            color: DesignTokens.bgAppBody,
                            borderRadius: BorderRadius.circular(
                                DesignTokens.cardRadius),
                            border: Border.all(
                                color: DesignTokens.borderDefault),
                          ),
                          child: Row(
                            children: [
                              Icon(_categoryIcon(c.category),
                                  size: DesignTokens.iconMedium,
                                  color: DesignTokens.textLight),
                              const SizedBox(width: DesignTokens.s16),
                              Expanded(
                                child: Text(
                                  _categoryLabel(c.category),
                                  style: DesignTokens.oneLinerSemibold,
                                ),
                              ),
                              Switch(
                                value: c.consented,
                                onChanged: (_) =>
                                    _toggle(c.category, c.consented),
                                activeColor: DesignTokens.primaryGreen,
                                activeTrackColor:
                                    DesignTokens.primaryGreenDark,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    DesignTokens.s8,
                    DesignTokens.s16,
                    DesignTokens.s32,
                  ),
                  decoration: const BoxDecoration(
                    color: DesignTokens.bgAppFoundation,
                    border: Border(
                      top: BorderSide(
                          color: DesignTokens.borderDefault, width: 1),
                    ),
                  ),
                  child: SmPrimaryButton(
                    label: 'Back',
                    onPressed: () async { Navigator.pop(context); },
                    height: DesignTokens.buttonHeight,
                    borderRadius: DesignTokens.buttonRadius,
                    color: DesignTokens.buttonGrayFill,
                    labelColor: DesignTokens.buttonGrayText,
                  ),
                ),
              ],
            );
          },
          loadFailure: (failure) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: DesignTokens.colorError, size: 48),
                const SizedBox(height: DesignTokens.s16),
                Text('Failed to load preferences',
                    style: DesignTokens.bodyText),
                const SizedBox(height: DesignTokens.s16),
                GestureDetector(
                  onTap: _load,
                  child: Text('Retry',
                      style: TextStyle(color: DesignTokens.primaryGreen)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}
