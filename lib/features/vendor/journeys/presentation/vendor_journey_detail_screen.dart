import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/data/vendor_journeys_api.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/domain/vendor_journey.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/journey_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/vendor_journeys_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One journey, from wherever I stand in it.
///
///  * Owner: invite businesses, drag steps into order, remove a step (or
///    cancel an invite), replace my reel, rename, end the journey.
///  * Member: replace my reel, leave.
///  * Invitee: accept by picking one of my reels, or decline.
///
/// The screen journey notifications open (`/vendor/journeys/{id}`).
class VendorJourneyDetailScreen extends ConsumerStatefulWidget {
  const VendorJourneyDetailScreen({required this.journeyId, super.key});

  final String journeyId;

  static const Key inviteKey = Key('journey-detail-invite');
  static const Key editKey = Key('journey-detail-edit');
  static const Key endKey = Key('journey-detail-end');
  static const Key leaveKey = Key('journey-detail-leave');
  static const Key replaceKey = Key('journey-detail-replace');
  static const Key acceptKey = Key('journey-detail-accept');
  static const Key declineKey = Key('journey-detail-decline');
  static Key stepKey(String stepId) => Key('journey-step-$stepId');
  static Key dragKey(String stepId) => Key('journey-step-drag-$stepId');
  static Key removeKey(String stepId) => Key('journey-step-remove-$stepId');

  @override
  ConsumerState<VendorJourneyDetailScreen> createState() =>
      _VendorJourneyDetailScreenState();
}

class _VendorJourneyDetailScreenState
    extends ConsumerState<VendorJourneyDetailScreen> {
  /// The journey as the last change returned it, ahead of a reload.
  VendorJourney? _latest;
  bool _busy = false;

  VendorJourneysApi get _api => ref.read(vendorJourneysApiProvider);

  Future<void> _reload() async {
    setState(() => _latest = null);
    ref.invalidate(vendorJourneysProvider);
    await ref.refresh(vendorJourneyProvider(widget.journeyId).future);
  }

  /// Runs a change that answers with the journey, and shows the answer.
  Future<void> _change(
    Future<Either<ServiceFailure, VendorJourney>> Function() call, {
    String? done,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => showJourneySnack(context, journeyFailureMessage(failure)),
      (journey) {
        setState(() => _latest = journey);
        ref.invalidate(vendorJourneysProvider);
        if (done != null) showJourneySnack(context, done);
      },
    );
  }

  /// Runs a change after which this journey is no longer mine (leave,
  /// decline), and goes back to the list.
  Future<void> _exit(
    Future<Either<ServiceFailure, Object>> Function() call,
    String done,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await call();
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => showJourneySnack(context, journeyFailureMessage(failure)),
      (_) {
        ref.invalidate(vendorJourneysProvider);
        showJourneySnack(context, done);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(JourneyRoutes.list);
        }
      },
    );
  }

  Future<void> _invite(VendorJourney journey) async {
    final choice = await pickJourneyInvitee(context);
    if (choice == null || !mounted) return;
    await _change(
      () => _api.invite(
        journey.id,
        vendorAccountId: choice.vendor.vendorAccountId,
        note: choice.note,
      ),
      done: 'Invite sent to ${choice.vendor.businessName}.',
    );
  }

  Future<void> _edit(VendorJourney journey) async {
    final edited = await editJourneyTitle(
      context,
      title: journey.title,
      city: journey.city,
    );
    if (edited == null || !mounted) return;
    await _change(
      () => _api.update(journey.id, title: edited.title, city: edited.city),
    );
  }

  Future<void> _end(VendorJourney journey) async {
    final ok = await confirmServiceAction(
      context,
      title: 'End this journey?',
      message:
          'Buyers stop seeing it and every business in it is told. Their '
          'reels stay as they are. This cannot be undone.',
      confirmLabel: 'End journey',
    );
    if (!ok || !mounted) return;
    await _change(() => _api.end(journey.id), done: 'Journey ended.');
  }

  Future<void> _remove(VendorJourney journey, VendorJourneyStep step) async {
    final invite = step.isInvite;
    final ok = await confirmServiceAction(
      context,
      title: invite ? 'Cancel this invite?' : 'Remove ${step.vendorName}?',
      message: invite
          ? '${step.vendorName} will not be able to accept it any more.'
          : "Their step leaves the journey. Their reel isn't changed.",
      confirmLabel: invite ? 'Cancel invite' : 'Remove',
    );
    if (!ok || !mounted) return;
    await _change(() => _api.removeStep(journey.id, step.id));
  }

  Future<void> _replace(VendorJourney journey) async {
    final step = journey.myStep;
    if (step == null) return;
    final reelId = await pickJourneyReel(
      context,
      journeyId: journey.id,
      title: 'Replace your reel',
      confirmLabel: 'Use this reel',
      current: step.reelId,
    );
    if (reelId == null || !mounted) return;
    await _change(
      () => _api.replaceReel(journey.id, step.id, reelId: reelId),
      done: 'Your reel was replaced.',
    );
  }

  Future<void> _accept(VendorJourney journey) async {
    final stepId = journey.myStepId;
    if (stepId == null) return;
    final reelId = await pickJourneyReel(
      context,
      journeyId: journey.id,
      title: 'Pick the reel for your step',
      confirmLabel: 'Join journey',
    );
    if (reelId == null || !mounted) return;
    await _change(
      () => _api.accept(journey.id, stepId, reelId: reelId),
      done: "You're in the journey.",
    );
  }

  Future<void> _decline(VendorJourney journey) async {
    final stepId = journey.myStepId;
    if (stepId == null) return;
    final ok = await confirmServiceAction(
      context,
      title: 'Decline this invite?',
      message: '${journey.ownerName} will be told you declined.',
      confirmLabel: 'Decline',
    );
    if (!ok || !mounted) return;
    await _exit(() => _api.decline(journey.id, stepId), 'Invite declined.');
  }

  Future<void> _leave(VendorJourney journey) async {
    final ok = await confirmServiceAction(
      context,
      title: 'Leave this journey?',
      message:
          'Your step disappears from it and ${journey.ownerName} is told. '
          'Your reel stays as it is.',
      confirmLabel: 'Leave',
    );
    if (!ok || !mounted) return;
    await _exit(() => _api.leave(journey.id), 'You left the journey.');
  }

  Future<void> _reorder(VendorJourney journey, int from, int to) async {
    if (_busy) return;
    final target = to > from ? to - 1 : to;
    if (target == from) return;
    final steps = [...journey.steps];
    final moved = steps.removeAt(from);
    steps.insert(target, moved);
    final before = journey;
    // Shown at once; the server's answer replaces it, or it snaps back.
    setState(() {
      _latest = journey.withSteps(steps);
      _busy = true;
    });
    final result = await _api.reorder(journey.id, [
      for (final step in steps) step.id,
    ]);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _latest = result.fold((_) => before, (saved) => saved);
    });
    result.fold(
      (failure) => showJourneySnack(context, journeyFailureMessage(failure)),
      (_) => ref.invalidate(vendorJourneysProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loaded = ref.watch(vendorJourneyProvider(widget.journeyId));
    final journey = _latest ?? loaded.value;
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text(journey?.displayTitle ?? 'Journey'),
        actions: [
          if (journey != null && journey.isOwner && !journey.isEnded)
            IconButton(
              key: VendorJourneyDetailScreen.editKey,
              tooltip: 'Edit title and city',
              onPressed: _busy ? null : () => _edit(journey),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: journey != null
            ? RefreshIndicator(onRefresh: _reload, child: _body(journey))
            : loaded.hasError
            ? ListView(
                children: [
                  ServiceLoadFailureView(
                    error: loaded.error!,
                    settingUpTitle: 'Journeys are being set up',
                    specific: journeyErrorMessage,
                    onRetry: () => ref.invalidate(
                      vendorJourneyProvider(widget.journeyId),
                    ),
                  ),
                ],
              )
            : const SmPageLoader(),
      ),
    );
  }

  Widget _body(VendorJourney journey) {
    final canReorder =
        journey.isOwner && !journey.isEnded && journey.steps.length > 1;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      buildDefaultDragHandles: false,
      header: _Header(journey: journey, canReorder: canReorder),
      footer: _actions(journey),
      itemCount: journey.steps.length,
      onReorder: (from, to) {
        if (canReorder) unawaited(_reorder(journey, from, to));
      },
      itemBuilder: (context, i) {
        final step = journey.steps[i];
        return _StepTile(
          key: VendorJourneyDetailScreen.stepKey(step.id),
          index: i,
          step: step,
          isMine: step.id == journey.myStepId,
          isOwnerStep: journey.isOwnerStep(step),
          canReorder: canReorder && !_busy,
          onRemove:
              journey.isOwner && !journey.isEnded && !journey.isOwnerStep(step)
              ? () => _remove(journey, step)
              : null,
        );
      },
    );
  }

  Widget _actions(VendorJourney journey) {
    if (journey.isEnded) return const SizedBox.shrink();
    final mine = journey.myStep;
    final children = <Widget>[];
    void add(Widget child) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: DesignTokens.s8));
      }
      children.add(child);
    }

    if (journey.isInvitee) {
      add(
        ServiceActionButton(
          key: VendorJourneyDetailScreen.acceptKey,
          label: 'Accept and pick my reel',
          icon: Icons.check_rounded,
          busy: _busy,
          onPressed: () => _accept(journey),
        ),
      );
      add(
        ServiceActionButton(
          key: VendorJourneyDetailScreen.declineKey,
          label: 'Decline',
          outlined: true,
          destructive: true,
          onPressed: _busy ? null : () => _decline(journey),
        ),
      );
    } else {
      if (journey.isOwner) {
        add(
          ServiceActionButton(
            key: VendorJourneyDetailScreen.inviteKey,
            label: journey.canAddSteps
                ? 'Invite a business'
                : 'Journey is full (${journey.maxSteps} steps)',
            icon: Icons.person_add_alt_1_rounded,
            busy: _busy,
            onPressed: journey.canAddSteps ? () => _invite(journey) : null,
          ),
        );
      }
      if (mine != null && mine.state == JourneyStepState.active) {
        add(
          ServiceActionButton(
            key: VendorJourneyDetailScreen.replaceKey,
            label: 'Replace my reel',
            icon: Icons.swap_horiz_rounded,
            outlined: true,
            onPressed: _busy ? null : () => _replace(journey),
          ),
        );
      }
      if (journey.isOwner) {
        add(
          ServiceActionButton(
            key: VendorJourneyDetailScreen.endKey,
            label: 'End journey',
            outlined: true,
            destructive: true,
            onPressed: _busy ? null : () => _end(journey),
          ),
        );
      } else {
        add(
          ServiceActionButton(
            key: VendorJourneyDetailScreen.leaveKey,
            label: 'Leave journey',
            outlined: true,
            destructive: true,
            onPressed: _busy ? null : () => _leave(journey),
          ),
        );
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s20),
      child: Column(children: children),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.journey, required this.canReorder});

  final VendorJourney journey;
  final bool canReorder;

  @override
  Widget build(BuildContext context) {
    final city = journey.city;
    final invite = journey.isInvitee ? journey.myStep : null;
    final note = invite?.inviteNote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ServiceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      journey.displayTitle,
                      style: DesignTokens.mediumSemibold,
                    ),
                  ),
                  JourneyStatusPill(journey: journey),
                ],
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                [
                  if (city != null) city,
                  if (journey.isOwner) 'Your journey' else 'By ${journey.ownerName}',
                ].join(' · '),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              if (!journey.isEnded && !journey.isLive) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Buyers see it once at least 2 steps have a published reel.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
              if (journey.isEnded) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  journey.endedByAdmin
                      ? 'Ended by StyleMint${journey.endReason == null ? '' : ': ${journey.endReason}'}'
                      : 'This journey has ended. Buyers no longer see it.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (invite != null) ...[
          const SizedBox(height: DesignTokens.s12),
          ServiceCard(
            borderColor: DesignTokens.colorInfo,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${journey.ownerName} invited you to add a step',
                  style: DesignTokens.mediumSemibold,
                ),
                if (note != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text('"$note"', style: DesignTokens.smallRegular),
                ],
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Pick one of your published reels to accept. Your reel keeps '
                  'its own tags — buyers add your items to their cart as usual.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
        ServiceSectionTitle(
          canReorder ? 'Steps — drag to reorder' : 'Steps',
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    required this.isMine,
    required this.isOwnerStep,
    required this.canReorder,
    this.onRemove,
    super.key,
  });

  final int index;
  final VendorJourneyStep step;
  final bool isMine;
  final bool isOwnerStep;
  final bool canReorder;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final hidden = step.hiddenReason.sentence;
    final caption = step.caption?.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: ServiceCard(
        padding: const EdgeInsets.all(DesignTokens.s8),
        borderColor: isMine ? DesignTokens.primaryGreen : null,
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: DesignTokens.bgAppBodyLight,
              child: Text(
                '${index + 1}',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            JourneyThumb(url: step.thumbnailUrl, size: 40),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      step.vendorName,
                      if (isMine) '(you)',
                      if (isOwnerStep && !isMine) '· owner',
                    ].join(' '),
                    style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (caption != null && caption.isNotEmpty)
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  const SizedBox(height: 2),
                  if (step.isInvite)
                    const ServicePill('Invited', tone: ServicePillTone.info)
                  else if (hidden != null)
                    Text(
                      hidden,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.colorWarning,
                      ),
                    )
                  else
                    const ServicePill('Visible', tone: ServicePillTone.success),
                ],
              ),
            ),
            if (onRemove != null)
              IconButton(
                key: VendorJourneyDetailScreen.removeKey(step.id),
                tooltip: step.isInvite
                    ? 'Cancel invite to ${step.vendorName}'
                    : 'Remove ${step.vendorName}',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: DesignTokens.colorError,
                ),
              ),
            if (canReorder)
              ReorderableDragStartListener(
                key: VendorJourneyDetailScreen.dragKey(step.id),
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(DesignTokens.s8),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: DesignTokens.textMuted,
                    semanticLabel: 'Drag to reorder',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
