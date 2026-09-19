import 'dart:async';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/services/private_twin_crypto.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/notifiers/memory_vault_notifier.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/widgets/memory_consent_section.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/widgets/twin_password_dialog.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Memory Vault — what the StyleMint companion remembers about the customer,
/// with controls to pause it, correct or forget memories, and download them.
class MemoryVaultScreen extends ConsumerWidget {
  const MemoryVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<MemoryVaultState>(memoryVaultNotifierProvider, (_, next) {
      if (next case MemoryVaultLoaded(message: final message?)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        ref.read(memoryVaultNotifierProvider.notifier).clearMessage();
      }
    });

    final state = ref.watch(memoryVaultNotifierProvider);
    final notifier = ref.read(memoryVaultNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Your StyleMint memory',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: switch (state) {
        MemoryVaultLoading() => const SmPageLoader(),
        MemoryVaultFailed(:final message) => SmErrorView(
          message: message,
          onRetry: notifier.load,
        ),
        MemoryVaultLoaded(:final vault, :final busy) => _VaultBody(
          vault: vault,
          busy: busy,
        ),
      },
    );
  }
}

class _VaultBody extends ConsumerWidget {
  const _VaultBody({required this.vault, required this.busy});

  final MemoryVault vault;
  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(memoryVaultNotifierProvider.notifier);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Text(
          'Your companion remembers what you buy, watch and like so its '
          'suggestions fit you. You decide what it keeps.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        Container(
          decoration: DesignTokens.cardDecoration(),
          child: SwitchListTile(
            value: !vault.paused,
            onChanged: busy
                ? null
                : (remember) {
                    unawaited(notifier.setPaused(paused: !remember));
                    // The Mall's personalisation reads this same switch and
                    // caches the answer; tell it to ask again.
                    ref.read(storefrontPersonalizerProvider).forgetConsent();
                  },
            activeTrackColor: DesignTokens.primaryGreen,
            title: Text(
              'Remember new things',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            subtitle: Text(
              vault.paused
                  ? 'Paused. Nothing new is kept, and none of the four uses '
                        'below run.'
                  : 'New purchases, views and likes are remembered. Each use '
                        'below is a separate decision.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        MemoryConsentSection(vault: vault, busy: busy),
        const SizedBox(height: DesignTokens.s12),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: DesignTokens.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(
                      'Your portable private twin',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s6),
              Text(
                'Backups are encrypted on this device before sharing. '
                'Only your password can unlock them, including on a new device.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : () => _backup(context, notifier),
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text('Backup'),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => _restore(context, notifier),
                      icon: const Icon(Icons.settings_backup_restore, size: 18),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.textWhite,
                        side: const BorderSide(
                          color: DesignTokens.borderDefault,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        OutlinedButton.icon(
          onPressed: busy || vault.memories.isEmpty
              ? null
              : () => _confirmForgetAll(context, notifier),
          icon: const Icon(Icons.delete_sweep_outlined, size: 18),
          label: const Text('Forget everything'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.colorError,
            side: const BorderSide(color: DesignTokens.colorError),
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        Text(
          'What it remembers (${vault.memories.length})',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.primaryGreen,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        if (vault.memories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s24),
            child: Text(
              'Nothing remembered yet.',
              textAlign: TextAlign.center,
              style: DesignTokens.bodyText.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          )
        else
          for (final memory in vault.memories)
            _MemoryTile(memory: memory, enabled: !busy),
      ],
    );
  }

  Future<void> _backup(
    BuildContext context,
    MemoryVaultNotifier notifier,
  ) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const TwinPasswordDialog(confirmPassword: true),
    );
    if (password == null || !context.mounted) return;
    try {
      final json = await notifier.export();
      if (json == null || !context.mounted) return;
      final encrypted = await PrivateTwinCrypto().encrypt(json, password);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              encrypted,
              mimeType: 'application/vnd.stylemint.private-twin+json',
              name: 'stylemint-private-twin.smtwin',
            ),
          ],
          subject: 'My encrypted StyleMint private twin',
        ),
      );
    } on FormatException catch (error) {
      if (context.mounted) _showError(context, error.message);
    }
  }

  Future<void> _restore(
    BuildContext context,
    MemoryVaultNotifier notifier,
  ) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['smtwin'],
      withData: true,
    );
    final bytes = picked?.files.single.bytes;
    if (bytes == null || !context.mounted) return;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const TwinPasswordDialog(confirmPassword: false),
    );
    if (password == null || !context.mounted) return;
    try {
      final json = await PrivateTwinCrypto().decrypt(bytes, password);
      await notifier.importPortableTwin(json);
    } on FormatException catch (error) {
      if (context.mounted) _showError(context, error.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _confirmForgetAll(BuildContext context, MemoryVaultNotifier notifier) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: DesignTokens.bgAppBody,
          title: const Text(
            'Forget everything?',
            style: TextStyle(color: DesignTokens.textWhite),
          ),
          content: const Text(
            'Your companion will forget everything it remembers about you. '
            'This cannot be undone.',
            style: TextStyle(color: DesignTokens.textLight),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                unawaited(notifier.forgetAll());
              },
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.colorError,
              ),
              child: const Text('Forget all'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _MemoryAction { correct, forget }

class _MemoryTile extends ConsumerWidget {
  const _MemoryTile({required this.memory, required this.enabled});

  final CompanionMemory memory;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(memoryVaultNotifierProvider.notifier);
    final date = memory.rememberedAt.toLocal();
    final when =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      decoration: DesignTokens.cardDecoration(),
      child: ListTile(
        title: Text(
          memory.content,
          style: DesignTokens.bodyText.copyWith(color: DesignTokens.textWhite),
        ),
        subtitle: Text(
          memory.category == null ? when : '${memory.category} · $when',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        trailing: PopupMenuButton<_MemoryAction>(
          enabled: enabled,
          icon: const Icon(Icons.more_vert, color: DesignTokens.iconLight),
          tooltip: 'Memory options',
          onSelected: (action) async {
            switch (action) {
              case _MemoryAction.correct:
                final corrected = await showDialog<String>(
                  context: context,
                  builder: (_) => _CorrectMemoryDialog(initial: memory.content),
                );
                if (corrected != null) {
                  await notifier.correct(memory.id, corrected);
                }
              case _MemoryAction.forget:
                await notifier.forget(memory.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: _MemoryAction.correct, child: Text('Correct')),
            PopupMenuItem(value: _MemoryAction.forget, child: Text('Forget')),
          ],
        ),
      ),
    );
  }
}

class _CorrectMemoryDialog extends StatefulWidget {
  const _CorrectMemoryDialog({required this.initial});

  final String initial;

  @override
  State<_CorrectMemoryDialog> createState() => _CorrectMemoryDialogState();
}

class _CorrectMemoryDialogState extends State<_CorrectMemoryDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: const Text(
        'Correct memory',
        style: TextStyle(color: DesignTokens.textWhite),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 2000,
        minLines: 1,
        maxLines: 4,
        style: const TextStyle(color: DesignTokens.textWhite),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) Navigator.pop(context, text);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
