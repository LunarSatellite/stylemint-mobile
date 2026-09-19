import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/entities/demand_signals.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/presentation/widgets/intent_decision_board_panel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Voyager "Intent Signal and Demand Sensing" for vendors: what shoppers
/// searched for over the last 7 or 30 days, leading with the searches that
/// found nothing — the demand a vendor can act on by stocking it.
class VendorDemandSignalsScreen extends ConsumerWidget {
  const VendorDemandSignalsScreen({super.key});

  static const windows = <int>[7, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demandSignalsNotifierProvider);
    final notifier = ref.read(demandSignalsNotifierProvider.notifier);
    final days = notifier.days;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 18,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: Text(
          'What shoppers search for',
          style: DesignTokens.oneLinerSemibold,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s12,
              ),
              child: _WindowToggle(
                selectedDays: days,
                onSelected: (value) {
                  if (value != days) notifier.load(days: value);
                },
              ),
            ),
            Expanded(
              child: state.when(
                initial: () => const SmPageLoader(),
                loadInProgress: () => const SmPageLoader(),
                loadSuccess: (signals) => signals.isEmpty
                    ? _NoSearchesView(
                        days: days,
                        onTryLongerWindow: days < windows.last
                            ? () => notifier.load(days: windows.last)
                            : null,
                      )
                    : _SignalsBody(signals: signals, days: days),
                loadFailure: (_) => SmErrorView(
                  message: 'Could not load what shoppers searched for.',
                  onRetry: notifier.load,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowToggle extends StatelessWidget {
  const _WindowToggle({required this.selectedDays, required this.onSelected});

  final int selectedDays;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s4),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final days in VendorDemandSignalsScreen.windows)
            Expanded(
              child: Semantics(
                button: true,
                selected: days == selectedDays,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelected(days),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.s8,
                    ),
                    decoration: BoxDecoration(
                      color: days == selectedDays
                          ? DesignTokens.primaryGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Last $days days',
                      style: DesignTokens.smallRegular.copyWith(
                        fontWeight: FontWeight.w600,
                        color: days == selectedDays
                            ? Colors.black
                            : DesignTokens.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignalsBody extends StatelessWidget {
  const _SignalsBody({required this.signals, required this.days});

  final DemandSignals signals;
  final int days;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s24,
      ),
      children: [
        const _SectionHeader(
          key: ValueKey('unmet-searches-header'),
          title: 'Searched but not found',
          subtitle:
              'These searches returned no products. Stocking them could '
              'win you sales.',
        ),
        const SizedBox(height: DesignTokens.s8),
        if (signals.unmetSearches.isEmpty)
          const _SectionNote('Every search in this period found products.')
        else
          _QueryList(
            queries: signals.unmetSearches,
            accent: DesignTokens.warning500,
          ),
        const SizedBox(height: DesignTokens.s24),
        const _SectionHeader(
          key: ValueKey('top-searches-header'),
          title: 'Top searches',
          subtitle: 'What shoppers searched for most on StyleMint.',
        ),
        const SizedBox(height: DesignTokens.s8),
        if (signals.topSearches.isEmpty)
          const _SectionNote('No searches recorded in this period.')
        else
          _QueryList(
            queries: signals.topSearches,
            accent: DesignTokens.primaryGreen,
          ),
        const SizedBox(height: DesignTokens.s24),
        IntentDecisionBoardPanel(days: days),
        const SizedBox(height: DesignTokens.s16),
        Text(
          'Counts are totals across all shoppers. No personal details are '
          'shared.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SectionNote extends StatelessWidget {
  const _SectionNote(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Text(
        message,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}

class _QueryList extends StatelessWidget {
  const _QueryList({required this.queries, required this.accent});

  final List<DemandQuery> queries;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final maxCount = queries.fold<int>(0, (m, q) => q.count > m ? q.count : m);
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < queries.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                color: DesignTokens.borderDefault,
                indent: DesignTokens.s16,
                endIndent: DesignTokens.s16,
              ),
            _QueryRow(
              rank: i + 1,
              query: queries[i],
              share: maxCount == 0 ? 0 : queries[i].count / maxCount,
              accent: accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _QueryRow extends StatelessWidget {
  const _QueryRow({
    required this.rank,
    required this.query,
    required this.share,
    required this.accent,
  });

  final int rank;
  final DemandQuery query;
  final double share;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query.query,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: share.clamp(0, 1).toDouble(),
                    minHeight: 4,
                    color: accent,
                    backgroundColor: DesignTokens.borderDefault,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Text(
            searchCountLabel(query.count),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSearchesView extends StatelessWidget {
  const _NoSearchesView({required this.days, this.onTryLongerWindow});

  final int days;
  final VoidCallback? onTryLongerWindow;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.manage_search_rounded,
              size: 56,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'No searches yet',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s6),
            Text(
              'Shoppers haven\'t searched StyleMint in the last $days days. '
              'Check back soon.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            if (onTryLongerWindow != null) ...[
              const SizedBox(height: DesignTokens.s16),
              OutlinedButton(
                onPressed: onTryLongerWindow,
                style: DesignTokens.outlinedButtonStyle(),
                child: Text(
                  'See the last 30 days',
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "1 search" / "1,240 searches".
String searchCountLabel(int count) => count == 1
    ? '1 search'
    : '${NumberFormat.decimalPattern('en_US').format(count)} searches';
