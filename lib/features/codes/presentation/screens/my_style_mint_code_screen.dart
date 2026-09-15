import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/style_mint_code_info.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/style_mint_code_format.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/vcard.dart';
import 'package:stylemint_mobile_frontend/features/codes/presentation/widgets/style_mint_qr.dart';
import 'package:stylemint_mobile_frontend/features/codes/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/providers/creator_identity_providers.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Profile → "My StyleMint code": a QR that opens this person's StyleMint
/// profile, with share, rotate and save-as-contact.
class MyStyleMintCodeScreen extends ConsumerStatefulWidget {
  const MyStyleMintCodeScreen({super.key});

  static const String title = 'My StyleMint code';

  @override
  ConsumerState<MyStyleMintCodeScreen> createState() =>
      _MyStyleMintCodeScreenState();
}

class _MyStyleMintCodeScreenState extends ConsumerState<MyStyleMintCodeScreen> {
  /// Off by default: the phone number goes on the contact card only when
  /// the person turns this on.
  bool _includePhone = false;
  bool _savingContact = false;

  String get _displayName => ref
      .read(profileNotifierProvider)
      .maybeWhen(loadSuccess: (s) => s.displayName, orElse: () => '');

  Future<void> _shareLink(StyleMintCodeInfo code) async {
    await SharePlus.instance.share(
      ShareParams(
        text: 'Find me on StyleMint: ${code.url}',
        subject: 'My StyleMint profile',
      ),
    );
  }

  Future<void> _saveContact(StyleMintCodeInfo code) async {
    if (_savingContact) return;
    setState(() => _savingContact = true);
    try {
      String? phone;
      if (_includePhone) {
        final profile = await ref
            .read(profileRepositoryProvider)
            .getFullProfile();
        phone = profile.fold(
          (_) => null,
          (p) => p.phone.trim().isEmpty ? null : p.phone,
        );
        if (!mounted) return;
        if (phone == null) {
          SmSnackbar.info(
            context,
            "Your profile has no phone number, so the card won't have one.",
          );
        }
      }
      final name = _displayName;
      final fileName = profileVCardFileName(name);
      final card = buildProfileVCard(
        displayName: name,
        profileUrl: code.url,
        phone: phone,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(card),
              mimeType: 'text/vcard',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
        ),
      );
    } on Object catch (_) {
      if (mounted) SmSnackbar.error(context, "Couldn't share the contact.");
    } finally {
      if (mounted) setState(() => _savingContact = false);
    }
  }

  Future<void> _confirmRotate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text(
          'Make a new code?',
          style: DesignTokens.sectionInnerTitle,
        ),
        content: Text(
          'Your current code stops working straight away, including any '
          "you've printed or shared. People will need your new code to find "
          'you.',
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('confirm-rotate-code'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Make new code'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await ref
        .read(myProfileCodeNotifierProvider.notifier)
        .rotate();
    if (!mounted) return;
    if (failure == null) {
      SmSnackbar.success(
        context,
        'New code ready. The old one no longer works.',
      );
    } else {
      SmSnackbar.error(context, NetworkExceptions.getMessage(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProfileCodeNotifierProvider);
    final summary = ref
        .watch(profileNotifierProvider)
        .maybeWhen(loadSuccess: (s) => s, orElse: () => null);
    final handle = ref.watch(activeHandleProvider).asData?.value;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          MyStyleMintCodeScreen.title,
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: switch (state) {
        MyProfileCodeLoading() => const SmPageLoader(),
        MyProfileCodeFailed() => SmErrorView(
          message: "Couldn't load your StyleMint code.",
          onRetry: () => unawaited(
            ref.read(myProfileCodeNotifierProvider.notifier).load(),
          ),
        ),
        MyProfileCodeReady(:final code, :final rotating) => ListView(
          padding: const EdgeInsets.all(DesignTokens.s20),
          children: [
            _PersonHeader(
              name: summary?.displayName ?? '',
              avatarUrl: summary?.avatarUrl ?? '',
              handle: handle,
            ),
            const SizedBox(height: DesignTokens.s24),
            Center(
              child: StyleMintQr(
                key: const ValueKey('profile-code-qr'),
                data: code.url,
                semanticLabel: 'QR code for your StyleMint profile',
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              StyleMintCodeFormat.display(code.code),
              textAlign: TextAlign.center,
              style: DesignTokens.sectionInnerTitle.copyWith(letterSpacing: 2),
            ),
            const SizedBox(height: DesignTokens.s4),
            const Text(
              'Friends scan this with StyleMint to open your profile.',
              textAlign: TextAlign.center,
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(height: DesignTokens.s24),
            _CodeAction(
              icon: Icons.ios_share_rounded,
              label: 'Share my code',
              onTap: () => unawaited(_shareLink(code)),
            ),
            _CodeAction(
              icon: Icons.contact_page_outlined,
              label: _savingContact ? 'Preparing contact…' : 'Save contact',
              onTap: _savingContact
                  ? null
                  : () => unawaited(_saveContact(code)),
            ),
            SwitchListTile(
              value: _includePhone,
              onChanged: (value) => setState(() => _includePhone = value),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s4,
              ),
              title: Text(
                'Include my phone number',
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              subtitle: const Text(
                'Only on the contact card you share. Off unless you turn '
                'it on.',
                style: DesignTokens.smallRegular,
              ),
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? DesignTokens.textWhite
                    : DesignTokens.textMuted,
              ),
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? DesignTokens.primaryGreen
                    : DesignTokens.bgAppBodyLight,
              ),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            ),
            const Divider(color: DesignTokens.borderDefault, height: 1),
            _CodeAction(
              icon: Icons.autorenew_rounded,
              label: rotating ? 'Making a new code…' : 'Rotate code',
              onTap: rotating ? null : () => unawaited(_confirmRotate()),
            ),
          ],
        ),
      },
    );
  }
}

class _PersonHeader extends StatelessWidget {
  const _PersonHeader({
    required this.name,
    required this.avatarUrl,
    required this.handle,
  });

  final String name;
  final String avatarUrl;
  final String? handle;

  @override
  Widget build(BuildContext context) {
    final at = handle;
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: DesignTokens.bgAppBodyLight,
          backgroundImage: avatarUrl.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? const Icon(Icons.person, color: DesignTokens.iconLight)
              : null,
        ),
        const SizedBox(height: DesignTokens.s12),
        if (name.isNotEmpty)
          Text(
            name,
            textAlign: TextAlign.center,
            style: DesignTokens.sectionInnerTitle,
          ),
        if (at != null && at.isNotEmpty)
          Text(
            '@$at',
            textAlign: TextAlign.center,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
      ],
    );
  }
}

class _CodeAction extends StatelessWidget {
  const _CodeAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s4,
          vertical: DesignTokens.s16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? DesignTokens.iconWhite : DesignTokens.iconLight,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(
                  color: enabled
                      ? DesignTokens.textWhite
                      : DesignTokens.textMuted,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.iconLight,
            ),
          ],
        ),
      ),
    );
  }
}
