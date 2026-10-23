import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/presentation/journey_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/journeys/shared/journey_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Start a journey: an optional title and city, and one of my published
/// reels as step 1. Opens the new journey, where I invite the businesses
/// that come next.
class CreateJourneyScreen extends ConsumerStatefulWidget {
  const CreateJourneyScreen({super.key});

  static const Key submitKey = Key('create-journey-submit');

  @override
  ConsumerState<CreateJourneyScreen> createState() =>
      _CreateJourneyScreenState();
}

class _CreateJourneyScreenState extends ConsumerState<CreateJourneyScreen> {
  final _title = TextEditingController();
  final _city = TextEditingController();
  String? _reelId;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final reelId = _reelId;
    if (reelId == null || _busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(vendorJourneysApiProvider)
        .create(reelId: reelId, title: _title.text, city: _city.text);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (failure) => showJourneySnack(context, journeyFailureMessage(failure)),
      (journey) {
        ref.invalidate(vendorJourneysProvider);
        unawaited(context.pushReplacement(JourneyRoutes.detailPath(journey.id)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('New journey'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          children: [
            JourneyTitleFields(title: _title, city: _city),
            const ServiceSectionTitle('Your reel — step 1'),
            JourneyReelPickerList(
              journeyId: '',
              selected: _reelId,
              shrinkWrap: true,
              onSelected: (id) => setState(() => _reelId = id),
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Buyers see the journey once at least one other business has '
              'accepted your invite and added its reel.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s16),
            ServiceActionButton(
              key: CreateJourneyScreen.submitKey,
              label: 'Create journey',
              busy: _busy,
              onPressed: _reelId == null ? null : _create,
            ),
          ],
        ),
      ),
    );
  }
}
