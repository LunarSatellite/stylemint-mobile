import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_tag_suggestion.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Suggested products": what the ML detector saw in the reel and the
/// catalogue products it matched. Accept tags the product (the server may
/// refuse, e.g. not a campaign product — its message is shown); Dismiss hides
/// the candidate. Draws nothing while loading, on error, or when empty.
class ReelTagSuggestionsSection extends ConsumerStatefulWidget {
  const ReelTagSuggestionsSection({required this.reelId, super.key});

  final String reelId;

  @override
  ConsumerState<ReelTagSuggestionsSection> createState() =>
      _ReelTagSuggestionsSectionState();
}

class _ReelTagSuggestionsSectionState
    extends ConsumerState<ReelTagSuggestionsSection> {
  /// Suggestions accepted or dismissed here, hidden without a refetch.
  final Set<String> _handled = {};
  String? _busyId;

  Future<void> _accept(ReelTagSuggestionCandidate c) async {
    setState(() => _busyId = c.suggestionId);
    final result = await ref
        .read(reelTagSuggestionsRepositoryProvider)
        .acceptSuggestion(widget.reelId, c.suggestionId);
    if (!mounted) return;
    setState(() => _busyId = null);
    result.fold(
      (failure) =>
          SmSnackbar.error(context, NetworkExceptions.getMessage(failure)),
      (_) {
        setState(() => _handled.add(c.suggestionId));
        SmSnackbar.success(context, 'Product tagged.');
        ref
          ..invalidate(reelTaggedProductsProvider(widget.reelId))
          ..invalidate(creatorReelDetailProvider(widget.reelId));
        unawaited(
          ref
              .read(reelsFeedNotifierProvider.notifier)
              .refreshReel(widget.reelId),
        );
      },
    );
  }

  Future<void> _dismiss(ReelTagSuggestionCandidate c) async {
    // Hidden at once; restored only if the server refuses.
    setState(() => _handled.add(c.suggestionId));
    final result = await ref
        .read(reelTagSuggestionsRepositoryProvider)
        .dismissSuggestion(widget.reelId, c.suggestionId);
    if (!mounted) return;
    result.fold((failure) {
      setState(() => _handled.remove(c.suggestionId));
      SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final detections =
        ref.watch(reelTagSuggestionsProvider(widget.reelId)).asData?.value ??
        const <ReelTagSuggestionDetection>[];
    final visible = [
      for (final d in detections)
        if (d.candidates.any((c) => !_handled.contains(c.suggestionId))) d,
    ];
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const ValueKey('reel-tag-suggestions'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.s12),
        const Text('Suggested products', style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s8),
        for (final d in visible) ...[
          Text(_detectionTitle(d), style: DesignTokens.bodyText),
          for (final c in d.candidates)
            if (!_handled.contains(c.suggestionId))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: c.primaryImageUrl == null
                    ? const SizedBox(width: 44, height: 44)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          c.primaryImageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const SizedBox(width: 44, height: 44),
                        ),
                      ),
                title: Text(
                  c.productName ?? 'Product',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.bodyText,
                ),
                subtitle: Text(
                  [
                    if (c.vendorDisplayName != null) c.vendorDisplayName!,
                    if (c.priceLabel != null) c.priceLabel!,
                    if (c.similarity != null)
                      '${(c.similarity! * 100).round()}% match',
                  ].join('  ·  '),
                  style: DesignTokens.bodyText,
                ),
                trailing: _busyId == c.suggestionId
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            key: ValueKey('accept-${c.suggestionId}'),
                            tooltip: 'Tag this product',
                            icon: const Icon(
                              Icons.check,
                              color: DesignTokens.primaryGreen,
                            ),
                            onPressed: _busyId == null
                                ? () => _accept(c)
                                : null,
                          ),
                          IconButton(
                            key: ValueKey('dismiss-${c.suggestionId}'),
                            tooltip: 'Dismiss suggestion',
                            icon: const Icon(
                              Icons.close,
                              color: DesignTokens.textLight,
                            ),
                            onPressed: _busyId == null
                                ? () => _dismiss(c)
                                : null,
                          ),
                        ],
                      ),
              ),
        ],
      ],
    );
  }

  static String _detectionTitle(ReelTagSuggestionDetection d) {
    final label = d.label.isEmpty ? 'Item' : d.label;
    final t = d.frameTimeSeconds;
    return t == null ? label : '$label  ·  ${t.toStringAsFixed(1)}s';
  }
}
