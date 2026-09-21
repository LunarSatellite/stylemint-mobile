import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// The vendor's brand direction: the story, the presentation rules, and the
/// material to work from.
///
/// Every field here is separately nullable and the rendering depends on that.
/// The rules this widget keeps:
///
///  * A guideline the vendor never wrote draws **nothing** — no heading, no
///    placeholder, no "Not specified" row. A blank "Tone of voice" section
///    reads as a brand with no opinion on tone, which is a different claim
///    from a brand that was never asked.
///  * A guideline the vendor wrote as an empty *list* is a real answer and
///    says so. `referenceAssets: []` means "there are none", and that is
///    stated, because silently drawing nothing would make it indistinguishable
///    from a vendor who never addressed assets.
///
/// Those two rules pull in opposite directions on purpose, and the type keeps
/// them apart: null is unspecified, `[]` is specified-as-none.
class BrandDirectionSection extends StatelessWidget {
  const BrandDirectionSection({required this.direction, super.key});

  final BrandDirection? direction;

  static const noReferenceAssetsLabel =
      'The brand says there are no reference assets for this campaign.';

  @override
  Widget build(BuildContext context) {
    final d = direction;
    // Null direction is the truth about briefs authored before brand direction
    // existed: nobody specified anything. Draw nothing.
    if (d == null || d.isEmpty) return const SizedBox.shrink();

    final presentation = d.presentation;
    final assets = d.referenceAssets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(
          icon: Icons.auto_awesome_outlined,
          label: 'Brand direction',
        ),
        const SizedBox(height: 12),

        if (d.campaignStory != null)
          _Block(title: 'Campaign story', body: d.campaignStory!),

        if (presentation != null && !presentation.isEmpty) ...[
          if (presentation.brandNameUsage != null)
            _Block(
              title: 'Using the brand name',
              body: presentation.brandNameUsage!,
            ),
          if (presentation.logoAndMarkUsage != null)
            _Block(
              title: 'Logo and marks',
              body: presentation.logoAndMarkUsage!,
            ),
          if (presentation.toneOfVoice != null)
            _Block(title: 'Tone of voice', body: presentation.toneOfVoice!),
          if (presentation.mandatoryMentions != null)
            _MentionsBlock(mentions: presentation.mandatoryMentions!),
        ],

        if (assets != null) _AssetsBlock(assets: assets),

        const SizedBox(height: 4),
      ],
    );
  }
}

/// Mandatory mentions. A non-null empty list means the vendor said there are
/// none, which is stated rather than drawn as an empty list.
class _MentionsBlock extends StatelessWidget {
  const _MentionsBlock({required this.mentions});

  final List<String> mentions;

  static const noneLabel = 'The brand requires no specific mentions.';

  @override
  Widget build(BuildContext context) {
    if (mentions.isEmpty) {
      return const _Block(title: 'Mandatory mentions', body: noneLabel);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlockTitle('Mandatory mentions'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in mentions)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreenLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    m,
                    style: const TextStyle(
                      color: DesignTokens.textLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetsBlock extends StatelessWidget {
  const _AssetsBlock({required this.assets});

  final List<BrandAssetLink> assets;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const _Block(
        title: 'Reference assets',
        body: BrandDirectionSection.noReferenceAssetsLabel,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BlockTitle('Reference assets'),
          const SizedBox(height: 6),
          for (final a in assets)
            InkWell(
              onTap: () => _open(a.url),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link,
                      size: 16,
                      color: DesignTokens.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.displayLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DesignTokens.primaryGreen,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: DesignTokens.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the asset in the browser. A URL the platform refuses is dropped
  /// silently rather than crashing the brief — the rest of the direction is
  /// still worth reading.
  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: DesignTokens.textMuted),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: DesignTokens.textWhite,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: DesignTokens.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BlockTitle(title),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            color: DesignTokens.textLight,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}
