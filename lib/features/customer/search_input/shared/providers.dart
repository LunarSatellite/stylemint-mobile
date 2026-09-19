import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/app_settings_launcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/barcode_product_lookup.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/camera_probe.dart';
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
    return const SearchInputCapabilities();
  }

  Future<void> probeBarcode() async {
    final hasCamera = await ref.read(cameraProbeProvider)();
    reportBarcode(
      hasCamera ? SearchInputStatus.unprobed : SearchInputStatus.unsupported,
    );
  }

  void reportVoice(SearchInputStatus status) {
    if (state.voice == status) return;
    state = state.copyWith(voice: status);
  }

  void reportBarcode(SearchInputStatus status) {
    if (state.barcode == status) return;
    state = state.copyWith(barcode: status);
  }
}

final searchInputCapabilitiesProvider =
    NotifierProvider<SearchInputCapabilitiesNotifier, SearchInputCapabilities>(
      SearchInputCapabilitiesNotifier.new,
    );
