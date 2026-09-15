import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_host_html.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_navigation_policy.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';

/// The WebView behind an [EmbedSlot].
///
/// It never takes touches: the reel page above it owns taps and swipes, and
/// playback is driven through the slot. It never opens a window, and every
/// navigation goes through [EmbedNavigationPolicy], so a player cannot take
/// the viewer to the platform's site or app.
class EmbedSlotView extends StatefulWidget {
  const EmbedSlotView({required this.slot, super.key});

  final EmbedSlot slot;

  /// The WebView's settings.
  @visibleForTesting
  static InAppWebViewSettings buildSettings() => InAppWebViewSettings(
    javaScriptEnabled: true,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    allowsPictureInPictureMediaPlayback: false,
    allowsAirPlayForMediaPlayback: false,
    transparentBackground: true,
    useHybridComposition: true,
    thirdPartyCookiesEnabled: true,
    domStorageEnabled: true,
    databaseEnabled: true,
    disableContextMenu: true,
    supportZoom: false,
    disableHorizontalScroll: true,
    disableVerticalScroll: true,
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    // No redirects out of StyleMint: navigations are vetted, pop-ups are off.
    // The pop-up flags are the defaults, spelled out so they never drift.
    useShouldOverrideUrlLoading: true,
    // ignore: avoid_redundant_argument_values
    supportMultipleWindows: false,
    // ignore: avoid_redundant_argument_values
    javaScriptCanOpenWindowsAutomatically: false,
  );

  @override
  State<EmbedSlotView> createState() => _EmbedSlotViewState();
}

class _EmbedSlotViewState extends State<EmbedSlotView>
    implements EmbedSlotDriver {
  InAppWebViewController? _controller;

  late final InAppWebViewSettings _settings = EmbedSlotView.buildSettings();

  @override
  Future<void> loadHost(String origin) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.loadData(
      data: embedHostHtml(origin: origin),
      baseUrl: WebUri('$origin/'),
      mimeType: 'text/html',
      encoding: 'utf-8',
    );
  }

  @override
  Future<void> runJavaScript(String source) async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.evaluateJavascript(source: source);
    } on Object {
      // The page or view went away mid-call. A dead renderer is reported
      // separately and the slot reloads its reel then.
    }
  }

  @override
  void didUpdateWidget(EmbedSlotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.slot, widget.slot)) return;
    oldWidget.slot.detach(this);
    if (_controller != null) widget.slot.attach(this);
  }

  @override
  void dispose() {
    widget.slot.detach(this);
    _controller = null;
    super.dispose();
  }

  void _onRendererGone() {
    _controller = null;
    widget.slot.rendererGone();
  }

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = Uri.tryParse(action.request.url?.toString() ?? '');
    if (url == null) return NavigationActionPolicy.CANCEL;
    // iOS asks with no target frame when a page wants a new window; treat
    // that like a top-level load. Android never sends a target frame.
    final newWindow =
        defaultTargetPlatform == TargetPlatform.iOS &&
        action.targetFrame == null;
    final allowed = EmbedNavigationPolicy.allows(
      url,
      isTopLevel: action.isForMainFrame || newWindow,
      hostOrigin: widget.slot.hostOrigin,
    );
    return allowed
        ? NavigationActionPolicy.ALLOW
        : NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: InAppWebView(
        initialSettings: _settings,
        onWebViewCreated: (controller) {
          _controller = controller;
          controller.addJavaScriptHandler(
            handlerName: 'sm',
            callback: (args) {
              final event = args.isEmpty ? null : args.first;
              if (event is Map) {
                widget.slot.handleEvent(Map<String, dynamic>.from(event));
              }
              return null;
            },
          );
          widget.slot.attach(this);
        },
        shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
        // Windows are never honoured. Pop-ups are off, and on iOS an
        // unhandled request falls back to a load in this view, which
        // [EmbedNavigationPolicy] then cancels.
        onCreateWindow: (controller, action) async => false,
        onLoadStop: (controller, url) =>
            widget.slot.hostLoaded(url?.toString()),
        onRenderProcessGone: (controller, detail) => _onRendererGone(),
        onWebContentProcessDidTerminate: (controller) => _onRendererGone(),
      ),
    );
  }
}
