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
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s4,
        DesignTokens.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE STYLEMINT MALL',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.eyebrow.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'Discover',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.displaySection.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: const ValueKey('discover-mission'),
            tooltip: 'Shop by mission',
            color: DesignTokens.textLight,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: onMission,
          ),
        ],
      ),
    );
  }
}
