import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/reel_share.dart';

void main() {
  test('shares the StyleMint link with the hook line and the creator', () {
    final text = ReelShare.text(
      reelId: 'reel-1',
      caption:
          'Three ways to style one canvas tote\n'
          'Nomad Canvas Tote · Rs 1,800\n'
          'Tap the product to shop on StyleMint.\n'
          '#StyleMint #tote',
      creatorName: 'Sumendra',
    );

    expect(
      text,
      "Three ways to style one canvas tote\n\n"
      "Watch Sumendra's reel on StyleMint: "
      'https://stylemint.voyageritnepal.com/reels/reel-1',
    );
  });

  test('never carries a platform link, even one in the caption', () {
    final text = ReelShare.text(
      reelId: 'reel-2',
      caption: 'Fit check https://www.tiktok.com/@miko/video/123 #ootd',
      creatorName: 'miko',
    );

    expect(text, startsWith('Fit check\n\n'));
    expect(text, isNot(contains('tiktok.com')));
    expect(text, endsWith('https://stylemint.voyageritnepal.com/reels/reel-2'));
  });

  test('without a caption or creator it is just the invitation', () {
    expect(
      ReelShare.text(reelId: 'reel-3', caption: '', creatorName: '  '),
      'Watch this reel on StyleMint: '
      'https://stylemint.voyageritnepal.com/reels/reel-3',
    );
  });

  test('shortens a very long hook', () {
    final hook = ReelShare.hookLine('${'word ' * 60}\nsecond line');

    expect(hook.runes.length, lessThanOrEqualTo(120));
    expect(hook, endsWith('…'));
  });

  test('the link is the StyleMint reel path', () {
    expect(
      ReelShare.link('a b').toString(),
      'https://stylemint.voyageritnepal.com/reels/a%20b',
    );
  });
}
