import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Builds the [ImageProvider] for one avatar URL.
typedef AvatarImageProviderBuilder = ImageProvider<Object> Function(String url);

/// Circular creator avatar that rotates through the profile pictures of the
/// creator's connected platforms (Instagram, TikTok, YouTube, Facebook).
///
/// * Two or more pictures: each stays up for [interval], then spins around
///   the Y axis to reveal the next one, looping. The next picture is
///   precached before the spin starts, and a picture that fails to load is
///   dropped from the rotation.
/// * One picture: a static avatar.
/// * No pictures: [fallback] (a person icon by default).
///
/// With reduced motion ([MediaQuery.disableAnimationsOf]) the spin becomes a
/// cross-fade. Rotation pauses while tickers are muted ([TickerMode], e.g. an
/// inactive tab or a covered route) and while the app is not in the
/// foreground.
class PlatformAvatarCarousel extends StatefulWidget {
  const PlatformAvatarCarousel({
    required this.imageUrls,
    required this.size,
    this.fallback,
    this.backgroundColor = DesignTokens.bgAppBodyLight,
    this.interval = const Duration(milliseconds: 2500),
    this.transitionDuration = const Duration(milliseconds: 600),
    this.imageProviderBuilder,
    this.semanticLabel,
    super.key,
  });

  /// Picture URLs in rotation order. Blank entries and duplicates are
  /// ignored.
  final List<String> imageUrls;

  /// Avatar diameter.
  final double size;

  /// Shown when there is no picture, or when a picture fails to load. It is
  /// clipped to a circle of [size].
  final Widget? fallback;

  /// Fill behind pictures and behind the default fallback icon.
  final Color backgroundColor;

  /// How long each picture stays up before moving to the next one.
  final Duration interval;

  /// Length of the spin. The reduced-motion cross-fade takes half as long.
  final Duration transitionDuration;

  /// Builds the provider for a URL. Defaults to [CachedNetworkImageProvider].
  final AvatarImageProviderBuilder? imageProviderBuilder;

  /// Accessibility label for the avatar.
  final String? semanticLabel;

  /// The platform pictures when there are any, otherwise [fallbackUrl] (a
  /// single legacy avatar URL) so payloads without platform pictures still
  /// show one.
  static List<String> resolveUrls(
    List<String> platformUrls, [
    String? fallbackUrl,
  ]) {
    final urls = normalizeUrls(platformUrls);
    if (urls.isNotEmpty) return urls;
    final single = fallbackUrl?.trim() ?? '';
    return single.isEmpty ? const <String>[] : <String>[single];
  }

  /// Trims, drops blanks and removes duplicates, keeping the first
  /// occurrence's position.
  static List<String> normalizeUrls(List<String> urls) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in urls) {
      final url = raw.trim();
      if (url.isNotEmpty && seen.add(url)) result.add(url);
    }
    return result;
  }

  @override
  State<PlatformAvatarCarousel> createState() => _PlatformAvatarCarouselState();
}

class _PlatformAvatarCarouselState extends State<PlatformAvatarCarousel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _transition;

  /// Normalized [PlatformAvatarCarousel.imageUrls], used to detect changes.
  late List<String> _sourceUrls;

  /// The rotation: [_sourceUrls] minus pictures that failed to load.
  late List<String> _urls;

  int _current = 0;
  int? _next;
  bool _nextReady = false;
  bool _holdElapsed = false;
  Timer? _holdTimer;

  /// Bumped whenever an in-flight precache result should be ignored.
  int _precacheGeneration = 0;

  bool _tickersEnabled = true;
  bool _reduceMotion = false;
  bool _appInForeground = true;

  bool get _canRotate =>
      _urls.length > 1 && _tickersEnabled && _appInForeground;

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(
      vsync: this,
      duration: widget.transitionDuration,
    )..addStatusListener(_onTransitionStatus);
    _sourceUrls = PlatformAvatarCarousel.normalizeUrls(widget.imageUrls);
    _urls = List.of(_sourceUrls);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appInForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncCycle();
  }

  @override
  void didUpdateWidget(covariant PlatformAvatarCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urls = PlatformAvatarCarousel.normalizeUrls(widget.imageUrls);
    if (listEquals(urls, _sourceUrls)) return;

    final shown = _urls.isEmpty ? null : _urls[_current];
    _stopCycle();
    _sourceUrls = urls;
    _urls = List.of(urls);
    _current = shown == null ? 0 : math.max(0, _urls.indexOf(shown));
    _syncCycle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    _syncCycle();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdTimer?.cancel();
    _precacheGeneration++;
    _transition.dispose();
    super.dispose();
  }

  ImageProvider<Object> _provider(String url) =>
      widget.imageProviderBuilder?.call(url) ?? CachedNetworkImageProvider(url);

  /// Starts, resumes or pauses the rotation to match current conditions.
  void _syncCycle() {
    if (!_canRotate) {
      _holdTimer?.cancel();
      _holdTimer = null;
      return;
    }
    // A muted ticker pauses an in-flight transition by itself.
    if (_transition.isAnimating) return;
    if (_holdElapsed) {
      if (_nextReady) _startTransition();
      return;
    }
    if (_holdTimer != null) return;
    _prepareNext();
    _holdTimer = Timer(widget.interval, _onHoldElapsed);
  }

  void _stopCycle() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _precacheGeneration++;
    _next = null;
    _nextReady = false;
    _holdElapsed = false;
    if (_transition.isAnimating || _transition.value != 0) {
      _transition
        ..stop()
        ..value = 0;
    }
  }

  /// Picks the next picture and precaches it; the transition waits for it.
  void _prepareNext() {
    if (_urls.length < 2) {
      _next = null;
      _nextReady = false;
      return;
    }
    final next = (_current + 1) % _urls.length;
    final url = _urls[next];
    final generation = ++_precacheGeneration;
    _next = next;
    _nextReady = false;
    var failed = false;
    unawaited(
      precacheImage(
        _provider(url),
        context,
        onError: (_, _) {
          failed = true;
        },
      ).then((_) {
        if (!mounted || generation != _precacheGeneration) return;
        if (failed) {
          _dropUrl(url);
        } else {
          _nextReady = true;
          if (_holdElapsed) _syncCycle();
        }
      }),
    );
  }

  void _dropUrl(String url) {
    final index = _urls.indexOf(url);
    if (index < 0) return;
    final shown = _urls[_current];
    setState(() {
      _urls = List.of(_urls)..removeAt(index);
      _current = math.max(0, _urls.indexOf(shown));
    });
    if (_urls.length < 2) {
      _stopCycle();
      return;
    }
    _prepareNext();
  }

  void _onHoldElapsed() {
    _holdTimer = null;
    _holdElapsed = true;
    _syncCycle();
  }

  void _startTransition() {
    _transition.duration = _reduceMotion
        ? widget.transitionDuration ~/ 2
        : widget.transitionDuration;
    unawaited(_transition.forward(from: 0));
  }

  void _onTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final next = _next;
    setState(() {
      if (next != null && next < _urls.length) _current = next;
      _next = null;
      _nextReady = false;
      _holdElapsed = false;
    });
    _transition.value = 0;
    _syncCycle();
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_urls.isEmpty) {
      content = _fallback();
    } else if (_urls.length == 1) {
      content = _face(_urls.first);
    } else {
      content = AnimatedBuilder(
        animation: _transition,
        builder: (context, _) => _rotatingFace(),
      );
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      child: SizedBox.square(dimension: widget.size, child: content),
    );
  }

  Widget _rotatingFace() {
    final current = _urls[math.min(_current, _urls.length - 1)];
    final nextIndex = _next;
    final progress = _transition.value;
    if (nextIndex == null || nextIndex >= _urls.length || progress == 0) {
      return _face(current);
    }
    final next = _urls[nextIndex];

    if (_reduceMotion) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(opacity: 1 - progress, child: _face(current)),
          Opacity(opacity: progress, child: _face(next)),
        ],
      );
    }

    // Front face turns away for the first half; the next picture turns in
    // from the other edge for the second half, so it never shows mirrored.
    final angle = Curves.easeInOut.transform(progress) * math.pi;
    final pastEdge = angle > math.pi / 2;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0015)
        ..rotateY(pastEdge ? angle - math.pi : angle),
      child: _face(pastEdge ? next : current),
    );
  }

  Widget _face(String url) => ClipOval(
    child: ColoredBox(
      color: widget.backgroundColor,
      child: Image(
        image: _provider(url),
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    ),
  );

  Widget _fallback() => ClipOval(
    child: SizedBox.square(
      dimension: widget.size,
      child:
          widget.fallback ??
          ColoredBox(
            color: widget.backgroundColor,
            child: Icon(
              Icons.person,
              size: widget.size * 0.6,
              color: DesignTokens.iconLight,
            ),
          ),
    ),
  );
}
