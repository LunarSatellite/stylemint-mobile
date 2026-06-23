import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _SortOption {
  highestEarnings('Highest Earnings'),
  mostLiked('Most Liked'),
  mostWatched('Most Watched'),
  highestConversionRate('Highest Conversion Rate'),
  highestEngagement('Most Engagement (likes & Shares)');

  const _SortOption(this.label);
  final String label;
}

enum _TimeFilter {
  thisWeek('This Week'),
  thisMonth('This Month'),
  allTime('All Time');

  const _TimeFilter(this.label);
  final String label;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TopReelsScreen extends ConsumerStatefulWidget {
  const TopReelsScreen({super.key});

  @override
  ConsumerState<TopReelsScreen> createState() => _TopReelsScreenState();
}

class _TopReelsScreenState extends ConsumerState<TopReelsScreen> {
  _SortOption _sort = _SortOption.highestEarnings;
  _TimeFilter _timeFilter = _TimeFilter.allTime;

  bool get _isFilterActive => _timeFilter != _TimeFilter.allTime;

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(creatorDashboardNotifierProvider);

    final reels = dashState.maybeWhen(
      loadSuccess: (d) => _apply(d.topReels),
      orElse: () => const <CreatorReel>[],
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Top Performing Reels',
          style: DesignTokens.titleMedium,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Chips row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s16,
              DesignTokens.s12,
            ),
            child: Row(
              children: [
                _FilterChip(
                  isActive: _isFilterActive,
                  onTap: () => _openFilterSheet(context),
                ),
                const SizedBox(width: DesignTokens.s8),
                _SortChip(
                  current: _sort,
                  onTap: () => _openSortSheet(context),
                ),
              ],
            ),
          ),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: dashState.maybeWhen(
              loadInProgress: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              orElse: () => reels.isEmpty
                  ? Center(
                      child: Text(
                        'No reels yet.',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.s16,
                        0,
                        DesignTokens.s16,
                        DesignTokens.s32,
                      ),
                      itemCount: reels.length,
                      separatorBuilder: (_, _s) =>
                          const SizedBox(height: DesignTokens.s12),
                      itemBuilder: (_, index) => _RankedReelCard(
                        rank: index + 1,
                        reel: reels[index],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<CreatorReel> _apply(List<CreatorReel> source) {
    var result = List<CreatorReel>.from(source);

    // Time filter
    if (_timeFilter != _TimeFilter.allTime) {
      final now = DateTime.now();
      final cutoff = _timeFilter == _TimeFilter.thisWeek
          ? now.subtract(const Duration(days: 7))
          : now.subtract(const Duration(days: 30));
      result = result
          .where((r) => r.publishedAt.isAfter(cutoff))
          .toList();
    }

    // Sort
    switch (_sort) {
      case _SortOption.highestEarnings:
        result.sort((a, b) => b.comments.compareTo(a.comments));
      case _SortOption.mostLiked:
        result.sort((a, b) => b.likes.compareTo(a.likes));
      case _SortOption.mostWatched:
        result.sort((a, b) => b.views.compareTo(a.views));
      case _SortOption.highestConversionRate:
        result.sort((a, b) => b.shares.compareTo(a.shares));
      case _SortOption.highestEngagement:
        result.sort(
          (a, b) => (b.views + b.shares).compareTo(a.views + a.shares),
        );
    }

    return result;
  }

  void _openSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) => _SortSheet(
        current: _sort,
        onSelected: (opt) {
          setState(() => _sort = opt);
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (sheetCtx) => _FilterSheet(
        initialSort: _sort,
        initialTime: _timeFilter,
        onApply: (sort, time) {
          setState(() {
            _sort = sort;
            _timeFilter = time;
          });
          Navigator.of(sheetCtx).pop();
        },
        onClear: () {
          setState(() {
            _sort = _SortOption.highestEarnings;
            _timeFilter = _TimeFilter.allTime;
          });
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }
}

// ── Chips ─────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? DesignTokens.primaryGreen
              : DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 14,
              color: isActive
                  ? DesignTokens.buttonPrimaryText
                  : DesignTokens.textWhite,
            ),
            const SizedBox(width: DesignTokens.s4),
            Text(
              'Filter',
              style: DesignTokens.smallRegular.copyWith(
                color: isActive
                    ? DesignTokens.buttonPrimaryText
                    : DesignTokens.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.current, required this.onTap});

  final _SortOption current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s12,
          vertical: DesignTokens.s8,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: DesignTokens.s4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: DesignTokens.textWhite,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort By bottom sheet ──────────────────────────────────────────────────────

class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelected});

  final _SortOption current;
  final ValueChanged<_SortOption> onSelected;

  // Options shown in the Sort By sheet (subset matching the design)
  static const _options = [
    _SortOption.highestEarnings,
    _SortOption.mostLiked,
    _SortOption.mostWatched,
    _SortOption.highestEngagement,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: DesignTokens.s12),
        _SheetHandle(),
        const SizedBox(height: DesignTokens.s4),
        _SheetHeader(
          title: 'Sort By',
          onClose: () => Navigator.of(context).pop(),
        ),
        for (final opt in _options)
          RadioListTile<_SortOption>(
            value: opt,
            groupValue: current,
            onChanged: (val) {
              if (val != null) onSelected(val);
            },
            activeColor: DesignTokens.primaryGreen,
            title: Text(
              opt.label,
              style: DesignTokens.oneLinerRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        const SizedBox(height: DesignTokens.s16),
      ],
    );
  }
}

// ── Filter Reels bottom sheet ─────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initialSort,
    required this.initialTime,
    required this.onApply,
    required this.onClear,
  });

  final _SortOption initialSort;
  final _TimeFilter initialTime;
  final void Function(_SortOption sort, _TimeFilter time) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _SortOption _sort;
  late _TimeFilter _time;

  static const _sortOptions = [
    _SortOption.highestEarnings,
    _SortOption.mostLiked,
    _SortOption.highestConversionRate,
    _SortOption.highestEngagement,
  ];

  @override
  void initState() {
    super.initState();
    _sort = widget.initialSort;
    _time = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: DesignTokens.s12),
          _SheetHandle(),
          const SizedBox(height: DesignTokens.s4),
          _SheetHeader(
            title: 'Filter Reels',
            onClose: () => Navigator.of(context).pop(),
          ),
          // ── Time section ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s16,
              0,
            ),
            child: Text(
              'Time:',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final t in _TimeFilter.values)
            RadioListTile<_TimeFilter>(
              value: t,
              groupValue: _time,
              onChanged: (val) {
                if (val != null) setState(() => _time = val);
              },
              activeColor: DesignTokens.primaryGreen,
              title: Text(
                t.label,
                style: DesignTokens.oneLinerRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          // ── Sort By section ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s16,
              0,
            ),
            child: Text(
              'Sort By:',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final opt in _sortOptions)
            RadioListTile<_SortOption>(
              value: opt,
              groupValue: _sort,
              onChanged: (val) {
                if (val != null) setState(() => _sort = val);
              },
              activeColor: DesignTokens.primaryGreen,
              title: Text(
                opt.label,
                style: DesignTokens.oneLinerRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          // ── Buttons ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onClear,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DesignTokens.borderDefault),
                      foregroundColor: DesignTokens.textWhite,
                      minimumSize: const Size(0, DesignTokens.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onApply(_sort, _time),
                    style: DesignTokens.primaryButtonStyle(),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sheet widgets ──────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: DesignTokens.borderDefault,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ranked card ───────────────────────────────────────────────────────────────

class _RankedReelCard extends StatelessWidget {
  const _RankedReelCard({required this.rank, required this.reel});

  final int rank;
  final CreatorReel reel;

  @override
  Widget build(BuildContext context) {
    final title = reel.title.isEmpty ? 'Untitled reel' : reel.title;
    final posted = DateFormat('d MMM, yyyy hh:mm a').format(reel.publishedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '#$rank',
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Container(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s12,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s4),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: DesignTokens.bgAppBody,
                      alignment: Alignment.center,
                      child: reel.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              reel.thumbnailUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.play_circle_fill,
                              color: DesignTokens.iconLight,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          'Posted on: $posted',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: DesignTokens.iconLight,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              const Divider(
                color: DesignTokens.borderDefault,
                height: 1,
                thickness: 1,
              ),
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                      icon: Icons.receipt_long_outlined,
                      value: reel.comments,
                    ),
                    _Stat(icon: Icons.favorite_outline, value: reel.likes),
                    _Stat(icon: Icons.visibility_outlined, value: reel.views),
                    _Stat(
                      icon: Icons.shopping_bag_outlined,
                      value: reel.shares,
                    ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.s8),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: DesignTokens.iconLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: DesignTokens.textWhite),
        const SizedBox(height: DesignTokens.s4),
        Text(
          _compact(value),
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.3,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}k';
    return '$n';
  }
}
