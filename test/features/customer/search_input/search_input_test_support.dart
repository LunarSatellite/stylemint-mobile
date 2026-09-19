import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/app_settings_launcher.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/voice_recognizer.dart';
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
