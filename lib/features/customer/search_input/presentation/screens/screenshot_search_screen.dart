import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_image.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/screenshot_search_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/screenshot_no_match.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/search_input_recovery.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Search the Mall with a screenshot of somewhere else.
///
/// A photo is of a thing in the world; a screenshot is of another app's
/// screen — a product page, a chat, a post. It is the input a buyer already
/// has when they see something they want, and it arrives here two ways:
///
/// * **Shared in** from the other app, through the system share sheet, which
///   is the common one. [sharedBytes] carries it.
/// * **Picked** from the gallery, when the buyer came to StyleMint first.
///
/// Both converge on the same confirm step below, so there is one upload
/// path, one disclosure and one set of endings — not a second, looser route
/// for shares.
///
/// ## The confirm step is not a formality
///
/// A screenshot can hold a private conversation, an account balance or
/// somebody else's face, and the buyer may not have looked closely at what
/// they shared. So nothing is uploaded on arrival. The picture is shown at
/// the size it will be sent, next to a plain sentence about what leaves the
/// device and what is kept, and the upload happens only when the buyer taps
/// the button. That is also what §5.9 requires: no explicit action, no
/// server-side effect.
class ScreenshotSearchScreen extends ConsumerStatefulWidget {
  const ScreenshotSearchScreen({
    super.key,
    this.sharedBytes,
    this.initialQuery,
  });

  /// Raw bytes handed over by another app. Null when the buyer opened this
  /// screen from Discover and will pick from the gallery instead.
  final Uint8List? sharedBytes;

  /// Whatever is already typed in the Discover field, sent alongside the
  /// picture so "the red one" still narrows a screenshot search.
  final String? initialQuery;

  @override
  ConsumerState<ScreenshotSearchScreen> createState() =>
      _ScreenshotSearchScreenState();
}

enum _Stage {
  opening,
  confirm,
  searching,
  noMatch,
  notRecognized,
  blocked,
  unavailable,
}

class _ScreenshotSearchScreenState
    extends ConsumerState<ScreenshotSearchScreen> {
  _Stage _stage = _Stage.opening;
  ScreenshotImage? _screenshot;
  SearchInputStatus _blockedStatus = SearchInputStatus.denied;
  String? _blockedDetail;
  String _unavailableMessage = '';
  String? _unavailableDetail;

  /// What vision reported seeing on a recognised-but-unstocked screenshot.
  /// Empty whenever the server did not report features.
  List<String> _recognizedFeatures = const [];

  @override
  void initState() {
    super.initState();
    final shared = widget.sharedBytes;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shared != null) {
        unawaitedIngest(shared);
      } else {
        unawaitedPick();
      }
    });
  }

  @override
  void dispose() {
    // Belt and braces: the search already drops its reference the moment a
    // request returns, and leaving the screen drops it whatever happened.
    _screenshot = null;
    super.dispose();
  }

  void unawaitedPick() => _pick();
  void unawaitedIngest(Uint8List bytes) => _ingest(bytes);

  Future<void> _pick() async {
    setState(() => _stage = _Stage.opening);
    final pick = await ref.read(screenshotPickerProvider)();
    if (!mounted) return;
    switch (pick) {
      case ScreenshotPicked(:final bytes):
        await _ingest(bytes);
      case ScreenshotPickCancelled():
        // Backing out of the chooser means backing out of the search.
        if (mounted && context.canPop()) context.pop();
      case ScreenshotPickBlocked(:final status, :final detail):
        ref
            .read(searchInputCapabilitiesProvider.notifier)
            .reportScreenshot(
              status,
            );
        if (!mounted) return;
        setState(() {
          _blockedStatus = status;
          _blockedDetail = detail;
          _stage = _Stage.blocked;
        });
    }
  }

  Future<void> _ingest(Uint8List bytes) async {
    setState(() => _stage = _Stage.opening);
    try {
      final screenshot = await ref.read(screenshotNormalizerProvider)(bytes);
      if (!mounted) return;
      setState(() {
        _screenshot = screenshot;
        _stage = _Stage.confirm;
      });
    } on ScreenshotDecodeException catch (error) {
      if (!mounted) return;
      setState(() {
        _unavailableMessage = error.message;
        _unavailableDetail = null;
        _stage = _Stage.unavailable;
      });
    }
  }

  Future<void> _search() async {
    final screenshot = _screenshot;
    if (screenshot == null) return;
    setState(() => _stage = _Stage.searching);
    final outcome = await ref
        .read(screenshotSearchProvider)
        .run(screenshot, query: widget.initialQuery);
    // Released as soon as the answer is in, whatever the answer is. The
    // picture has done its job and nothing downstream needs it.
    _screenshot = null;
    if (!mounted) return;
    switch (outcome) {
      case ScreenshotMatches(:final results):
        await context.push(
          '${RouteNames.searchResults}?visual=1',
          extra: results,
        );
        // Back from the results means back to Discover, not to a confirm
        // screen whose picture is already gone.
        if (mounted && context.canPop()) context.pop();
      case ScreenshotNoMatch(:final recognizedFeatures):
        setState(() {
          _recognizedFeatures = recognizedFeatures;
          _stage = _Stage.noMatch;
        });
      case ScreenshotNotRecognized():
        setState(() => _stage = _Stage.notRecognized);
      case ScreenshotSearchUnavailable(:final message, :final detail):
        setState(() {
          _unavailableMessage = message;
          _unavailableDetail = detail;
          _stage = _Stage.unavailable;
        });
    }
  }

  void _typeInstead() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.search);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(
      title: const Text('Search with a screenshot'),
      // A tooltip sets the semantics *tooltip*, not the accessible name, and
      // an icon-only button has no text to fall back on — so the label is
      // explicit, exactly as the voice and barcode buttons do it.
      leading: Semantics(
        button: true,
        label: 'Close screenshot search',
        child: IconButton(
          key: const ValueKey('screenshot-close'),
          tooltip: 'Close screenshot search',
          icon: const Icon(Icons.close_rounded),
          onPressed: _typeInstead,
        ),
      ),
    ),
    body: SafeArea(child: _body()),
  );

  Widget _body() => switch (_stage) {
    _Stage.opening => const _ScreenshotBusy(
      key: ValueKey('screenshot-opening'),
      label: 'Opening your photos',
    ),
    _Stage.searching => const _ScreenshotBusy(
      key: ValueKey('screenshot-searching'),
      label: 'Looking for this in the Mall',
    ),
    _Stage.confirm => _ScreenshotConfirm(
      screenshot: _screenshot!,
      onSearch: _search,
      onChooseAnother: _pick,
    ),
    _Stage.noMatch => ScreenshotNoMatchView(
      recognizedFeatures: _recognizedFeatures,
      onTryAnother: _pick,
      onTypeInstead: _typeInstead,
    ),
    _Stage.notRecognized => ScreenshotNotRecognizedView(
      onTryAnother: _pick,
      onTypeInstead: _typeInstead,
    ),
    _Stage.blocked => SearchInputRecovery(
      kind: SearchInputKind.screenshot,
      status: _blockedStatus,
      detail: _blockedDetail,
      onAskAgain: _pick,
      onOpenSettings: () => ref.read(appSettingsLauncherProvider)(),
      onTypeInstead: _typeInstead,
    ),
    _Stage.unavailable => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MallErrorState(
                key: const ValueKey('screenshot-unavailable'),
                title: 'Screenshot search did not run',
                body: _unavailableMessage,
                detail: _unavailableDetail,
                icon: Icons.image_not_supported_outlined,
                retryLabel: 'Choose another screenshot',
                onRetry: _pick,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: DesignTokens.s24,
                  right: DesignTokens.s24,
                  bottom: DesignTokens.s24,
                ),
                child: TextButton(
                  key: const ValueKey('screenshot-unavailable-type-instead'),
                  onPressed: _typeInstead,
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
    ),
  };
}

class _ScreenshotBusy extends StatelessWidget {
  const _ScreenshotBusy({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // One live region: a screen reader announces the stage once,
          // rather than the spinner and the caption separately.
          Semantics(
            liveRegion: true,
            label: label,
            excludeSemantics: true,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: DesignTokens.s16),
              ],
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 15,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The one screen between a screenshot and the network.
class _ScreenshotConfirm extends StatelessWidget {
  const _ScreenshotConfirm({
    required this.screenshot,
    required this.onSearch,
    required this.onChooseAnother,
  });

  final ScreenshotImage screenshot;
  final VoidCallback onSearch;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.maxHeight - DesignTokens.s16 * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Capped rather than sized to the image, and capped against the
            // screen rather than at a fixed height: on a short handset at a
            // large text scale a 260px preview pushes the Search button and
            // the disclosure below the fold.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: constraints.maxHeight * 0.38,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                child: Semantics(
                  image: true,
                  label:
                      'The screenshot you are about to search with, '
                      '${screenshot.width} by ${screenshot.height} pixels',
                  child: Image.memory(
                    screenshot.bytes,
                    key: const ValueKey('screenshot-preview'),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            const _WhatIsSentNotice(),
            const SizedBox(height: DesignTokens.s16),
            FilledButton.icon(
              key: const ValueKey('screenshot-search'),
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              label: const Text(
                'Search the Mall with this',
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              key: const ValueKey('screenshot-choose-another'),
              onPressed: onChooseAnother,
              child: const Text(
                'Choose a different screenshot',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Said before the upload, in the buyer's words, not in a policy they would
/// have to go and find.
class _WhatIsSentNotice extends StatelessWidget {
  const _WhatIsSentNotice();

  static const String _copy =
      'Only this picture is sent, and only when you tap Search. StyleMint '
      'strips the location and date from it first, and keeps no copy once '
      'the results come back.';

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('screenshot-privacy-notice'),
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreen.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 18,
          color: DesignTokens.primaryGreen,
        ),
        SizedBox(width: DesignTokens.s8),
        // The icon is decoration; the sentence is the whole message, so the
        // row reads as one label rather than "lock, then text".
        Expanded(
          child: Text(
            _copy,
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              height: 1.45,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      ],
    ),
  );
}
