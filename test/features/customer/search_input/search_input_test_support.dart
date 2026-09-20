import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/app_settings_launcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/inbound_share.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_image.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/voice_recognizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/screenshot_search_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';

/// A recognizer the test drives by hand: nothing touches the plugin, so the
/// permission and unsupported paths can be exercised on a desktop VM.
class FakeVoiceRecognizer implements VoiceRecognizer {
  FakeVoiceRecognizer({this.prepareStatus = SearchInputStatus.ready});

  SearchInputStatus prepareStatus;
  int prepareCalls = 0;
  bool listening = false;
  bool cancelled = false;

  ValueChanged<VoiceTranscript>? _onTranscript;
  ValueChanged<VoiceFailure>? _onFailure;
  VoidCallback? _onStopped;

  @override
  Future<SearchInputStatus> prepare() async {
    prepareCalls++;
    return prepareStatus;
  }

  @override
  Future<void> listen({
    required ValueChanged<VoiceTranscript> onTranscript,
    required ValueChanged<VoiceFailure> onFailure,
    required VoidCallback onStopped,
  }) async {
    listening = true;
    _onTranscript = onTranscript;
    _onFailure = onFailure;
    _onStopped = onStopped;
  }

  @override
  Future<void> stop() async {
    listening = false;
    _onStopped?.call();
  }

  @override
  Future<void> cancel() async {
    listening = false;
    cancelled = true;
  }

  void hear(String words, {bool isFinal = false}) =>
      _onTranscript?.call(VoiceTranscript(words: words, isFinal: isFinal));

  void fail(VoiceFailure failure) => _onFailure?.call(failure);
}

/// Callable, so it can stand in for the [AppSettingsLauncher] function type
/// while still counting how many times the screen reached for settings.
class FakeAppSettingsLauncher {
  FakeAppSettingsLauncher({this.succeeds = true});

  final bool succeeds;
  int opened = 0;

  Future<bool> call() async {
    opened++;
    return succeeds;
  }
}

/// Pins the capability state so a test can say "this device has no camera"
/// without the notifier probing real hardware.
class FixedCapabilities extends SearchInputCapabilitiesNotifier {
  FixedCapabilities(this.initial);

  final SearchInputCapabilities initial;

  @override
  SearchInputCapabilities build() => initial;

  @override
  Future<void> probeBarcode() async {}
}

/// ---------------------------------------------------------------------------
/// Screenshot search
/// ---------------------------------------------------------------------------

/// A chooser the test answers for. No `image_picker`, no gallery, no plugin.
class FakeScreenshotPicker {
  FakeScreenshotPicker(this.result);

  ScreenshotPick result;
  int calls = 0;

  Future<ScreenshotPick> call() async {
    calls++;
    return result;
  }
}

/// Normalisation without a real codec: widget tests care that the bytes
/// reach the confirm step and the request unchanged, not that PNG encoding
/// works — [normalizeScreenshot] has its own test for that.
Future<ScreenshotImage> fakeNormalize(Uint8List raw) async =>
    ScreenshotImage(bytes: raw, width: 12, height: 20);

/// Stands in for the network. Records exactly what was handed to it, which
/// is how the tests assert that a shared screenshot and a picked one travel
/// the same way.
class FakeScreenshotSearch implements ScreenshotSearch {
  FakeScreenshotSearch(this.outcome);

  ScreenshotSearchOutcome outcome;
  final List<Uint8List> searched = [];
  final List<String?> queries = [];

  @override
  CustomerSearchRemoteDataSource get searchDataSource =>
      throw UnimplementedError('The fake never reaches the network.');

  @override
  Future<ScreenshotSearchOutcome> run(
    ScreenshotImage screenshot, {
    String? query,
  }) async {
    searched.add(screenshot.bytes);
    queries.add(query);
    return outcome;
  }
}

/// A share sheet the test drives: one cold-start share, plus any number of
/// warm ones pushed while the app is running.
class FakeInboundShareSource implements InboundShareSource {
  FakeInboundShareSource({this.launchShare});

  InboundShare? launchShare;
  int takeCalls = 0;
  final StreamController<InboundShare> _controller =
      StreamController<InboundShare>.broadcast();

  void share(Uint8List bytes) => _controller.add(InboundShare(bytes: bytes));

  Future<void> close() => _controller.close();

  @override
  Future<InboundShare?> takeLaunchShare() async {
    takeCalls++;
    final share = launchShare;
    // Taken once, exactly as the platform source behaves.
    launchShare = null;
    return share;
  }

  @override
  Stream<InboundShare> get shares => _controller.stream;
}

SearchResultProduct fakeSearchProduct(String name) => SearchResultProduct(
  productId: 'p-$name',
  name: name,
  heroImageUrl: 'https://example.test/$name.jpg',
  price: 10,
  currency: 'USD',
  averageRating: 4,
);

CustomerSearchResults fakeResults(List<String> names) => CustomerSearchResults(
  products: names.map(fakeSearchProduct).toList(),
  brands: const [],
  reels: const [],
  creators: const [],
  totalHits: names.length,
  queryUnderstanding: 'Products recognized from your photo',
);

/// A real, decodable 1x1 PNG.
///
/// The confirm step draws the picture with `Image.memory`, so widget tests
/// need bytes Flutter's codec accepts — arbitrary numbers make the image
/// resource service throw and the assertion then measures the wrong thing.
final Uint8List tinyPngBytes = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);
