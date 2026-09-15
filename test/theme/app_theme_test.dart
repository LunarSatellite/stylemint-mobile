import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';
import 'package:stylemint_mobile_frontend/theme/colors.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/theme/font_licenses.dart';

List<TextStyle?> _styles(TextTheme theme) => [
  theme.displayLarge,
  theme.displayMedium,
  theme.displaySmall,
  theme.headlineLarge,
  theme.headlineMedium,
  theme.headlineSmall,
  theme.titleLarge,
  theme.titleMedium,
  theme.titleSmall,
  theme.bodyLarge,
  theme.bodyMedium,
  theme.bodySmall,
  theme.labelLarge,
  theme.labelMedium,
  theme.labelSmall,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('font families', () {
    test('every Material text style is Poppins in both themes', () {
      for (final theme in [AppTheme.dark, AppTheme.light]) {
        for (final style in [
          ..._styles(theme.textTheme),
          ..._styles(theme.primaryTextTheme),
        ]) {
          expect(style?.fontFamily, 'Poppins');
        }
      }
    });

    test('token type scale is Poppins; editorial display is Instrument '
        'Serif', () {
      for (final style in [
        DesignTokens.titleLarge,
        DesignTokens.bodyText,
        DesignTokens.smallRegular,
        DesignTokens.eyebrow,
      ]) {
        expect(style.fontFamily, 'Poppins');
      }
      for (final style in [
        DesignTokens.displayHero,
        DesignTokens.displayTitle,
        DesignTokens.displaySection,
        DesignTokens.displayAccent,
      ]) {
        expect(style.fontFamily, 'InstrumentSerif');
      }
      expect(DesignTokens.displayAccent.fontStyle, FontStyle.italic);
      expect(
        DesignTokens.displayHero.fontSize! * DesignTokens.displayHero.height!,
        closeTo(44, 0.001),
      );
      expect(DesignTokens.eyebrow.letterSpacing, 1.2);
      expect(DesignTokens.eyebrow.fontWeight, FontWeight.w600);
    });

    test('pubspec bundles both families and their TTFs ship', () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json'))
              as List<dynamic>;
      final families = {
        for (final entry in manifest.cast<Map<String, dynamic>>())
          entry['family'] as String: (entry['fonts'] as List<dynamic>)
              .cast<Map<String, dynamic>>(),
      };
      expect(families.keys, containsAll(['Poppins', 'InstrumentSerif']));
      expect(families.keys, isNot(contains('Inter')));
      expect(
        families['Poppins']!.map((font) => '${font['weight']}'),
        containsAll(['400', '500', '600', '700']),
      );
      expect(
        families['InstrumentSerif']!.map((font) => font['style']),
        contains('italic'),
      );
      for (final font in [
        ...families['Poppins']!,
        ...families['InstrumentSerif']!,
      ]) {
        final data = await rootBundle.load(font['asset'] as String);
        expect(data.lengthInBytes, greaterThan(50000));
        expect(data.getUint32(0), 0x00010000, reason: 'TrueType header');
      }
    });
  });

  group('font licences', () {
    setUp(LicenseRegistry.reset);
    tearDown(LicenseRegistry.reset);

    test('OFL texts for both families reach the licence registry', () async {
      registerFontLicenses();
      final entries = await LicenseRegistry.licenses.toList();
      expect(
        entries.expand((entry) => entry.packages),
        containsAll(['Poppins', 'Instrument Serif']),
      );
      for (final entry in entries) {
        final text = entry.paragraphs.map((p) => p.text).join('\n');
        expect(text, contains('SIL Open Font License'));
      }
    });
  });

  group('colours', () {
    test('schemes derive from DesignTokens', () {
      final dark = AppTheme.dark;
      expect(dark.colorScheme.primary, DesignTokens.primaryGreen);
      expect(dark.colorScheme.onPrimary, DesignTokens.buttonPrimaryText);
      expect(dark.colorScheme.surface, DesignTokens.bgAppFoundation);
      expect(dark.scaffoldBackgroundColor, DesignTokens.bgAppFoundation);
      expect(dark.textTheme.bodyMedium?.color, DesignTokens.textWhite);
      expect(dark.colorScheme.surfaceContainerHigh, DesignTokens.surfaceRaised);
      expect(AppTheme.light.colorScheme.primary, DesignTokens.primaryGreen);
    });

    test('legacy k* names alias the tokens', () {
      expect(kPrimaryColor, DesignTokens.primaryGreen);
      expect(kTextColor, DesignTokens.textWhite);
      expect(kShimmerBase, DesignTokens.bgAppBody);
    });
  });
}
