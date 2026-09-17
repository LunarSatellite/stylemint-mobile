import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_feed_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_search_field.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/discover_suggestions_panel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Discover tab: a search box with live suggestions over a chip-driven,
/// curated feed. Submitting opens `/search-results`.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _searching = false;

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
    _focusNode.unfocus();
    unawaited(
      context.push(
        '${RouteNames.searchResults}?q=${Uri.encodeComponent(term)}',
      ),
    );
  }

  void _open(String location) {
    final typed = _controller.text.trim();
    if (typed.isNotEmpty) {
      unawaited(ref.read(recentSearchesProvider.notifier).add(typed));
    }
    _focusNode.unfocus();
    unawaited(context.push(location));
  }

  @override
  Widget build(BuildContext context) {
    // Keeps suggestions (and the debounce) alive while the feed is showing.
    ref
      ..listen(searchSuggestNotifierProvider, (_, _) {})
      // Reads saved searches up front so they're ready on first focus.
      ..listen(recentSearchesProvider, (_, _) {});

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
                _Header(
                  onMission: () =>
                      unawaited(context.push(RouteNames.missionShopping)),
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
                        child: const DiscoverFeedView(),
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
