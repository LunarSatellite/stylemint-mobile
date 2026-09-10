import 'dart:async';

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

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _loadedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_handleTabChange)
      ..dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || _tabController.index == _loadedTab) {
      return;
    }
    _loadedTab = _tabController.index;
    unawaited(
      ref
          .read(tipsNotifierProvider.notifier)
          .loadHistory(type: _loadedTab == 0 ? 'sent' : 'received'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balanceState = ref.watch(tipBalanceNotifierProvider);
    final historyState = ref.watch(tipsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Tips', style: DesignTokens.sectionInnerTitle),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          indicatorColor: DesignTokens.primaryGreen,
          tabs: const [
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
            loadSuccess: _buildBalanceCard,
            loadFailure: (_) => const SizedBox.shrink(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(
                  historyState,
                  type: 'sent',
                  received: false,
                ),
                _buildHistoryList(
                  historyState,
                  type: 'received',
                  received: true,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'send-tip',
        backgroundColor: DesignTokens.primaryGreen,
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const SendTipScreen()),
        ),
        icon: const Icon(
          Icons.card_giftcard,
          color: DesignTokens.buttonPrimaryText,
        ),
        label: const Text(
          'Send Tip',
          style: TextStyle(color: DesignTokens.buttonPrimaryText),
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
        borderColor: DesignTokens.primaryGreen.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _balanceColumn(
            'Settled',
            balance.availableBalance,
            DesignTokens.primaryGreen,
          ),
          _balanceColumn(
            'Received',
            balance.totalReceived,
            DesignTokens.textWhite,
          ),
          _balanceColumn(
            'Sent',
            balance.totalSent,
            DesignTokens.colorError,
          ),
        ],
      ),
    );
  }

  Widget _balanceColumn(String label, Money amount, Color color) {
    return Column(
      children: [
        Text(label, style: DesignTokens.smallRegular),
        const SizedBox(height: DesignTokens.s4),
        Text(
          formatMoney(amount),
          style: DesignTokens.mediumSemibold.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildHistoryList(
    TipHistoryState state, {
    required String type,
    required bool received,
  }) {
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (tips) => RefreshIndicator(
        onRefresh: () =>
            ref.read(tipsNotifierProvider.notifier).loadHistory(type: type),
        child: tips.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 280,
                    child: Center(
                      child: Text(
                        received ? 'No received tips yet' : 'No sent tips yet',
                        style: DesignTokens.mediumRegular,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(DesignTokens.s16),
                itemCount: tips.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: DesignTokens.s8),
                itemBuilder: (context, index) => TipHistoryTile(
                  tip: tips[index],
                  received: received,
                ),
              ),
      ),
      loadFailure: (_) => Center(
        child: TextButton.icon(
          onPressed: () => unawaited(
            ref.read(tipsNotifierProvider.notifier).loadHistory(type: type),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry tips'),
        ),
      ),
    );
  }

  Widget _balanceLoader() => const SizedBox(
    height: 80,
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _loader() => const Center(child: CircularProgressIndicator());
}
