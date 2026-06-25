class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.flag,
    required this.displayName,
  });

  final String code;
  final String flag;
  final String displayName;

  // Legacy getters — keep existing callers compiling
  String get label => displayName;
  String get nativeLabel => displayName;

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', flag: '🇺🇸', displayName: 'English (United States)'),
    LanguageOption(code: 'zh', flag: '🇨🇳', displayName: 'Chinese (中国人)'),
    LanguageOption(code: 'ne', flag: '🇳🇵', displayName: 'Nepali (नेपाली)'),
    LanguageOption(code: 'es', flag: '🇪🇸', displayName: 'Spanish (Español)'),
    LanguageOption(code: 'hi', flag: '🇮🇳', displayName: 'Hindi (हिन्दी)'),
  ];
}
