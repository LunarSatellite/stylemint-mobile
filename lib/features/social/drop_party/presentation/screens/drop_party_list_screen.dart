import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/notifiers/drop_party_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/scan_invite_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/widgets/drop_party_card.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The backend's list endpoint deliberately returns live parties only.
class DropPartyListScreen extends ConsumerWidget {
  const DropPartyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dropPartiesNotifierProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text(
          'Live Drop Parties',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (_) => _Failure(
          onRetry: () =>
              ref.read(dropPartiesNotifierProvider.notifier).loadAll(),
        ),
        loadSuccess: (parties) => parties.isEmpty
            ? const Center(
                child: Text(
                  'No live drop parties right now',
                  style: DesignTokens.mediumRegular,
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(dropPartiesNotifierProvider.notifier).loadAll(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  itemCount: parties.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (_, index) => SizedBox(
                    height: 190,
                    child: DropPartyCard(party: parties[index]),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: 'Join by code',
        backgroundColor: DesignTokens.bgAppBodyLight,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ScanInviteScreen()),
        ),
        child: const Icon(Icons.qr_code_scanner, color: DesignTokens.textWhite),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Failed to load live drop parties',
          style: DesignTokens.mediumRegular,
        ),
        const SizedBox(height: DesignTokens.s12),
        ElevatedButton(
          onPressed: onRetry,
          style: DesignTokens.primaryButtonStyle(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
