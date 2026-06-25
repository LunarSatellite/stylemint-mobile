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
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _selectedCode = Localizations.localeOf(context).languageCode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LanguageChangeState>(languageChangeNotifierProvider, (_, next) {
      next.whenOrNull(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Language updated')),
          );
          context.pop();
        },
        failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${f.toString()}')),
        ),
      );
    });

    final filtered = _query.isEmpty
        ? LanguageOption.supportedLanguages
        : LanguageOption.supportedLanguages
            .where((l) => l.displayName.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
        title: const Text('Language', style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          Text(
            'Select your preferred language',
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textWhite),
              decoration: InputDecoration(
                hintText: 'Search language',
                hintStyle: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textMuted),
                suffixIcon: const Icon(Icons.search, color: DesignTokens.textMuted, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s12,
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),

          // Language list card
          if (filtered.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        color: DesignTokens.borderDefault,
                        indent: DesignTokens.s16,
                        endIndent: DesignTokens.s16,
                      ),
                    _LanguageTile(
                      option: filtered[i],
                      isSelected: _selectedCode == filtered[i].code,
                      isFirst: i == 0,
                      isLast: i == filtered.length - 1,
                      onTap: () {
                        setState(() => _selectedCode = filtered[i].code);
                        ref
                            .read(languageChangeNotifierProvider.notifier)
                            .changeLanguage(filtered[i].code);
                      },
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s32),
              child: Center(
                child: Text(
                  'No languages found',
                  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.option,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final LanguageOption option;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(DesignTokens.cardRadius);
    final borderRadius = BorderRadius.only(
      topLeft: isFirst ? r : Radius.zero,
      topRight: isFirst ? r : Radius.zero,
      bottomLeft: isLast ? r : Radius.zero,
      bottomRight: isLast ? r : Radius.zero,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? DesignTokens.primaryGreen.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
          child: Row(
            children: [
              // Flag in white rounded square
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                ),
                alignment: Alignment.center,
                child: Text(option.flag, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: DesignTokens.s16),
              Expanded(
                child: Text(
                  option.displayName,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: isSelected ? DesignTokens.primaryGreen : DesignTokens.textWhite,
                  ),
                ),
              ),
              // Radio indicator — bullseye style
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
