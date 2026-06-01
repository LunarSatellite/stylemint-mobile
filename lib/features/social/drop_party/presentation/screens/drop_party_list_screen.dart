import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/notifiers/drop_party_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/widgets/drop_party_card.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class DropPartyListScreen extends ConsumerWidget {
  const DropPartyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dropPartiesNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Drop Parties 🔥',
            style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (parties) => _buildBody(context, ref, parties),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load drop parties',
                  style: DesignTokens.mediumRegular),
              const SizedBox(height: DesignTokens.s12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(dropPartiesNotifierProvider.notifier).loadAll(),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            backgroundColor: DesignTokens.bgAppBodyLight,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const _ScanPlaceholderScreen()),
              );
            },
            child: const Icon(Icons.qr_code_scanner,
                color: DesignTokens.textWhite),
          ),
          const SizedBox(width: DesignTokens.s12),
          FloatingActionButton.extended(
            heroTag: 'create',
            backgroundColor: DesignTokens.primaryGreen,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create Drop Party coming soon')),
              );
            },
            icon: const Icon(Icons.add, color: DesignTokens.buttonPrimaryText),
            label: const Text('Create Drop Party',
                style: TextStyle(color: DesignTokens.buttonPrimaryText)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, List<DropParty> parties) {
    if (parties.isEmpty) {
      return const Center(
        child: Text('No drop parties available',
            style: DesignTokens.mediumRegular),
      );
    }

    final live =
        parties.where((p) => p.status == DropPartyStatus.live).toList();
    final upcoming =
        parties.where((p) => p.status == DropPartyStatus.upcoming).toList();
    final ended =
        parties.where((p) => p.status == DropPartyStatus.ended || p.status == DropPartyStatus.soldOut).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: DesignTokens.primaryGreen,
            unselectedLabelColor: DesignTokens.textMuted,
            indicatorColor: DesignTokens.primaryGreen,
            tabs: [
              Tab(text: 'Live'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Ended'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildGrid(context, ref, live),
                _buildGrid(context, ref, upcoming),
                _buildGrid(context, ref, ended),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, WidgetRef ref, List<DropParty> parties) {
    if (parties.isEmpty) {
      return const Center(
        child: Text('No parties here', style: DesignTokens.mediumRegular),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(dropPartiesNotifierProvider.notifier).loadAll(),
      child: GridView.builder(
        padding: const EdgeInsets.all(DesignTokens.s16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: DesignTokens.s12,
          crossAxisSpacing: DesignTokens.s12,
          childAspectRatio: 0.72,
        ),
        itemCount: parties.length,
        itemBuilder: (context, index) {
          return DropPartyCard(party: parties[index]);
        },
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());
}

class _ScanPlaceholderScreen extends StatelessWidget {
  const _ScanPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Scan QR', style: DesignTokens.sectionInnerTitle)),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: 120, color: DesignTokens.primaryGreen),
            SizedBox(height: DesignTokens.s16),
            Text('Point camera at a Drop Party QR code',
                style: DesignTokens.mediumRegular),
          ],
        ),
      ),
    );
  }
}
