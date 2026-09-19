import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/voice_recognizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/search_input_recovery.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _VoicePhase { preparing, idle, listening, blocked }

/// Speak a search, watch it transcribe, fix what the engine misheard, then
/// search.
///
/// The screen never submits on the engine's say-so. `finalResult` means the
/// engine has settled on a reading, not that the reading is right, and a
/// query the buyer cannot correct is a dead end — so the transcript always
/// lands in an editable field and only the Search button runs it.
///
/// Pops the confirmed query back to Discover, which owns recent searches and
/// the route to the results, so voice joins the same path as typing and the
/// photo search rather than opening a second one.
class VoiceSearchScreen extends ConsumerStatefulWidget {
  const VoiceSearchScreen({super.key, this.initialQuery});

  /// Whatever was already typed in the Discover field, kept so speaking does
  /// not silently throw away a half-written search.
  final String? initialQuery;

  static const String title = 'Search by voice';

  @override
  ConsumerState<VoiceSearchScreen> createState() => _VoiceSearchScreenState();
}

class _VoiceSearchScreenState extends ConsumerState<VoiceSearchScreen> {
  late final TextEditingController _transcript = TextEditingController(
    text: widget.initialQuery ?? '',
  );

  /// Held in a field because `ref` is unsafe once the element is being
  /// unmounted, and teardown must still close the microphone.
  late final VoiceRecognizer _recognizer;
  _VoicePhase _phase = _VoicePhase.preparing;
  SearchInputStatus _blocked = SearchInputStatus.unsupported;
  String? _detail;
  String? _transientNote;

  @override
  void initState() {
    super.initState();
    _recognizer = ref.read(voiceRecognizerProvider);
    unawaited(_prepare());
  }

  @override
  void dispose() {
    unawaited(_recognizer.cancel());
    _transcript.dispose();
    super.dispose();
  }

  /// Initialises the engine, which is also what raises the microphone
  /// prompt. Doing it here — after a deliberate tap on the mic — keeps the
  /// prompt in context instead of on Discover's first paint.
  Future<void> _prepare() async {
    setState(() {
      _phase = _VoicePhase.preparing;
      _transientNote = null;
    });
    final status = await _recognizer.prepare();
    ref.read(searchInputCapabilitiesProvider.notifier).reportVoice(status);
    if (!mounted) return;
    if (status != SearchInputStatus.ready) {
      setState(() {
        _phase = _VoicePhase.blocked;
        _blocked = status;
      });
      return;
    }
    setState(() => _phase = _VoicePhase.idle);
    await _startListening();
  }

  Future<void> _startListening() async {
    if (_phase == _VoicePhase.listening) return;
    setState(() {
      _phase = _VoicePhase.listening;
      _transientNote = null;
    });
    await _recognizer.listen(
      onTranscript: _onTranscript,
      onFailure: _onFailure,
      onStopped: _onStopped,
    );
  }

  void _onTranscript(VoiceTranscript transcript) {
    if (!mounted || _phase != _VoicePhase.listening) return;
    final words = transcript.words;
    if (words.isEmpty) return;
    _transcript.value = TextEditingValue(
      text: words,
      selection: TextSelection.collapsed(offset: words.length),
    );
    // A final reading only ends the listening session. The buyer still has
    // to read it and press Search.
    if (transcript.isFinal) setState(() => _phase = _VoicePhase.idle);
  }

  void _onFailure(VoiceFailure failure) {
    if (!mounted) return;
    if (failure.kind == VoiceFailureKind.transient) {
      setState(() {
        _phase = _VoicePhase.idle;
        _transientNote = failure.code.contains('no_match')
            ? "We didn't catch that. Tap the mic and say it again."
            : 'Listening stopped. Tap the mic to try again.';
      });
      return;
    }
    ref
        .read(searchInputCapabilitiesProvider.notifier)
        .reportVoice(failure.status);
    setState(() {
      _phase = _VoicePhase.blocked;
      _blocked = failure.status;
      _detail = failure.code;
    });
  }

  void _onStopped() {
    if (!mounted || _phase != _VoicePhase.listening) return;
    setState(() => _phase = _VoicePhase.idle);
  }

  Future<void> _stopListening() async {
    await _recognizer.stop();
    if (mounted && _phase == _VoicePhase.listening) {
      setState(() => _phase = _VoicePhase.idle);
    }
  }

  Future<void> _toggleListening() async {
    if (_phase == _VoicePhase.listening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _openSettings() async {
    final opened = await ref.read(appSettingsLauncherProvider)();
    if (opened || !mounted) return;
    SmSnackbar.error(
      context,
      'We could not open your device settings. Find StyleMint under '
      'Settings, then Apps, then Permissions.',
    );
  }

  Future<void> _submit() async {
    final query = _transcript.text.trim();
    if (query.isEmpty) return;
    await _recognizer.cancel();
    if (!mounted) return;
    Navigator.of(context).pop(query);
  }

  void _leave() {
    unawaited(_recognizer.cancel());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final listening = _phase == _VoicePhase.listening;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        foregroundColor: DesignTokens.textWhite,
        title: const Text(VoiceSearchScreen.title),
      ),
      body: SafeArea(
        child: switch (_phase) {
          _VoicePhase.preparing => const Center(
            child: CircularProgressIndicator(
              key: ValueKey('voice-search-preparing'),
            ),
          ),
          _VoicePhase.blocked => SearchInputRecovery(
            kind: SearchInputKind.voice,
            status: _blocked,
            detail: _detail,
            onAskAgain: () => unawaited(_prepare()),
            onOpenSettings: () => unawaited(_openSettings()),
            onTypeInstead: _leave,
          ),
          _ => _buildStudio(listening: listening),
        },
      ),
    );
  }

  Widget _buildStudio({required bool listening}) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - DesignTokens.s32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MallStatusPill(
                key: const ValueKey('voice-search-status'),
                label: listening ? 'Listening' : 'Not listening',
                tone: listening
                    ? MallStatusTone.progress
                    : MallStatusTone.neutral,
                icon: listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                semanticLabel: listening
                    ? 'Listening to you now'
                    : 'Microphone is idle',
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            Center(
              // A tooltip sets the semantics *tooltip*, not the accessible
              // name, and this button is an icon with no text of its own.
              child: Semantics(
                button: true,
                label: listening
                    ? 'Stop listening'
                    : 'Start listening and speak your search',
                child: IconButton.filled(
                  key: const ValueKey('voice-search-mic'),
                  tooltip: listening ? 'Stop listening' : 'Start listening',
                  iconSize: 36,
                  onPressed: () => unawaited(_toggleListening()),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(72, 72),
                    backgroundColor: listening
                        ? DesignTokens.primaryGreen
                        : DesignTokens.bgAppBodyLight,
                    foregroundColor: listening
                        ? DesignTokens.bgAppFoundation
                        : DesignTokens.textWhite,
                  ),
                  icon: Icon(
                    listening ? Icons.stop_rounded : Icons.mic_rounded,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            TextField(
              key: const ValueKey('voice-search-transcript'),
              controller: _transcript,
              // Editable the moment listening stops. While the engine is
              // still writing into the field, typing would fight it — so a
              // tap on the field stops listening and hands it over.
              readOnly: listening,
              onTap: listening ? () => unawaited(_stopListening()) : null,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => unawaited(_submit()),
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                height: 1.35,
                color: DesignTokens.textWhite,
              ),
              cursorColor: DesignTokens.primaryGreen,
              decoration: InputDecoration(
                labelText: 'What we heard',
                labelStyle: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: DesignTokens.textMuted,
                ),
                hintText: listening
                    ? 'Say what you are looking for'
                    : 'Nothing heard yet — you can type it',
                hintStyle: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  color: DesignTokens.textMuted,
                ),
                filled: true,
                fillColor: const Color(0xFF1A1E1B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.cardRadius,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              listening
                  ? 'Tap the words to stop listening and fix them.'
                  : 'Check the words before you search — speech gets things '
                        'wrong, and this one is yours to correct.',
              style: DesignTokens.smallRegular,
            ),
            if (_transientNote case final note?) ...[
              const SizedBox(height: DesignTokens.s12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MallStatusPill(
                  key: const ValueKey('voice-search-note'),
                  label: note,
                  tone: MallStatusTone.caution,
                  icon: Icons.hearing_disabled_rounded,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s24),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _transcript,
              builder: (context, value, _) {
                final ready = value.text.trim().isNotEmpty;
                return FilledButton(
                  key: const ValueKey('voice-search-submit'),
                  onPressed: ready ? () => unawaited(_submit()) : null,
                  child: const Text(
                    'Search',
                    semanticsLabel: 'Search for the words above',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
