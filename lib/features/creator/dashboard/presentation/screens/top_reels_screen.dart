import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reels_sort.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_top_reels_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Time filter enum (local UX only — maps to fromUtc/toUtc for API) ──────────

enum _TimeFilter {
  thisWeek('This Week'),
  thisMonth('This Month'),
  allTime('All Time');

  const _TimeFilter(this.label);
  final String label;
}

extension _TopReelsSortLabel on TopReelsSort {
  String get label => switch (this) {
        TopReelsSort.highestEarnings => 'Highest Earnings',
        TopReelsSort.mostViewed => 'Most Viewed',
        TopReelsSort.highestConversion => 'Highest Conversion Rate',
        TopReelsSort.mostEngagement => 'Most Engagement',
      };
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TopReelsScreen extends ConsumerStatefulWidget {
  const TopReelsScreen({super.key});

  @override
  ConsumerState<TopReelsScreen> createState() => _TopReelsScreenState();
}

class _TopReelsScreenState extends ConsumerState<TopReelsScreen> {
  TopReelsSort _sort = TopReelsSort.highestEarnings;
  _TimeFilter _timeFilter = _TimeFilter.allTime;

  bool get _isFilterActive => _timeFilter != _TimeFilter.allTime;

  DateTime? get _fromUtc => switch (_timeFilter) {
        _TimeFilter.allTime => null,
        _TimeFilter.thisWeek =>
          DateTime.now().toUtc().subtract(const Duration(days: 7)),
        _TimeFilter.thisMonth =>
          DateTime.now().toUtc().subtract(const Duration(days: 30)),
      };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorTopReelsNotifierProvider);

    final reels = state.maybeWhen(
      loadSuccess: (r) => r,
      orElse: () => const <TopReelSummary>[],
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
            child: state.maybeWhen(
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
                      itemBuilder: (ctx, index) => GestureDetector(
                        onTap: () => ctx.push(
                          '/creator/reels/${reels[index].reelId}',
                        ),
                        child: _RankedReelCard(
                          rank: index + 1,
                          reel: reels[index],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _fetch() {
    ref.read(creatorTopReelsNotifierProvider.notifier).fetch(
          sortBy: _sort,
          fromUtc: _fromUtc,
        );
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
          _fetch();
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
          _fetch();
        },
        onClear: () {
          setState(() {
            _sort = TopReelsSort.highestEarnings;
            _timeFilter = _TimeFilter.allTime;
          });
          Navigator.of(sheetCtx).pop();
          _fetch();
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

  final TopReelsSort current;
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

  final TopReelsSort current;
  final ValueChanged<TopReelsSort> onSelected;

  static const _options = TopReelsSort.values;

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
          RadioListTile<TopReelsSort>(
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

  final TopReelsSort initialSort;
  final _TimeFilter initialTime;
  final void Function(TopReelsSort sort, _TimeFilter time) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TopReelsSort _sort;
  late _TimeFilter _time;

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
          for (final opt in TopReelsSort.values)
            RadioListTile<TopReelsSort>(
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
  final TopReelSummary reel;

  @override
  Widget build(BuildContext context) {
    final title = reel.title.isEmpty ? 'Untitled reel' : reel.title;
    final posted =
        DateFormat('d MMM, yyyy hh:mm a').format(reel.publishedAtUtc.toLocal());

    return Container(
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
          Text(
            '#$rank',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
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
                Icons.arrow_outward,
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
                  iconWidget: Image.asset(
                    'assets/images/creatordash/universal-currency.png',
                    width: 20,
                    height: 20,
                  ),
                  value: reel.earnings.amount.round(),
                ),
                _Stat(icon: Icons.favorite, value: reel.likes),
                _Stat(icon: Icons.visibility, value: reel.views),
                _Stat(icon: Icons.shopping_bag, value: reel.sales),
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
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, this.iconWidget});

  final IconData icon;
  final int value;
  final Widget? iconWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        iconWidget ?? Icon(icon, size: 20, color: DesignTokens.textWhite),
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
