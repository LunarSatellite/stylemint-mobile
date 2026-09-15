import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/codes/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `/c/{code}` — opens a StyleMint code from the scanner, an NFC tag or a
/// link. Resolves it (which counts the scan), then replaces itself with the
/// in-store product, the store, or the person's profile.
class CodeResolveScreen extends ConsumerWidget {
  const CodeResolveScreen({required this.code, required this.via, super.key});

  static const String openingLabel = 'Opening StyleMint code';
  static const String notActiveTitle = "This code isn't active";
  static const String notActiveBody =
      'It may have been replaced or switched off. You can still shop and '
      'watch reels on StyleMint.';
  static const String failedTitle = "We couldn't open this code";
  static const String homeLabel = 'Go to StyleMint home';
  static const String retryLabel = 'Try again';

  final String code;
  final CodeScanVia via;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = codeResolveNotifierProvider((code: code, via: via));
    ref.listen<CodeResolveState>(provider, (_, next) {
      if (next is CodeResolved) {
        context.pushReplacement(next.target.location, extra: next.target.extra);
      }
    });
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
      ),
      body: SafeArea(
        child: switch (state) {
          CodeResolving() || CodeResolved() => const _Opening(),
          CodeNotActive() => _CodeMessage(
            icon: Icons.link_off_rounded,
            title: notActiveTitle,
            body: notActiveBody,
            primaryLabel: homeLabel,
            onPrimary: () => context.go(RouteNames.home),
          ),
          CodeResolveFailed(:final failure) => _CodeMessage(
            icon: Icons.cloud_off_rounded,
            title: failedTitle,
            body: NetworkExceptions.getMessage(failure),
            primaryLabel: retryLabel,
            onPrimary: () => unawaited(ref.read(provider.notifier).resolve()),
            secondaryLabel: homeLabel,
            onSecondary: () => context.go(RouteNames.home),
          ),
        },
      ),
    );
  }
}

class _Opening extends StatelessWidget {
  const _Opening();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SmBrandLoader(semanticLabel: CodeResolveScreen.openingLabel),
        const SizedBox(height: DesignTokens.s16),
        Text(
          CodeResolveScreen.openingLabel,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    ),
  );
}

class _CodeMessage extends StatelessWidget {
  const _CodeMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: DesignTokens.iconLight),
            const SizedBox(height: DesignTokens.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: DesignTokens.sectionInnerTitle,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(primaryLabel),
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: DesignTokens.s12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: DesignTokens.outlinedButtonStyle(),
                  child: Text(secondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
