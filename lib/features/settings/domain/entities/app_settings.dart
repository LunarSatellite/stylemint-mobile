class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });

  final String code;
  final String label;
  final String nativeLabel;

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'en', label: 'English', nativeLabel: 'English'),
    LanguageOption(code: 'ne', label: 'Nepali', nativeLabel: 'नेपाली'),
    LanguageOption(code: 'zh', label: 'Chinese', nativeLabel: '中文'),
    LanguageOption(code: 'es', label: 'Spanish', nativeLabel: 'Español'),
    LanguageOption(code: 'hi', label: 'Hindi', nativeLabel: 'हिन्दी'),
  ];
}
