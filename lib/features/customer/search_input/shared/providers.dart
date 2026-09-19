import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/app_settings_launcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/barcode_product_lookup.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/camera_probe.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/inbound_share.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_image.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/voice_recognizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';

/// One recognizer per voice screen; cancelled when that screen goes away so
/// the microphone is never left open behind a pop.
final Provider<VoiceRecognizer> voiceRecognizerProvider =
    Provider.autoDispose<VoiceRecognizer>((ref) {
      final recognizer = SpeechToTextVoiceRecognizer();
      ref.onDispose(() => unawaited(recognizer.cancel()));
      return recognizer;
    });

final cameraProbeProvider = Provider<CameraProbe>((ref) => deviceHasCamera);

final appSettingsLauncherProvider = Provider<AppSettingsLauncher>(
  (ref) => openSystemAppSettings,
);

final barcodeProductLookupProvider = Provider<BarcodeProductLookup>(
  (ref) => BarcodeProductLookup(
    searchDataSource: ref.watch(customerSearchRemoteDataSourceProvider),
  ),
);

final screenshotPickerProvider = Provider<ScreenshotPicker>(
  (ref) => pickScreenshotFromGallery,
);

final screenshotNormalizerProvider = Provider<ScreenshotNormalizer>(
  (ref) => normalizeScreenshot,
);

final visualSearchProbeProvider = Provider<VisualSearchProbe>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return () => probeVisualSearch(apiClient);
});

final screenshotSearchProvider = Provider<ScreenshotSearch>(
  (ref) => ScreenshotSearch(
    searchDataSource: ref.watch(customerSearchRemoteDataSourceProvider),
  ),
);

/// Where screenshots shared from other apps arrive. Android routes
/// `ACTION_SEND` through `MainActivity`; iOS has no share extension yet and
/// gets [NoInboundShareSource] rather than a channel that throws.
final inboundShareSourceProvider = Provider<InboundShareSource>(
  (ref) => defaultTargetPlatform == TargetPlatform.android
      ? PlatformInboundShareSource()
      : const NoInboundShareSource(),
);

/// Which multimodal inputs Discover may offer, and why not when it may not.
///
/// The camera is probed up front because listing hardware needs no
/// permission. The microphone is not: `speech_to_text.initialize()` raises
/// the system prompt, and a prompt the buyer never asked for, on first paint,
/// is exactly the dark pattern permissions are meant to prevent. Voice is
/// therefore offered optimistically and the first tap does the asking — after
/// which whatever the engine reported is remembered here, so a handset with
/// no speech engine stops being offered one.
class SearchInputCapabilitiesNotifier
    extends Notifier<SearchInputCapabilities> {
  @override
  SearchInputCapabilities build() {
    unawaited(probeBarcode());
    unawaited(probeScreenshot());
    return const SearchInputCapabilities();
  }

  Future<void> probeBarcode() async {
    final hasCamera = await ref.read(cameraProbeProvider)();
    reportBarcode(
      hasCamera ? SearchInputStatus.unprobed : SearchInputStatus.unsupported,
    );
  }

  /// Screenshot search is gated by the server, not the handset, so the probe
  /// is a request rather than a hardware listing. It raises no permission
  /// prompt, which is why it may run while Discover paints.
  Future<void> probeScreenshot() async {
    reportScreenshot(await ref.read(visualSearchProbeProvider)());
  }

  void reportVoice(SearchInputStatus status) {
    if (state.voice == status) return;
    state = state.copyWith(voice: status);
  }

  void reportBarcode(SearchInputStatus status) {
    if (state.barcode == status) return;
    state = state.copyWith(barcode: status);
  }

  void reportScreenshot(SearchInputStatus status) {
    if (state.screenshot == status) return;
    state = state.copyWith(screenshot: status);
  }
}

final searchInputCapabilitiesProvider =
    NotifierProvider<SearchInputCapabilitiesNotifier, SearchInputCapabilities>(
      SearchInputCapabilitiesNotifier.new,
    );
