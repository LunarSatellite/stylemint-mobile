import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Which input a recovery screen is speaking about.
enum SearchInputKind {
  voice,
  barcode;

  String get hardware =>
      this == SearchInputKind.voice ? 'microphone' : 'camera';
}

/// The one screen a blocked voice or barcode search lands on.
///
/// Every status it accepts carries a way forward — ask again, open the
/// system settings, or fall back to typing — so neither input can leave the
/// buyer on a screen with nothing to press.
class SearchInputRecovery extends StatelessWidget {
  const SearchInputRecovery({
    required this.kind,
    required this.status,
    required this.onAskAgain,
    required this.onOpenSettings,
    required this.onTypeInstead,
    super.key,
    this.detail,
  });

  final SearchInputKind kind;
  final SearchInputStatus status;

  /// Re-triggers the system prompt. Only reachable while it can still appear.
  final VoidCallback onAskAgain;
  final VoidCallback onOpenSettings;

  /// Leaves for the ordinary typed search, which works on every device.
  final VoidCallback onTypeInstead;

  /// The raw engine code, shown small and muted under the copy.
  final String? detail;

  ({String title, String body, IconData icon}) get _copy => switch ((
    kind,
    status,
  )) {
    (SearchInputKind.voice, SearchInputStatus.denied) => (
      title: 'StyleMint needs the microphone',
      body:
          'Voice search listens only while this screen is open, and the words '
          'stay yours to edit before anything is searched.',
      icon: Icons.mic_off_rounded,
    ),
    (SearchInputKind.voice, SearchInputStatus.deniedForever) => (
      title: 'The microphone is switched off for StyleMint',
      body:
          'Your device will not ask again. Turn the microphone back on in '
          'settings, then come back to this screen.',
      icon: Icons.mic_off_rounded,
    ),
    (SearchInputKind.voice, SearchInputStatus.restricted) => (
      title: 'The microphone is restricted on this device',
      body:
          'A device policy or a parental control is blocking it. Whoever '
          'manages this device can allow it for StyleMint in settings.',
      icon: Icons.lock_outline_rounded,
    ),
    (SearchInputKind.voice, _) => (
      title: "Voice search isn't available on this device",
      body:
          'This handset has no speech recognition StyleMint can use, or not '
          'in your language. Typing works everywhere.',
      icon: Icons.mic_off_rounded,
    ),
    (SearchInputKind.barcode, SearchInputStatus.denied) => (
      title: 'StyleMint needs the camera',
      body:
          'Scanning reads the barcode on your device. No picture is kept and '
          'nothing is uploaded.',
      icon: Icons.no_photography_rounded,
    ),
    (SearchInputKind.barcode, SearchInputStatus.deniedForever) => (
      title: 'The camera is switched off for StyleMint',
      body:
          'Your device will not ask again. Turn the camera back on in '
          'settings, then come back to this screen.',
      icon: Icons.no_photography_rounded,
    ),
    (SearchInputKind.barcode, SearchInputStatus.restricted) => (
      title: 'The camera is restricted on this device',
      body:
          'A device policy or a parental control is blocking it. Whoever '
          'manages this device can allow it for StyleMint in settings.',
      icon: Icons.lock_outline_rounded,
    ),
    (SearchInputKind.barcode, _) => (
      title: 'This device has no camera to scan with',
      body:
          'StyleMint could not find a camera it can use. Typing works '
          'everywhere.',
      icon: Icons.no_photography_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final askAgain = status.canAskAgain;
    final settings = status.opensSystemSettings;
    // Exactly one primary action, and "type instead" is always present
    // underneath it unless it is the primary one.
    final primaryLabel = askAgain
        ? 'Allow ${kind.hardware}'
        : settings
        ? 'Open settings'
        : 'Type your search instead';
    final primaryAction = askAgain
        ? onAskAgain
        : settings
        ? onOpenSettings
        : onTypeInstead;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MallErrorState(
                key: const ValueKey('search-input-recovery'),
                title: copy.title,
                body: copy.body,
                detail: detail,
                icon: copy.icon,
                retryLabel: primaryLabel,
                onRetry: primaryAction,
              ),
              if (primaryAction != onTypeInstead)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: DesignTokens.s24,
                    left: DesignTokens.s24,
                    right: DesignTokens.s24,
                  ),
                  child: TextButton(
                    key: const ValueKey('search-input-type-instead'),
                    onPressed: onTypeInstead,
                    child: const Text(
                      'Type your search instead',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
