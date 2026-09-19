import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';

/// A transcript as the engine hears it. [isFinal] marks the engine's own
/// settled reading — it never means "submit this".
@immutable
class VoiceTranscript {
  const VoiceTranscript({required this.words, required this.isFinal});

  final String words;
  final bool isFinal;
}

/// How a listening session ended badly.
enum VoiceFailureKind {
  /// The microphone was refused. Recovery depends on [VoiceFailure.status].
  permission,

  /// No engine, no usable locale, nothing to fix.
  unsupported,

  /// Device policy or parental controls.
  restricted,

  /// Nothing heard, network hiccup, engine busy — try again and it may work.
  transient,
}

@immutable
class VoiceFailure {
  const VoiceFailure({
    required this.kind,
    required this.status,
    required this.code,
  });

  final VoiceFailureKind kind;

  /// What the entry point and the recovery screen should do about it.
  final SearchInputStatus status;

  /// The raw engine code, for the muted technical line only.
  final String code;
}

/// The voice half of multimodal search, behind an interface so screens and
/// tests never touch the plugin directly.
abstract class VoiceRecognizer {
  /// Initialises the engine, asking for the microphone if it has not been
  /// asked yet. Returns [SearchInputStatus.ready] when listening can start.
  Future<SearchInputStatus> prepare();

  /// Starts a session. [onTranscript] fires for partials and the final
  /// reading; [onFailure] for anything that ends the session badly;
  /// [onStopped] whenever the engine is no longer listening.
  Future<void> listen({
    required ValueChanged<VoiceTranscript> onTranscript,
    required ValueChanged<VoiceFailure> onFailure,
    required VoidCallback onStopped,
  });

  Future<void> stop();

  Future<void> cancel();
}

/// Maps the engine's error vocabulary onto a state the UI can act on.
///
/// `speech_to_text` reports Android's `SpeechRecognizer` codes and iOS's
/// `SFSpeechError` strings, plus a [permanent] flag meaning "recognition
/// cannot continue until this is resolved".
VoiceFailure mapVoiceError(String errorMsg, {required bool permanent}) {
  final code = errorMsg.trim();
  final msg = code.toLowerCase();
  if (msg.contains('restricted')) {
    return VoiceFailure(
      kind: VoiceFailureKind.restricted,
      status: SearchInputStatus.restricted,
      code: code,
    );
  }
  if (msg.contains('permission') || msg.contains('not_authorized')) {
    return VoiceFailure(
      kind: VoiceFailureKind.permission,
      // A permanent permission error is the "don't ask again" case: the
      // engine will not raise another system prompt, so settings is the
      // only route back.
      status: permanent
          ? SearchInputStatus.deniedForever
          : SearchInputStatus.denied,
      code: code,
    );
  }
  if (msg.contains('language') ||
      msg.contains('not_supported') ||
      msg.contains('unavailable')) {
    return VoiceFailure(
      kind: VoiceFailureKind.unsupported,
      status: SearchInputStatus.unsupported,
      code: code,
    );
  }
  // error_no_match, error_speech_timeout, error_network, error_busy and
  // friends: the session failed, the capability did not.
  return VoiceFailure(
    kind: VoiceFailureKind.transient,
    status: SearchInputStatus.ready,
    code: code.isEmpty ? 'error_unknown' : code,
  );
}

/// The real recognizer, backed by `speech_to_text`.
class SpeechToTextVoiceRecognizer implements VoiceRecognizer {
  SpeechToTextVoiceRecognizer({SpeechToText? speech})
    : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  ValueChanged<VoiceFailure>? _onFailure;
  VoidCallback? _onStopped;
  VoiceFailure? _initFailure;

  @override
  Future<SearchInputStatus> prepare() async {
    _initFailure = null;
    try {
      final worked = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      if (worked) return SearchInputStatus.ready;
      // initialize() answers false both when the platform has no engine and
      // when the microphone was refused; the error callback, if it fired,
      // is the only thing that can tell the two apart.
      return _initFailure?.status ?? SearchInputStatus.unsupported;
    } on Object catch (_) {
      // A missing plugin or a platform channel failure is indistinguishable
      // from "this device cannot do it", and both hide the entry point.
      return SearchInputStatus.unsupported;
    }
  }

  @override
  Future<void> listen({
    required ValueChanged<VoiceTranscript> onTranscript,
    required ValueChanged<VoiceFailure> onFailure,
    required VoidCallback onStopped,
  }) async {
    _onFailure = onFailure;
    _onStopped = onStopped;
    try {
      await _speech.listen(
        onResult: (result) => onTranscript(
          VoiceTranscript(
            words: result.recognizedWords.trim(),
            isFinal: result.finalResult,
          ),
        ),
        listenOptions: SpeechListenOptions(
          // Partials are the point: the buyer watches the words arrive.
          cancelOnError: true,
          listenMode: ListenMode.search,
        ),
      );
    } on Object catch (error) {
      onFailure(mapVoiceError(error.toString(), permanent: false));
      onStopped();
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Object catch (_) {
      // Stopping a session that already ended is not worth surfacing.
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } on Object catch (_) {
      // Same as stop(): teardown must never throw at the caller.
    }
  }

  void _handleError(SpeechRecognitionError error) {
    final failure = mapVoiceError(
      error.errorMsg,
      permanent: error.permanent,
    );
    _initFailure = failure;
    _onFailure?.call(failure);
    _onStopped?.call();
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') _onStopped?.call();
  }
}
