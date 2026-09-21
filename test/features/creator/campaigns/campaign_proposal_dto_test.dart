import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/models/campaign_proposal_dto.dart';

/// The mapper's whole job is keeping three things apart that all look like
/// "nothing" in JSON: an absent key, an explicit null, and an empty list.
/// The first two mean the vendor never specified anything; the third is a
/// real answer they gave.
void main() {
  group('CampaignProposalDto.fromJson', () {
    test('scales commission fractions to percent', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'commissionRange': {'minPercent': 0.12, 'maxPercent': 0.2},
      });

      expect(dto.commissionMinPercent, closeTo(12, 0.0001));
      expect(dto.commissionMaxPercent, closeTo(20, 0.0001));
    });

    test('a brief with no body carries no brand direction at all', () {
      final dto = CampaignProposalDto.fromJson({'id': 'b1'});

      // Null, not an empty BrandDirection: briefs authored before brand
      // direction existed had nobody specify anything, and that is the truth
      // the UI needs in order to draw no section.
      expect(dto.brandDirection, isNull);
      expect(dto.suggestedHooks, isEmpty);
      expect(dto.productVariantIds, isEmpty);
    });

    test('an absent guideline is null, never an empty string', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'body': {
          'brandDirection': {'campaignStory': 'A quiet morning in Patan.'},
        },
      });

      final direction = dto.brandDirection!;
      expect(direction.campaignStory, 'A quiet morning in Patan.');
      expect(direction.presentation, isNull);
      expect(direction.referenceAssets, isNull);
    });

    test('a blank guideline string is treated as absent', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'title': '   ',
        'body': {
          'brandDirection': {
            'campaignStory': '',
            'presentation': {'toneOfVoice': '  '},
          },
        },
      });

      expect(dto.title, isNull);
      expect(dto.brandDirection!.campaignStory, isNull);
      expect(dto.brandDirection!.presentation!.toneOfVoice, isNull);
    });

    test(
      'an empty reference-asset list stays empty and does not become null',
      () {
        // `[]` is the vendor saying there are no assets. Collapsing it to null
        // would make it indistinguishable from never having been asked, and
        // the UI says different things about the two.
        final dto = CampaignProposalDto.fromJson({
          'id': 'b1',
          'body': {
            'brandDirection': {'referenceAssets': <dynamic>[]},
          },
        });

        expect(dto.brandDirection!.referenceAssets, isNotNull);
        expect(dto.brandDirection!.referenceAssets, isEmpty);
      },
    );

    test('an empty mandatory-mentions list stays empty and not null', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'body': {
          'brandDirection': {
            'presentation': {'mandatoryMentions': <dynamic>[]},
          },
        },
      });

      expect(
        dto.brandDirection!.presentation!.mandatoryMentions,
        isNotNull,
      );
      expect(dto.brandDirection!.presentation!.mandatoryMentions, isEmpty);
    });

    test('drops asset links that carry no url', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'body': {
          'brandDirection': {
            'referenceAssets': [
              {'url': 'https://example.test/logo.zip', 'label': 'Logos'},
              {'label': 'Broken'},
            ],
          },
        },
      });

      final assets = dto.brandDirection!.referenceAssets!;
      expect(assets, hasLength(1));
      expect(assets.single.displayLabel, 'Logos');
    });

    test('an unlabelled asset falls back to showing its url', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'body': {
          'brandDirection': {
            'referenceAssets': [
              {'url': 'https://example.test/shotlist.pdf'},
            ],
          },
        },
      });

      final asset = dto.brandDirection!.referenceAssets!.single;
      expect(asset.label, isNull);
      expect(asset.displayLabel, 'https://example.test/shotlist.pdf');
    });

    test('an unparseable window timestamp becomes null, not an instant', () {
      final dto = CampaignProposalDto.fromJson({
        'id': 'b1',
        'applicationsCloseUtc': 'not-a-date',
      });

      // A fallback instant here would tell a creator a campaign is open when
      // it is closed, or the reverse.
      expect(dto.applicationsCloseUtc, isNull);
    });

    test('toDomain derives the commission midpoint', () {
      final proposal = CampaignProposalDto.fromJson({
        'id': 'b1',
        'commissionRange': {'minPercent': 0.1, 'maxPercent': 0.2},
      }).toDomain();

      expect(proposal.commission.midpointPercent, closeTo(15, 0.0001));
      expect(proposal.commission.label, '10-20%');
    });
  });
}
