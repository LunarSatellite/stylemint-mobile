import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// SIL Open Font License texts for the fonts bundled in `assets/fonts/`,
/// keyed by the family name shown on the licence page.
const Map<String, String> fontLicenseAssets = {
  'Poppins': 'assets/fonts/Poppins-OFL.txt',
  'Instrument Serif': 'assets/fonts/InstrumentSerif-OFL.txt',
};

/// Adds the bundled fonts' OFL texts to [LicenseRegistry] so they appear on
/// the Flutter licence page next to package licences.
///
/// Call once at startup, after `WidgetsFlutterBinding.ensureInitialized()`.
/// The texts are read lazily, only when the licence page is opened.
void registerFontLicenses({AssetBundle? bundle}) {
  final source = bundle ?? rootBundle;
  LicenseRegistry.addLicense(() async* {
    for (final entry in fontLicenseAssets.entries) {
      final text = await source.loadString(entry.value);
      yield LicenseEntryWithLineBreaks([entry.key], text);
    }
  });
}
