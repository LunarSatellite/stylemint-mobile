import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/data/reel_video_cache.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

typedef ExternalUrlLauncher =
    Future<bool> Function(
      Uri url, {
      LaunchMode mode,
    });

/// Opens a provider permalink in the best available native experience.
///
/// Used by screens outside [ReelPlayer] (e.g. "view on Instagram" actions)
/// that need an explicit external hand-off even for platforms [ReelPlayer]
/// itself plays inline. Provider HTTPS links are intentional: Android App
/// Links and iOS Universal Links hand them to Instagram, TikTok, YouTube, or
/// Facebook when installed, without relying on undocumented,
/// provider-specific URL schemes. If no native handler accepts the link, the
/// same canonical URL opens externally in the browser rather than leaving
/// the tap unresponsive.
class ReelExternalLauncher {
  const ReelExternalLauncher({this.launcher = launchUrl});

  final ExternalUrlLauncher launcher;

  Future<bool> open(Uri permalink) async {
    // Imported reels are canonical provider HTTPS permalinks. Reject anything
    // else before it reaches the operating-system URL resolver.
    if (permalink.scheme != 'https' && permalink.scheme != 'http') {
      return false;
    }
    try {
      final openedNatively = await launcher(
        permalink,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (openedNatively) return true;
    } on Exception {
      // The browser fallback below keeps a valid provider link actionable.
    }

    try {
      return await launcher(permalink, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

/// Lets an ancestor (e.g. a full-screen tap layer) toggle the player's
/// play/pause state without owning the underlying controller.
class ReelPlaybackController {
  VoidCallback? _onToggle;

  /// Toggle play/pause on the attached [ReelPlayer]; no-op if none attached.
  void toggle() => _onToggle?.call();
}

/// Inline video player for a reel. Shared across features (customer feed,
/// creator reel details). Renders the right player for the source platform:
///
/// - **Instagram** → [video_player] using the resolved mp4 URL
///   (refreshed by the BE's `ReelVideoUrlRefreshJob`).
/// - **YouTube** → [youtube_player_flutter] using the platform video ID
///   parsed from the permalink. No API key needed for playback (only for
///   quota-protected metadata).
/// - **TikTok / Facebook** → static thumbnail + a "Watch on {Platform}"]
///   button that opens the reel in the platform's native app via
///   [url_launcher]. The TikTok/Facebook embed surface is too inconsistent
///   across iOS / Android to warrant an in-app WebView.
///
/// Plays when [isActive] is true; pauses when it's false (e.g. a reel
/// scrolled off-screen in the customer feed).
class ReelPlayer extends StatefulWidget {
  const ReelPlayer({
    required this.reel,
    required this.isActive,
    this.playbackController,
    this.externalLauncher = const ReelExternalLauncher(),
    this.autoplay = false,
    super.key,
  });

  /// Media meta extracted from the reel entity. See [ReelMedia].
  final ReelMedia reel;

  /// Whether the reel is currently the visible one in the viewport. Only the
  /// active reel auto-plays; the rest stay paused.
  final bool isActive;

  /// Optional handle so an ancestor can toggle play/pause on tap.
  final ReelPlaybackController? playbackController;

  /// Opens provider permalinks in the native app with a browser fallback.
  /// Injectable so the hand-off behavior can be verified without leaving tests.
  final ReelExternalLauncher externalLauncher;

  /// When true the player auto-starts on first render and (for YouTube)
  /// is created already unmuted so the IFrame autoplay policy does not
  /// silently drop programmatic playVideo() calls. Defaults to false
  /// so callers that host many reels in a scroller (the customer feed)
  /// do not all start streaming at once; the creator reel details screen
  /// sets it to true because there is only ever one reel on screen.
  final bool autoplay;

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> with WidgetsBindingObserver {
  // Direct .mp4 playback (Instagram).
  VideoPlayerController? _controller;
  bool _initialized = false;

  /// True when [_controller] was built from a cached file rather than the
  /// network, so a decode failure can be treated as a bad cache entry.
  bool _playingFromCache = false;
  bool _hasError = false;

  // YouTube playback.
  YoutubePlayerController? _ytController;
  VoidCallback? _ytEndListener;
  bool _ytChromeCssInjected = false;

  /// Flipped to true the instant we begin tearing the YouTube
  /// controller down. Every site that talks to the YT controller
  /// (end listener, value-changed listener, reconcile-playback, and
  /// the CSS-injection helper) checks this before issuing any
  /// call into the inner InAppWebViewController. Without that
  /// guard, async events fired between [_disposeAll] and the
  /// platform actually releasing the WebView can still reach
  /// `evaluateJavascript` / `play` / `pause` and raise
  /// "A AndroidInAppWebViewController was used after being
  /// disposed." on Android.
  bool _ytDisposed = false;

  /// True once the YouTube IFrame WebView reports ready. Until then the
  /// controller drops play()/pause() calls on the floor.
  bool _ytReady = false;

  /// User explicitly tapped to pause. Reset whenever this reel scrolls
  /// off-screen so it auto-plays again next time it becomes active.
  bool _manuallyPaused = false;

  /// False while this tab branch is offscreen (go_router wraps inactive
  /// shell branches in `TickerMode(enabled: false)`).
  bool _tabVisible = true;
  bool _appResumed = true;

  bool get _shouldPlay =>
      widget.isActive && _tabVisible && !_manuallyPaused && _appResumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.playbackController?._onToggle = _togglePlayPause;
    _initForPlatform();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _tabVisible) {
      _tabVisible = visible;
      _reconcilePlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed != _appResumed) {
      _appResumed = resumed;
      _reconcilePlayback();
    }
  }

  @override
  void didUpdateWidget(ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playbackController != widget.playbackController) {
      if (oldWidget.playbackController?._onToggle == _togglePlayPause) {
        oldWidget.playbackController?._onToggle = null;
      }
      widget.playbackController?._onToggle = _togglePlayPause;
    }

    if (oldWidget.reel.permalink != widget.reel.permalink ||
        oldWidget.reel.videoUrl != widget.reel.videoUrl ||
        oldWidget.reel.platform != widget.reel.platform) {
      _disposeAll();
      _initForPlatform();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) _manuallyPaused = false;

      // A reel that was only prefetching as a neighbour has no controller
      // yet; build one now that it is the reel on screen. By this point the
      // prefetch has usually landed, so this is a cache hit and starts
      // without touching the network.
      final platform = widget.reel.platform ?? SocialPlatform.instagram;
      if (widget.isActive &&
          platform == SocialPlatform.instagram &&
          _controller == null &&
          !_hasError) {
        unawaited(_initInstagramVideo());
      }
      // YouTube: initialize when this reel becomes active
      if (widget.isActive &&
          platform == SocialPlatform.youtube &&
          _ytController == null) {
        _initYouTube();
      }

      _reconcilePlayback();
    }
  }

  void _initForPlatform() {
    final platform = widget.reel.platform ?? SocialPlatform.instagram;
    switch (platform) {
      case SocialPlatform.instagram:
        // Only the reel actually on screen gets an ExoPlayer. The PageView
        // keeps both neighbours alive (allowImplicitScrolling), and three
        // simultaneous initialise() calls split the connection three ways —
        // starving the one the user is looking at. Neighbours warm the disk
        // cache instead, which is both cheaper and what makes the next swipe
        // start instantly.
        if (widget.isActive) {
          unawaited(_initInstagramVideo());
        } else {
          unawaited(_prefetchInstagramVideo());
        }
      case SocialPlatform.youtube:
        _initYouTube();
        break;
      case SocialPlatform.tiktok:
      case SocialPlatform.facebook:
        // No in-app player; thumbnail + open-in-app button.
        break;
    }
  }

  /// Stable cache key for this reel's video.
  ///
  /// Deliberately the permalink and not [ReelMedia.videoUrl]: the Instagram
  /// CDN URL is rotated by the backend's refresh job, so keying on it would
  /// miss after every rotation and re-download a file we already hold.
  String get _videoCacheKey {
    final permalink = widget.reel.permalink;
    return permalink.isNotEmpty ? permalink : (widget.reel.videoUrl ?? '');
  }

  Future<void> _prefetchInstagramVideo() async {
    final url = widget.reel.videoUrl;
    if (url == null || url.isEmpty) return;
    await ReelVideoCache.instance.prefetch(cacheKey: _videoCacheKey, url: url);
  }

  Future<void> _initInstagramVideo() async {
    final url = widget.reel.videoUrl;
    if (url == null || url.isEmpty) return;

    // Cache hit plays from disk: no network, no rebuffering, and it works
    // offline. A miss streams straight from the network rather than waiting
    // for a full download, so first view is never slower than before.
    final cached = await ReelVideoCache.instance.peek(_videoCacheKey);
    if (!mounted) return;

    try {
      final controller = cached != null
          ? VideoPlayerController.file(cached)
          : VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      _playingFromCache = cached != null;

      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      if (!mounted) return;

      setState(() => _initialized = true);

      // Reconcile now (controller ready) and again on the next frame so
      // _tabVisible / _appResumed have settled before we decide to play.
      _reconcilePlayback();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reconcilePlayback();
      });
    } on Exception catch (_) {
      // A cached file that will not open is a truncated or corrupt download.
      // Drop it and retry once over the network so one bad entry cannot
      // wedge the reel permanently.
      if (_playingFromCache) {
        await ReelVideoCache.instance.evict(_videoCacheKey);
        if (!mounted) return;
        _playingFromCache = false;
        unawaited(_controller?.dispose() ?? Future<void>.value());
        _controller = null;
        await _initInstagramVideoFromNetwork(url);
        return;
      }
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _initInstagramVideoFromNetwork(String url) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      if (!mounted) return;
      setState(() => _initialized = true);
      _reconcilePlayback();
    } on Exception catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _initYouTube() {
    final videoId = widget.reel.platformVideoId;
    if (videoId == null || videoId.isEmpty) return;
    // A fresh WebView is being built; clear the disposed guard so
    // listeners / injections that are already in flight (from the
    // previous lifecycle) cannot touch it.
    _ytDisposed = false;

    // When the caller asked for autoplay we hand a non-const flags block
    // to the controller so the IFrame Player comes up already muted +
    // playing. Mobile WebView autoplay policies (both Android Chromium
    // and WKWebView) silently reject programmatic playVideo() on an
    // unmuted iframe without a user gesture; starting muted is the
    // supported way to satisfy the policy. For the multi-reel customer
    // feed we keep autoPlay=false (default) so adjacent offscreen reels
    // don't all start streaming simultaneously and choke bandwidth.
    final ytAutoplay = widget.autoplay;
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: ytAutoplay,
        // Start muted when autoplaying so the IFrame autoplay policy is
        // satisfied. Once the controller reports ready, _onYouTubeValueChanged
        // unmutes (best-effort — WebView may still keep it muted until
        // the first user gesture).
        mute: ytAutoplay,
        // Disable IFrame loop:1 — it forces a network re-fetch at the end
        // of every loop (loop:1 seeks back to 0 and re-buffers), which is
        // the visible load-then-load-again on YouTube reels. We replay via
        // a controller listener on PlayerState.ended instead.
        loop: false,
        disableDragSeek: false,
        enableCaption: false,
      ),
    );
    // Listen only to inject the YT-chrome-hiding CSS once the IFrame
    // comes up. We do NOT loop from this listener: while the IFrame is
    // processing our own seekTo/play() calls during PlayerState.ended,
    // the controller re-fires `value` changes for every intermediate
    // state, so a listener-driven loop would spam the IFrame with
    // back-to-back seek + play requests. The YoutubePlayer widget's
    // `onEnded` callback fires exactly once per ended event, so the
    // manual loop lives there instead (see _buildYouTubeLayer).
    _ytEndListener = () {
      final yt = _ytController;
      if (yt == null || !mounted || _ytDisposed) return;
      // 1) Pre-loop: keep the IFrame buffer warm by seeking back to 0
      // BEFORE PlayerState.ended fires. The YT IFrame clears its
      // forward buffer at video end, so seekTo(0)+play after ENDED
      // always re-fetches the start of the video -- the visible
      // "loading again" between loops. By seeking back when we are
      // within 3 s of the end, we never reach ENDED and the buffer
      // we already have stays usable; the user sees a clean rewind
      // rather than a buffer spinner.
      if (yt.value.playerState == PlayerState.playing) {
        final durationSec = yt.value.metaData.duration.inSeconds;
        if (durationSec > 3) {
          final positionSec = yt.value.position.inMilliseconds / 1000.0;
          if (positionSec > durationSec - 3) {
            yt.seekTo(Duration.zero);
            return;
          }
        }
      }
      // 2) One-shot CSS injection (same-origin iframe once the URL
      // has been swapped to youtube-nocookie.com).
      if (_ytChromeCssInjected) return;
      final wc = yt.value.webViewController;
      if (wc == null) return;
      _ytChromeCssInjected = true;
      unawaited(_injectYouTubeOverlayHidingCss(wc));
    };
    _ytController!.addListener(_ytEndListener!);
    // Reconcile after init so autoplay flags and mute state are applied.
    _reconcilePlayback();
  }

  /// Hides YouTube's own UI overlays (title bar, channel strip,
  /// Share/Comment/Like buttons, the "YouTube Shorts" brand tag,
  /// watermark, pause-overlay logo, etc.) inside the inner IFrame's
  /// contentDocument. The YT.Player API opens its video inside an inner
  /// iframe, so styling the outer document is not enough -- we have to
  /// walk into the inner document once the player has rendered it.
  /// Retries for ~6 s so we do not race the YT IFrame API on a slow first
  /// paint.
  Future<void> _injectYouTubeOverlayHidingCss(
    InAppWebViewController webController,
  ) async {
    // The listener may have queued this call against a controller
    // that has since been torn down (permalinks changed, widget
    // disposed, user scrolled away mid-loop). The
    // InAppWebViewController synchronously throws
    // "A AndroidInAppWebViewController was used after being
    // disposed." on Android, and the throw is not always catchable
    // by the try/catch around evaluateJavascript because the
    // platform side rejects the call before it is dispatched.
    if (_ytDisposed) return;
    final css = <String>[
      // Top/bottom chrome + title overlays.
      '.ytp-chrome-top, .ytp-chrome-bottom, .ytp-chrome,',
      '.ytp-title, .ytp-title-text, .ytp-title-link, .ytp-title-channel, .ytp-title-wrap,',
      '.ytp-watermark, .ytp-pause-overlay, .ytp-show-cards-title,',
      '.ytp-cards-button, .ytp-endscreen, .ytp-suggestion-set,',
      '.ytp-ce-element-show, .ytp-remote-control,',
      '.ytp-right-controls, .ytp-left-controls,',
      '.caption-window, .ytp-caption-window-container,',
      '.iv-cards, .iv-promo,',
      // YouTube Shorts UI elements (channel badge, "Shorts" label,
      // recommendation lockup, custom control bar). YouTube's embed
      // for Shorts videos injects several different class names.
      '.ShortsLockupViewModelHost, .shortsPlayerCustomControls,',
      '.ShortsBadgeViewModel, .ShortsBrandViewModel,',
      '.ShortsInfoPanelViewModel, .ShortsPlayerCardViewModel,',
      '.shortsBrand, .ShortsBrand, .shortsdialog,',
      '.html5-shorts-info-panel, .ytp-shorts-title, .ytp-shorts-channel,',
      '.ytp-shortsinformationpanel, .ytp-shorts-info-panel,',
      '.ytp-youtube-button, .ytp-large-play-button,',
      // Catch-all: hide anything with "shorts"/"Shorts" in its class or
      // id. This catches dynamic class names YouTube uses for the text
      // overlay that appears in the middle of the player (e.g. the
      // Shorts label, channel name, brand badge).
      '[class*="shorts" i], [class*="Shorts" i],',
      '[id*="shorts" i], [class*="ShortsBadge" i],',
      '.html5-video-player .ytp-overlay > *,',
      '.html5-video-player .caption-window,',
      // Mute the Shorts-text element via a more specific selector too:
      // just in case YouTube puts the text in a generic container.
      '.html5-video-player .ytp-shorts-info-panel,',
      // Belt-and-braces: collapse any element whose direct text says
      // "Shorts" / "YouTube Shorts" so the middle-of-reel text never
      // lingers even if YouTube re-injects a node with an unknown
      // class on the next paint.
      '.ytp-shorts-overlay, .ytp-shorts-brand, .ytp-shorts-channel-name,',
      '{ display: none !important; visibility: hidden !important; }',
    ].join('\n');
    // The CSS targets the obvious YT / Shorts chrome selectors, but
    // YouTube also injects new Shorts-text elements dynamically (channel
    // name, "Shorts" label, lockups) AFTER the first paint. The
    // MutationObserver below keeps stripping them as they appear so the
    // middle-of-reel Shorts text can never linger.
    //     // Cross-origin was blocking the CSS injection. The
    // youtube_player_flutter package serves this outer page from the
    // baseUrl youtube-nocookie.com, but YT.Player embeds the inner
    // iframe at www.youtube.com. Those are different origins, so from
    // here we cannot reach iframe.contentDocument - it returned null
    // and our <style> block never landed. This script swaps the
    // iframe URL to youtube-nocookie.com (same-origin) so the
    // existing CSS / MutationObserver path actually runs. YT.Player
    // command channel uses postMessage (cross-origin-safe), so
    // play/pause/seek keep working across the URL swap.
    const jsTemplate = r'''
(function() {
  function getIframe() {
    var el = document.getElementById("player");
    if (el && el.tagName === "IFRAME" && el.src) return el;
    return null;
  }
  function swapToSameOrigin() {
    var f = getIframe();
    if (!f) return false;
    var src = f.src;
    if (src.indexOf("youtube-nocookie") !== -1) return true;
    if (src.indexOf("www.youtube.com") === -1) return false;
    f.src = src.replace(/www\.youtube\.com/g, "www.youtube-nocookie.com");
    return true;
  }
  var swapTries = 0;
  var swapTimer = setInterval(function () {
    if (swapToSameOrigin() || ++swapTries > 40) {
      clearInterval(swapTimer);
      setTimeout(phase2Inject, 1200);
    }
  }, 250);
  function phase2Inject() {
    var cssTries = 0;
    var cssTimer = setInterval(function () {
      var f = getIframe();
      if (!f) return;
      var doc = null;
      try { doc = f.contentDocument; } catch (e) { return; }
      if (!doc || !doc.head) return;
      if (!doc.head.querySelector("#sm-hide-yt-chrome")) {
        var s = doc.createElement("style");
        s.id = "sm-hide-yt-chrome";
        s.textContent = "$css";
        doc.head.appendChild(s);
      }
      // One-shot pass on entry, then a long-lived observer that keeps
      // stripping anything YouTube re-injects. The previous build
      // disconnected after 30 s; YouTube keeps mutating the DOM long
      // after that (channel name strip, lockup list, mid-reel
      // re-injection), so we keep watching for 5 minutes and re-attach
      // if the document is replaced.
      killShorts(doc);
      try {
        var obs = new MutationObserver(function () { killShorts(doc); });
        obs.observe(doc.documentElement || doc.body, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ["class", "id"],
        });
        // Re-attach every 60 s in case the iframe document is replaced.
        var keepAlive = setInterval(function () {
          try {
            var f2 = getIframe();
            if (!f2) { clearInterval(keepAlive); return; }
            var d2 = null;
            try { d2 = f2.contentDocument; } catch (e) { return; }
            if (!d2) return;
            if (!d2.head || !d2.head.querySelector("#sm-hide-yt-chrome")) {
              var s2 = d2.createElement("style");
              s2.id = "sm-hide-yt-chrome";
              s2.textContent = "$css";
              if (d2.head) d2.head.appendChild(s2);
            }
            try { obs.disconnect(); } catch (e) {}
            try {
              obs.observe(d2.documentElement || d2.body, {
                childList: true,
                subtree: true,
                attributes: true,
                attributeFilter: ["class", "id"],
              });
            } catch (e) {}
            killShorts(d2);
          } catch (e) {}
        }, 60000);
        setTimeout(function () {
          try { obs.disconnect(); } catch (e) {}
          try { clearInterval(keepAlive); } catch (e) {}
        }, 300000);
      } catch (e) {}
      clearInterval(cssTimer);
    }, 250);
  }
  function isPlayerRoot(el, doc) {
    if (!el) return true;
    if (el === doc.documentElement || el === doc.body) return true;
    if (el.id === "player") return true;
    if (el.tagName === "VIDEO") return true;
    if (el.tagName === "IFRAME") return true;
    return false;
  }
  function killShorts(doc) {
    if (!doc || !doc.querySelectorAll) return;
    // 1) Class/id-based killing: collect matches first, then remove
    // them. node.remove() takes them out of the layout entirely so
    // YouTube's later re-injection is the only way they can come
    // back - and the MutationObserver below kills those too.
    var classMatches = doc.querySelectorAll(
      '[class*="shorts" i], [class*="Shorts" i],' +
      ' [id*="shorts" i], [class*="ShortsBadge" i],' +
      ' .ShortsLockupViewModelHost, .shortsPlayerCustomControls,' +
      ' .ShortsBadgeViewModel, .ShortsBrandViewModel,' +
      ' .ShortsInfoPanelViewModel, .ShortsPlayerCardViewModel,' +
      ' .ytp-shorts-title, .ytp-shorts-channel,' +
      ' .ytp-shorts-overlay, .ytp-shorts-brand,' +
      ' .ytp-shorts-channel-name'
    );
    for (var i = 0; i < classMatches.length; i++) {
      removeIfInsidePlayer(classMatches[i], doc);
    }
    // 2) Text-content killing: walk every text node in the iframe body
    // and remove the nearest element whose own visible text contains
    // "Shorts" - covers overlay nodes whose class names YouTube
    // obfuscates.
    try {
      var walker = doc.createTreeWalker(doc.body, NodeFilter.SHOW_TEXT, null);
      var textNode;
      while ((textNode = walker.nextNode()) != null) {
        var raw = textNode.nodeValue || "";
        var t = raw.replace(/[\s\u00A0]+/g, " ").trim();
        if (!t) continue;
        if (!/\bshorts?\b/i.test(t)) continue;
        // Walk up to the smallest container whose own textContent still
        // matches /shorts/i - that's the overlay node YouTube
        // injected, not its ancestors.
        var el = textNode.parentElement;
        var safety = 0;
        while (el && safety++ < 10) {
          if (isPlayerRoot(el, doc)) break;
          if (el.children && el.children.length > 3) break;
          var own = (el.textContent || "").replace(/[\s\u00A0]+/g, " ").trim();
          if (/\bshorts?\b/i.test(own) && el.children.length <= 3) {
            removeIfInsidePlayer(el, doc);
            break;
          }
          el = el.parentElement;
        }
      }
    } catch (e) {}
    // 3) Strip SVG <text> nodes that say "Shorts" (channel-name /
    // brand labels occasionally live inside inline SVG).
    try {
      var svgs = doc.querySelectorAll("svg");
      for (var i = 0; i < svgs.length; i++) {
        var svg = svgs[i];
        if (svg.closest && svg.closest("video")) continue;
        var tnodes = svg.querySelectorAll("text");
        for (var j = 0; j < tnodes.length; j++) {
          var v = (tnodes[j].textContent || "").trim();
          if (/shorts/i.test(v)) removeIfInsidePlayer(tnodes[j], doc);
        }
      }
    } catch (e) {}
  }
  function removeIfInsidePlayer(el, doc) {
    if (!el || !el.parentNode) return;
    if (isPlayerRoot(el, doc)) return;
    if (el.closest && el.closest("video")) return;
    if (el.tagName === "VIDEO") return;
    try { el.parentNode.removeChild(el); } catch (e) {}
  }
})()

''';
    final js = jsTemplate.replaceFirst(r'$css', css);
    try {
      await webController.evaluateJavascript(source: js);
    } catch (_) {
      _ytChromeCssInjected = false;
    }
  }

  /// The IFrame player silently drops play()/pause() until its WebView
  /// reports ready, so the reconcile that runs at init time is always a
  /// no-op. Re-run it on the ready transition to apply the state the reel
  /// should actually be in by then.
  void _onYouTubeValueChanged() {
    if (_ytDisposed) return;
    final ready = _ytController?.value.isReady ?? false;
    if (ready == _ytReady) return;
    _ytReady = ready;
    if (ready) {
      // If the caller opted into autoplay we started the IFrame muted
      // so the autoplay policy would accept it. Try to bring audio back
      // once the player reports ready. The WebView may still ignore
      // this until the first user gesture — that is expected and the
      // tap-to-toggle behaviour already covers it.
      if (widget.autoplay) {
        _ytController?.unMute();
      }
      _reconcilePlayback();
    }
  }

  void _reconcilePlayback() {
    if (_ytDisposed) {
      if (_controller != null && _initialized && _controller!.value.isPlaying) {
        unawaited(_controller!.pause());
      }
      return;
    }
    if (!_shouldPlay) {
      if (_controller != null && _initialized && _controller!.value.isPlaying) {
        unawaited(_controller!.pause());
      }
      if (_ytReady && _ytController != null && _ytController!.value.isPlaying) {
        _ytController!.pause();
      }
      return;
    }

    if (_controller != null && _initialized && !_controller!.value.isPlaying) {
      unawaited(_controller!.play());
    }
    if (_ytReady && _ytController != null && !_ytController!.value.isPlaying) {
      _ytController!.play();
    }
  }

  void _disposeAll() {
    final c = _controller;
    _controller = null;
    _initialized = false;
    _playingFromCache = false;
    _hasError = false;
    unawaited(c?.dispose() ?? Future<void>.value());

    final yt = _ytController;
    // Flip the disposed guard BEFORE we null the controller or call
    // yt.dispose(). Any in-flight listener / async JS evaluation
    // captured a reference to the same `yt` and would otherwise
    // race with the platform tearing the inner WebView down.
    _ytDisposed = true;
    _ytController = null;
    final listener = _ytEndListener;
    _ytEndListener = null;
    _ytChromeCssInjected = false;
    if (yt != null) {
      if (listener != null) yt.removeListener(listener);
      yt.removeListener(_onYouTubeValueChanged);
      yt.dispose();
    }
    _ytReady = false;
  }

  @override
  void dispose() {
    if (widget.playbackController?._onToggle == _togglePlayPause) {
      widget.playbackController?._onToggle = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _disposeAll();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() => _manuallyPaused = !_manuallyPaused);
    _reconcilePlayback();
  }

  Future<void> _openExternally() async {
    final permalink = Uri.tryParse(widget.reel.permalink);
    if (permalink == null) return;
    await widget.externalLauncher.open(permalink);
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.reel.platform ?? SocialPlatform.instagram;

    switch (platform) {
      case SocialPlatform.instagram:
        return _buildInstagramLayer();
      case SocialPlatform.youtube:
        return _buildYouTubeLayer();
      case SocialPlatform.tiktok:
      case SocialPlatform.facebook:
        return _buildExternalLayer(platform);
    }
  }

  Widget _buildInstagramLayer() {
    final hasVideo = (widget.reel.videoUrl ?? '').isNotEmpty;

    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized && _controller != null)
            FittedBox(
              fit: _controller!.value.aspectRatio < 1
                  ? BoxFit.cover
                  : BoxFit.contain,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if ((widget.reel.thumbnailUrl ?? '').isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.reel.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: DesignTokens.bgAppBodyLight),
              errorWidget: (_, _, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),

          if (hasVideo && !_initialized && !_hasError)
            const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
                strokeWidth: 2,
              ),
            ),

          if (_manuallyPaused && _initialized)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.baseBlack.withValues(alpha: 0.45),
                ),
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: DesignTokens.iconLarge,
                  color: DesignTokens.iconWhite,
                ),
              ),
            ),

          if (!hasVideo || _hasError)
            Center(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.baseBlack.withValues(alpha: 0.35),
                ),
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: DesignTokens.iconLarge,
                  color: DesignTokens.iconWhite,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildYouTubeLayer() {
    final controller = _ytController;
    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            // The IFrame player is a native WebView (a platform view), which
            // can claim touches at the OS level before Flutter's gesture
            // arena resolves them — swallowing the vertical swipe the
            // feed's PageView needs to advance to the next reel. Playback is
            // driven entirely by [controller] (autoplay/pause/loop), so the
            // WebView never needs to receive touches itself; ignoring
            // pointers here lets them fall through to the tap-to-toggle and
            // PageView gesture detectors above/around this widget.
            IgnorePointer(
              child: YoutubePlayer(
                controller: controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: DesignTokens.primaryGreen,
                progressColors: ProgressBarColors(
                  playedColor: DesignTokens.primaryGreen,
                  handleColor: DesignTokens.primaryGreen,
                ),
              ),
            )
          else if ((widget.reel.thumbnailUrl ?? '').isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.reel.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: DesignTokens.bgAppBodyLight),
              errorWidget: (_, _, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExternalLayer(SocialPlatform platform) {
    return Semantics(
      button: true,
      label: 'Open reel on ${platform.displayName}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openExternally,
        child: ColoredBox(
          color: DesignTokens.baseBlack,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if ((widget.reel.thumbnailUrl ?? '').isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.reel.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: DesignTokens.bgAppBodyLight),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: DesignTokens.bgAppBodyLight,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: DesignTokens.iconLight,
                    ),
                  ),
                ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.baseBlack.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.all(DesignTokens.s16),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: DesignTokens.iconLarge,
                        color: DesignTokens.iconWhite,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    TextButton.icon(
                      onPressed: _openExternally,
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 18,
                        color: DesignTokens.iconWhite,
                      ),
                      label: Text(
                        'Watch on ${platform.displayName}',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.iconWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
