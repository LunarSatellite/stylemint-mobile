import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/partnership_terms.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/notifiers/partnership_terms_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor → More → "Partnership terms".
///
/// Authors the two sections every creator reads before accepting a
/// partnership: who the brand will work with, and what a reel has to do.
///
/// This screen is the gate on the whole partnership feature. Until a vendor
/// has published one version, the backend refuses both
/// `POST /v1/vendor/partnerships/invite` and a creator's
/// `POST /v1/creator/partnerships/request` with "Vendor must publish
/// partnership terms before inviting a creator" — so without it a vendor can
/// neither invite anyone nor be applied to.
///
/// Publishing always writes a NEW version rather than editing the current
/// one: the server supersedes the previous version and rotates every live
/// partnership onto the new terms. There is no vendor-scoped GET for the
/// current body (the server only exposes terms through a partnership), so the
/// editor opens on the starter text below rather than on what was last
/// published. Re-publishing therefore replaces, and does not append.
class PartnershipTermsScreen extends ConsumerStatefulWidget {
  const PartnershipTermsScreen({super.key});

  @override
  ConsumerState<PartnershipTermsScreen> createState() =>
      _PartnershipTermsScreenState();
}

class _PartnershipTermsScreenState
    extends ConsumerState<PartnershipTermsScreen> {
  /// Starting points, not house rules — every line is editable and the vendor
  /// is expected to make them their own. They exist because an empty editor
  /// in front of someone who has never written partnership terms is a wall.
  static const _whoCanJoinStarters = <String>[
    'Creators with a connected Instagram, TikTok or YouTube account',
    'No active policy violations in the last 90 days',
  ];
  static const _reelRuleStarters = <String>[
    'Tag at least one of our products in the reel',
    'Show the product clearly for at least 3 seconds',
    'Do not make health, safety or performance claims about the product',
  ];

  late final TextEditingController _whoHeading = TextEditingController(
    text: PartnershipTerms.defaultWhoCanJoinHeading,
  );
  late final TextEditingController _rulesHeading = TextEditingController(
    text: PartnershipTerms.defaultReelRulesHeading,
  );

  late final List<TextEditingController> _whoBullets = [
    for (final starter in _whoCanJoinStarters)
      TextEditingController(text: starter),
  ];
  late final List<TextEditingController> _ruleBullets = [
    for (final starter in _reelRuleStarters)
      TextEditingController(text: starter),
  ];

  @override
  void dispose() {
    _whoHeading.dispose();
    _rulesHeading.dispose();
    for (final c in [..._whoBullets, ..._ruleBullets]) {
      c.dispose();
    }
    super.dispose();
  }

  PartnershipTerms get _terms => PartnershipTerms(
    whoCanJoinHeading: _whoHeading.text,
    whoCanJoin: [for (final c in _whoBullets) c.text],
    reelRulesHeading: _rulesHeading.text,
    reelRules: [for (final c in _ruleBullets) c.text],
  );

  void _addBullet(List<TextEditingController> into) {
    if (into.length >= PartnershipTerms.maxBullets) return;
    setState(() => into.add(TextEditingController()));
  }

  void _removeBullet(List<TextEditingController> from, int index) {
    // The last bullet in a section is emptied rather than removed: a section
    // with no rows at all offers nowhere to start typing again.
    if (from.length == 1) {
      setState(from.first.clear);
      return;
    }
    final removed = from.removeAt(index);
    setState(() {});
    // Disposed a frame later: its TextField is still mounted until the
    // rebuild this setState schedules has run, and a controller disposed
    // underneath a live field throws.
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  Future<void> _publish() async {
    final terms = _terms;
    if (!terms.isPublishable) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBodyLight,
        title: const Text('Publish these terms?'),
        content: const Text(
          'Every creator you already partner with moves onto this version, '
          'and every new creator sees it before accepting. Publishing again '
          'later replaces it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(partnershipTermsNotifierProvider.notifier).publish(terms);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnershipTermsNotifierProvider);
    final submitting = state is PublishTermsSubmitting;

    ref.listen<PublishTermsState>(partnershipTermsNotifierProvider, (_, next) {
      switch (next) {
        case PublishTermsSuccess():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Partnership terms published. You can now invite creators.',
              ),
            ),
          );
          Navigator.of(context).pop(true);
        case PublishTermsFailure(:final failure):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(NetworkExceptions.getMessage(failure))),
          );
        case PublishTermsIdle():
        case PublishTermsSubmitting():
          break;
      }
    });

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Partnership terms',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.s16),
              decoration: DesignTokens.cardDecoration(),
              child: const Text(
                'Creators read these before they accept a partnership with '
                'you. You have to publish them once before you can invite '
                'anyone — or before a creator can apply to you.',
                style: DesignTokens.smallDescription,
              ),
            ),
            const SizedBox(height: DesignTokens.s24),

            _Section(
              headingController: _whoHeading,
              bullets: _whoBullets,
              bulletHint: 'e.g. Creators with at least 1,000 followers',
              addLabel: 'Add a requirement',
              onAdd: () => _addBullet(_whoBullets),
              onRemove: (i) => _removeBullet(_whoBullets, i),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s24),

            _Section(
              headingController: _rulesHeading,
              bullets: _ruleBullets,
              bulletHint: 'e.g. Tag at least one of our products',
              addLabel: 'Add a rule',
              onAdd: () => _addBullet(_ruleBullets),
              onRemove: (i) => _removeBullet(_ruleBullets, i),
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: DesignTokens.s32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                // Rebuilt on every keystroke through the section's onChanged,
                // so this reflects what is actually in the fields.
                onPressed: submitting || !_terms.isPublishable
                    ? null
                    : _publish,
                child: Text(
                  submitting ? 'Publishing…' : 'Publish terms',
                  style: DesignTokens.mediumSemibold,
                ),
              ),
            ),
            if (!_terms.isPublishable) ...[
              const SizedBox(height: DesignTokens.s12),
              const Text(
                'Both sections need a heading and at least one line.',
                style: DesignTokens.smallDescription,
              ),
            ],
            const SizedBox(height: DesignTokens.s24),
          ],
        ),
      ),
    );
  }
}

/// One titled list of lines — the shape both halves of the terms share.
class _Section extends StatelessWidget {
  const _Section({
    required this.headingController,
    required this.bullets,
    required this.bulletHint,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  final TextEditingController headingController;
  final List<TextEditingController> bullets;
  final String bulletHint;
  final String addLabel;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  /// Called on every keystroke: the publish button's enabled state is derived
  /// from this text, and controllers alone do not rebuild the screen.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    void rebuild(String _) => onChanged();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: headingController,
          onChanged: rebuild,
          maxLength: PartnershipTerms.maxHeadingLength,
          style: DesignTokens.sectionInnerTitle,
          decoration: DesignTokens.inputDecoration(labelText: 'Section title'),
        ),
        const SizedBox(height: DesignTokens.s12),
        for (var i = 0; i < bullets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: bullets[i],
                    onChanged: rebuild,
                    maxLines: null,
                    maxLength: PartnershipTerms.maxBulletLength,
                    style: DesignTokens.mediumRegular,
                    decoration: DesignTokens.inputDecoration(
                      hintText: bulletHint,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(i),
                  tooltip: 'Remove this line',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        if (bullets.length < PartnershipTerms.maxBullets)
          TextButton.icon(
            style: DesignTokens.textButtonStyle(),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(addLabel),
          ),
      ],
    );
  }
}
