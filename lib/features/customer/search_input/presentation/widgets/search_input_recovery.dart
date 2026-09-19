import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Which input a recovery screen is speaking about.
enum SearchInputKind {
  voice,
  barcode,
  screenshot;

  /// What the "Allow …" button is asking for. A screenshot search asks for
  /// the photo library rather than a piece of hardware, so the word is not
  /// the name of a sensor.
  String get hardware => switch (this) {
    SearchInputKind.voice => 'microphone',
    SearchInputKind.barcode => 'camera',
    SearchInputKind.screenshot => 'photos',
  };
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
    (SearchInputKind.screenshot, SearchInputStatus.denied) => (
      title: 'StyleMint needs to open your photos',
      body:
          'You pick the one screenshot yourself, and you see it before '
          'anything is sent. StyleMint never browses your gallery.',
      icon: Icons.image_not_supported_outlined,
    ),
    (SearchInputKind.screenshot, SearchInputStatus.deniedForever) => (
      title: 'Photo access is switched off for StyleMint',
      body:
          'Your device will not ask again. Turn photo access back on in '
          'settings, then come back to this screen. Sharing a screenshot to '
          'StyleMint from another app still works without it.',
      icon: Icons.image_not_supported_outlined,
    ),
    (SearchInputKind.screenshot, SearchInputStatus.restricted) => (
      title: 'Photo access is restricted on this device',
      body:
          'A device policy or a parental control is blocking it. Whoever '
          'manages this device can allow it for StyleMint in settings.',
      icon: Icons.lock_outline_rounded,
    ),
    (SearchInputKind.screenshot, _) => (
      // The server, not the handset: visual search is bound only where a
      // vision provider is configured.
      title: "Screenshot search isn't available yet",
      body:
          'The Mall cannot read pictures in this region yet. Typing and '
          'scanning a barcode both work.',
      icon: Icons.image_not_supported_outlined,
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
