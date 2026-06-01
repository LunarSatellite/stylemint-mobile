import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/notifiers/tips_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/screens/send_tip_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/widgets/tip_history_tile.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceState = ref.watch(tipBalanceNotifierProvider);
    final historyState = ref.watch(tipsNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          title:
              const Text('Tips', style: DesignTokens.sectionInnerTitle),
          bottom: const TabBar(
            labelColor: DesignTokens.primaryGreen,
            unselectedLabelColor: DesignTokens.textMuted,
            indicatorColor: DesignTokens.primaryGreen,
            tabs: [
              Tab(text: 'Sent'),
              Tab(text: 'Received'),
            ],
          ),
        ),
        body: Column(
          children: [
            balanceState.when(
              initial: _balanceLoader,
              loadInProgress: _balanceLoader,
              loadSuccess: (balance) => _buildBalanceCard(balance),
              loadFailure: (_) => const SizedBox.shrink(),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildHistoryList(ref, historyState),
                  _buildHistoryList(ref, historyState),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'send-tip',
          backgroundColor: DesignTokens.primaryGreen,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SendTipScreen()),
            );
          },
          icon: const Icon(Icons.card_giftcard,
              color: DesignTokens.buttonPrimaryText),
          label: const Text('Send Tip',
              style: TextStyle(color: DesignTokens.buttonPrimaryText)),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(TipBalance balance) {
    return Container(
      margin: const EdgeInsets.all(DesignTokens.s16),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(
        backgroundColor: DesignTokens.primaryGreenDark,
        borderColor: DesignTokens.primaryGreen.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _balanceColumn('Available', balance.availableBalance,
              DesignTokens.primaryGreen),
          _balanceColumn('Received', balance.totalReceived,
              DesignTokens.textWhite),
          _balanceColumn('Sent', balance.totalSent,
              DesignTokens.colorError),
        ],
      ),
    );
  }

  Widget _balanceColumn(String label, Money amount, Color color) {
    return Column(
      children: [
        Text(label, style: DesignTokens.smallRegular),
        const SizedBox(height: 4),
        Text(formatMoney(amount),
            style: DesignTokens.mediumSemibold.copyWith(color: color)),
      ],
    );
  }

  Widget _buildHistoryList(
      WidgetRef ref, TipHistoryState state) {
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (tips) {
        if (tips.isEmpty) {
          return const Center(
            child: Text('No tips yet',
                style: DesignTokens.mediumRegular),
          );
        }
        return RefreshIndicator(
          onRefresh: () => ref
              .read(tipsNotifierProvider.notifier)
              .loadHistory(type: 'sent'),
          child: ListView.separated(
            padding: const EdgeInsets.all(DesignTokens.s16),
            itemCount: tips.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: DesignTokens.s8),
            itemBuilder: (context, index) {
              return TipHistoryTile(tip: tips[index]);
            },
          ),
        );
      },
      loadFailure: (failure) => Center(
        child: Text('Failed to load',
            style: DesignTokens.mediumRegular),
      ),
    );
  }

  Widget _balanceLoader() => const SizedBox(
    height: 80,
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
