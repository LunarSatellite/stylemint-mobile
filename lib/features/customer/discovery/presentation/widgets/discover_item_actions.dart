import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/not_interested_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A feed card with its actions: long-press anywhere or tap the "…" button.
class DiscoverActionable extends StatelessWidget {
  const DiscoverActionable({
    required this.child,
    required this.itemLabel,
    required this.onMore,
    super.key,
  });

  final Widget child;

  /// Names the card in the "…" button's label.
  final String itemLabel;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(onLongPress: onMore, child: child),
        PositionedDirectional(
          top: 2,
          end: 2,
          child: DiscoverMoreButton(
            label: 'More options for $itemLabel',
            onTap: onMore,
          ),
        ),
      ],
    );
  }
}

/// A 44dp "…" button with a small translucent disc (no blur in lists).
class DiscoverMoreButton extends StatelessWidget {
  const DiscoverMoreButton({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: DesignTokens.minTouchTarget,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DesignTokens.bgAppFoundation.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(
                dimension: 28,
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ItemAction { notInterested, report }

const TextStyle _sheetTitleStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w600,
  height: 1.3,
  color: DesignTokens.textWhite,
);

const TextStyle _sheetBodyStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 13,
  height: 1.4,
  color: DesignTokens.textMuted,
);

/// The actions sheet of a feed card: "Not interested" for every kind, plus
/// "Report" for reels.
Future<void> showDiscoverItemActions(
  BuildContext context,
  WidgetRef ref, {
  required NotInterestedTarget target,
  required String itemLabel,
}) async {
  final action = await showModalBottomSheet<_ItemAction>(
    context: context,
    backgroundColor: DesignTokens.bgAppBody,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              child: Text(
                itemLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _sheetTitleStyle,
              ),
            ),
            ListTile(
              key: const ValueKey('discover-action-not-interested'),
              leading: const Icon(
                Icons.visibility_off_outlined,
                color: DesignTokens.textLight,
              ),
              title: const Text('Not interested', style: _sheetTitleStyle),
              subtitle: Text(
                _notInterestedHint(target.kind),
                style: _sheetBodyStyle,
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_ItemAction.notInterested),
            ),
            if (target.kind == NotInterestedKind.reel)
              ListTile(
                key: const ValueKey('discover-action-report'),
                leading: const Icon(
                  Icons.flag_outlined,
                  color: DesignTokens.textLight,
                ),
                title: const Text('Report reel', style: _sheetTitleStyle),
                subtitle: const Text(
                  'Tell us what is wrong with it',
                  style: _sheetBodyStyle,
                ),
                onTap: () => Navigator.of(sheetContext).pop(_ItemAction.report),
              ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  switch (action) {
    case _ItemAction.notInterested:
      await markNotInterested(context, ref, target);
    case _ItemAction.report:
      await reportDiscoverReel(context, ref, target.id);
  }
}

/// Signs in if needed, hides [target] at once and offers Undo. A refused
/// hide brings the card back and says so.
Future<void> markNotInterested(
  BuildContext context,
  WidgetRef ref,
  NotInterestedTarget target,
) async {
  final signedIn = await ref.read(discoverAuthGateProvider)(context, ref);
  if (!signedIn || !context.mounted) return;
  final notifier = ref.read(notInterestedNotifierProvider.notifier);
  final messenger = ScaffoldMessenger.of(context);
  final hiding = notifier.hide(target);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(_hiddenMessage(target.kind)),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => unawaited(_undo(messenger, notifier, target)),
        ),
      ),
    );
  if (await hiding) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text("Couldn't hide that right now. Try again.")),
    );
}

Future<void> _undo(
  ScaffoldMessengerState messenger,
  NotInterestedNotifier notifier,
  NotInterestedTarget target,
) async {
  if (await notifier.undo(target)) return;
  messenger.showSnackBar(
    const SnackBar(content: Text("Couldn't undo that. It stays hidden.")),
  );
}

/// Signs in if needed, asks for a reason and reports the reel.
Future<void> reportDiscoverReel(
  BuildContext context,
  WidgetRef ref,
  String reelId,
) async {
  final signedIn = await ref.read(discoverAuthGateProvider)(context, ref);
  if (!signedIn || !context.mounted) return;
  final reason = await showModalBottomSheet<ReelReportReason>(
    context: context,
    backgroundColor: DesignTokens.bgAppBody,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 4),
              child: Text('Report reel', style: _sheetTitleStyle),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
              child: Text(
                'Why are you reporting this reel?',
                style: _sheetBodyStyle,
              ),
            ),
            for (final reason in ReelReportReason.values)
              ListTile(
                key: ValueKey('discover-report-${reason.code}'),
                title: Text(reason.label, style: _sheetTitleStyle),
                onTap: () => Navigator.of(sheetContext).pop(reason),
              ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final result = await ref
      .read(discoverRepositoryProvider)
      .reportReel(reelId, reason);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          result.isRight()
              ? 'Thanks. Our team will review this reel.'
              : "Couldn't send the report. Try again.",
        ),
      ),
    );
}

String _notInterestedHint(NotInterestedKind kind) => switch (kind) {
  NotInterestedKind.reel => 'Hide this reel',
  NotInterestedKind.product => 'Hide this product',
  NotInterestedKind.creator => 'Hide this creator and their reels',
  NotInterestedKind.brand => 'Hide this brand and its products',
};

String _hiddenMessage(NotInterestedKind kind) => switch (kind) {
  NotInterestedKind.reel => 'Reel hidden',
  NotInterestedKind.product => 'Product hidden',
  NotInterestedKind.creator => 'Creator hidden',
  NotInterestedKind.brand => 'Brand hidden',
};
