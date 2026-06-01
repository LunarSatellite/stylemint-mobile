import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/app_settings.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/settings_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    // Fetch current language
    Future.microtask(() {
      ref.read(languageChangeNotifierProvider.notifier);
      // Read initial language; default to 'en'
      _selectedCode = Localizations.localeOf(context).languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LanguageChangeState>(languageChangeNotifierProvider, (prev, next) {
      next.whenOrNull(
        success: (code) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Language updated')),
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

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Language', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: LanguageOption.supportedLanguages.map((lang) {
          final isSelected = _selectedCode == lang.code;
          return Container(
            margin: const EdgeInsets.only(bottom: DesignTokens.s8),
            decoration: BoxDecoration(
              color: isSelected ? DesignTokens.bgAppBodyLight : DesignTokens.bgAppBody,
              borderRadius: BorderRadius.circular(DesignTokens.s12),
              border: isSelected
                  ? Border.all(color: DesignTokens.primaryGreen, width: 1)
                  : null,
            ),
            child: RadioListTile<String>(
              value: lang.code,
              groupValue: _selectedCode,
              activeColor: DesignTokens.primaryGreen,
              title: Text(lang.nativeLabel, style: DesignTokens.mediumSemibold),
              subtitle: Text(lang.label, style: DesignTokens.smallRegular),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCode = value);
                ref.read(languageChangeNotifierProvider.notifier).changeLanguage(value);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
