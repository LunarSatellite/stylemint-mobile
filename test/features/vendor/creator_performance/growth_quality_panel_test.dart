import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/widgets/growth_quality_panel.dart';

void main() {
  test('parses authoritative growth and supporting community evidence', () {
    final board = GrowthQualityBoard.fromJson({
      'activePartnerships': 4,
      'attributedRevenue': 24500,
      'affiliateConversions': 8,
      'evidencePolicy': 'Commerce is authoritative.',
      'creators': [
        {
          'creatorId': 'creator-1',
          'qualityScore': 76,
          'recommendation': 'scale_partnership',
          'attributedRevenue': 16000,
          'affiliateConversions': 6,
          'communityReactions': 91,
          'qualityRiskSignals': 0,
        },
      ],
    });

    expect(board.activePartnerships, 4);
    expect(board.attributedRevenue, 24500);
    expect(board.creators.single.action, 'Scale this partnership');
    expect(board.creators.single.communityReactions, 91);
  });

  test('quality risk always produces a review action label', () {
    final creator = GrowthQualityCreator.fromJson({
      'creatorId': 'creator-2',
      'qualityScore': 82,
      'recommendation': 'review_quality_risk',
      'attributedRevenue': 50000,
      'affiliateConversions': 20,
      'communityReactions': 200,
      'qualityRiskSignals': 2,
    });

    expect(creator.action, 'Review quality risk before spend');
    expect(creator.riskSignals, 2);
  });
}
