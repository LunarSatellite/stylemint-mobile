import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_thumbnail_plus/flutter_video_thumbnail_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_feed_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_search_field.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_suggestions_panel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/search_input_actions.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:video_player/video_player.dart';

/// The Discover tab: a search box with live suggestions over a chip-driven,
/// curated feed. Submitting opens `/search-results`.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  static const ValueKey<String> headerRegionKey = ValueKey(
    'discover-header-region',
  );

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _searching = false;
  bool _headerCollapsed = false;
  bool _visualSearching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_syncSearching);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_syncSearching)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncSearching() {
    final searching = _focusNode.hasFocus || _controller.text.isNotEmpty;
    if (searching != _searching && mounted) {
      setState(() => _searching = searching);
    }
  }

  void _onChanged(String text) {
    ref.read(searchSuggestNotifierProvider.notifier).onQueryChanged(text);
    setState(() => _searching = _focusNode.hasFocus || text.isNotEmpty);
  }

  void _clear() {
    _controller.clear();
    ref.read(searchSuggestNotifierProvider.notifier).clear();
    _focusNode.requestFocus();
    setState(() {});
  }

  void _exitSearch() {
    _controller.clear();
    ref.read(searchSuggestNotifierProvider.notifier).clear();
    _focusNode.unfocus();
    setState(() => _searching = false);
  }

  void _submit(String raw) {
    final term = raw.trim();
    if (term.isEmpty) return;
    unawaited(ref.read(recentSearchesProvider.notifier).add(term));
    _controller.value = TextEditingValue(
      text: term,
      selection: TextSelection.collapsed(offset: term.length),
    );
    ref.read(searchSuggestNotifierProvider.notifier).onQueryChanged(term);
    // A free-text search is the app's "hunting" intent signal. It has no
    // category to point at, so it goes as a query-shaped signal with no id;
    // the personalizer drops it if this customer paused personalisation.
    ref.read(feedSignalRecorderProvider).searchedQuery(term);
    _focusNode.unfocus();
    unawaited(
      context.push(
        '${RouteNames.searchResults}?q=${Uri.encodeComponent(term)}',
      ),
    );
  }

  Future<void> _startVisualSearch() async {
    final source = await showModalBottomSheet<_VisualSource>(
      context: context,
      backgroundColor: const Color(0xFF181C19),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Search what you see',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: 6),
              Text(
                'Use a photo or a short video. StyleMint samples the video '
                'and finds matching products.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _PhotoSourceButton(
                      icon: Icons.photo_camera_rounded,
                      label: 'Take photo',
                      onTap: () => Navigator.pop(
                        sheetContext,
                        _VisualSource.camera,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PhotoSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Choose photo',
                      onTap: () => Navigator.pop(
                        sheetContext,
                        _VisualSource.gallery,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PhotoSourceButton(
                icon: Icons.video_library_rounded,
                label: 'Understand a video',
                onTap: () => Navigator.pop(sheetContext, _VisualSource.video),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _visualSearching = true);
    try {
      final dataUris = source == _VisualSource.video
          ? await _pickVideoFrames()
          : await _pickPhoto(source);
      if (dataUris.isEmpty || !mounted) return;
      final results = await ref
          .read(customerSearchRemoteDataSourceProvider)
          .searchMultimodal(
            dataUris,
            query: _controller.text.trim(),
          );
      if (!mounted) return;
      await context.push(
        '${RouteNames.searchResults}?visual=1',
        extra: results,
      );
    } on Object catch (error) {
      if (!mounted) return;
      final message = error is FormatException
          ? error.message
          : 'Visual search is unavailable right now. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _visualSearching = false);
    }
  }

  Future<List<String>> _pickPhoto(_VisualSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source == _VisualSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (photo == null) return const [];
    final bytes = await photo.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) {
      throw const FormatException('Please choose an image smaller than 5 MB.');
    }
    final extension = photo.name.toLowerCase().split('.').last;
    final mime = extension == 'png'
        ? 'image/png'
        : extension == 'webp'
        ? 'image/webp'
        : 'image/jpeg';
    return ['data:$mime;base64,${base64Encode(bytes)}'];
  }

  Future<List<String>> _pickVideoFrames() async {
    final video = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (video == null) return const [];
    final controller = VideoPlayerController.file(File(video.path));
    try {
      await controller.initialize();
      final durationMs = controller.value.duration.inMilliseconds;
      if (durationMs <= 0) {
        throw const FormatException('This video could not be read.');
      }
      final moments = <int>{
        0,
        durationMs ~/ 2,
        (durationMs * 0.9).round(),
      };
      final frames = <String>[];
      for (final timeMs in moments) {
        final bytes = await FlutterVideoThumbnailPlus.thumbnailData(
          video: video.path,
          imageFormat: ImageFormat.jpeg,
          maxWidth: 1280,
          quality: 70,
          timeMs: timeMs,
        );
        if (bytes != null && bytes.isNotEmpty) {
          frames.add('data:image/jpeg;base64,${base64Encode(bytes)}');
        }
      }
      if (frames.isEmpty) {
        throw const FormatException(
          'No readable frames were found in this video.',
        );
      }
      return frames;
    } finally {
      await controller.dispose();
    }
  }

  void _open(String location) {
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) {
      unawaited(ref.read(recentSearchesProvider.notifier).add(typed));
    }
    _focusNode.unfocus();
    unawaited(context.push(location));
  }

  bool _onFeedScroll(ScrollNotification notification) {
    if (_searching ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }

    // Separate collapse and reveal thresholds prevent a small scroll wobble
    // from repeatedly opening and closing the hero.
    final nextCollapsed = _headerCollapsed
        ? notification.metrics.pixels > 8
        : notification.metrics.pixels > 48;
    if (nextCollapsed != _headerCollapsed && mounted) {
      setState(() => _headerCollapsed = nextCollapsed);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Keeps suggestions (and the debounce) alive while the feed is showing.
    ref
      ..listen(searchSuggestNotifierProvider, (_, _) {})
      // Reads saved searches up front so they're ready on first focus.
      ..listen(recentSearchesProvider, (_, _) {});

    final visualSearchAvailable =
        ref.watch(visualSearchCapabilityProvider).asData?.value ?? false;

    return PopScope(
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSearch();
      },
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_searching)
                _CollapsibleHeader(
                  collapsed: _headerCollapsed,
                  child: _Header(
                    onMission: () =>
                        unawaited(context.push(RouteNames.missionShopping)),
                  ),
                ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  DesignTokens.s16,
                  _searching ? DesignTokens.s12 : DesignTokens.s4,
                  _searching ? DesignTokens.s4 : DesignTokens.s16,
                  DesignTokens.s12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DiscoverSearchField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        onSubmitted: _submit,
                        onClear: _clear,
                      ),
                    ),
                    SearchInputActions(
                      currentQuery: () => _controller.text,
                      // Voice and barcode land on the same submit path as
                      // typing: recent searches, suggestions, results route.
                      onQuery: _submit,
                    ),
                    if (visualSearchAvailable) const SizedBox(width: 8),
                    if (visualSearchAvailable)
                      Semantics(
                        button: true,
                        label: 'Search with a photo',
                        child: IconButton.filledTonal(
                          key: const ValueKey('discover-visual-search'),
                          tooltip: 'Search with a photo',
                          onPressed: _visualSearching
                              ? null
                              : _startVisualSearch,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            backgroundColor: const Color(0x2432D477),
                            foregroundColor: DesignTokens.primaryGreen,
                          ),
                          icon: _visualSearching
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.center_focus_strong_rounded),
                        ),
                      ),
                    if (_searching)
                      TextButton(
                        key: const ValueKey('discover-search-cancel'),
                        onPressed: _exitSearch,
                        style: TextButton.styleFrom(
                          foregroundColor: DesignTokens.textLight,
                          minimumSize: const Size(
                            DesignTokens.minTouchTarget,
                            DesignTokens.minTouchTarget,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // The feed stays mounted under the suggestions so its
                    // scroll position and paging survive a search.
                    Offstage(
                      offstage: _searching,
                      child: TickerMode(
                        enabled: !_searching,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _onFeedScroll,
                          child: const DiscoverFeedView(),
                        ),
                      ),
                    ),
                    if (_searching)
                      Positioned.fill(
                        child: DiscoverSuggestionsPanel(
                          text: _controller.text,
                          onSubmit: _submit,
                          onOpen: _open,
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

class _CollapsibleHeader extends StatelessWidget {
  const _CollapsibleHeader({required this.collapsed, required this.child});

  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      duration: reduceMotion ? Duration.zero : DesignTokens.motionMedium,
      curve: DesignTokens.motionCurve,
      tween: Tween(end: collapsed ? 0 : 1),
      child: child,
      builder: (context, progress, child) => ClipRect(
        child: Align(
          key: DiscoverPage.headerRegionKey,
          alignment: Alignment.topCenter,
          heightFactor: progress,
          child: Opacity(
            opacity: progress,
            child: IgnorePointer(
              ignoring: progress < 0.5,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMission});

  final VoidCallback onMission;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
        padding: EdgeInsetsDirectional.fromSTEB(
          compact ? 14 : 18,
          compact ? 12 : 18,
          compact ? 10 : 14,
          compact ? 12 : 18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x2632D477)),
          gradient: const LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [Color(0xFF242A26), Color(0xFF111412)],
          ),
          boxShadow: DesignTokens.shadowCard,
        ),
        child: Stack(
          children: [
            const PositionedDirectional(
              top: -42,
              end: -28,
              child: IgnorePointer(child: _DiscoveryOrb()),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'YOUR STYLE, IN MOTION',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.eyebrow.copyWith(
                          color: DesignTokens.primaryGreen,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Shop by mission',
                      child: Material(
                        color: const Color(0x1F32D477),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          key: const ValueKey('discover-mission'),
                          onTap: onMission,
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                              compact ? 10 : 12,
                              9,
                              compact ? 10 : 12,
                              9,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: DesignTokens.primaryGreen,
                                ),
                                if (!compact) ...[
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Shop by mission',
                                    style: TextStyle(
                                      fontFamily: DesignTokens.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: DesignTokens.textWhite,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 18),
                Semantics(
                  header: true,
                  child: Text(
                    'Discover',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.displaySection.copyWith(
                      fontSize: compact ? 32 : 38,
                      height: 1,
                      letterSpacing: -1.4,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Products, reels and creators shaped around you.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      height: 1.4,
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryOrb extends StatelessWidget {
  const _DiscoveryOrb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x4032D477), Color(0x0032D477)],
        ),
      ),
    );
  }
}

class _PhotoSourceButton extends StatelessWidget {
  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x1832D477),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: DesignTokens.primaryGreen, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

enum _VisualSource { camera, gallery, video }
