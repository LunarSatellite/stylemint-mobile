import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/data/product_reel_ref_json.dart';

/// The `reel` field is not on the server yet, so every one of these shapes is
/// something the client may actually be handed. None of them may throw, and
/// none may cost the page a product: "no reel" simply means the type tile.
void main() {
  test('reads the contract shape', () {
    final reel = readProductReelRef({
      'reelId': '7b1f1e64-0f1a-4f5f-9a6b-0c2f2a9d4f11',
      'posterUrl': 'https://cdn.example.com/poster.jpg',
      'sourcePlatform': 1,
      'externalId': 'abc123',
      'hook': 'Styled three ways',
      'isAiGenerated': true,
      'durationSeconds': 12,
    });

    expect(reel, isNotNull);
    expect(reel!.reelId, '7b1f1e64-0f1a-4f5f-9a6b-0c2f2a9d4f11');
    expect(reel.posterUrl, 'https://cdn.example.com/poster.jpg');
    expect(reel.platform, SocialPlatform.instagram);
    expect(reel.externalId, 'abc123');
    expect(reel.hook, 'Styled three ways');
    expect(reel.isAiGenerated, isTrue);
    expect(reel.durationSeconds, 12);
  });

  test('an absent, null or non-object reel reads as no reel', () {
    expect(readProductReelRef(null), isNull);
    expect(readProductReelRef(''), isNull);
    expect(readProductReelRef(const []), isNull);
    expect(readProductReelRef(const <String, dynamic>{}), isNull);
  });

  test('a reel with no usable id reads as no reel', () {
    expect(readProductReelRef(const {'posterUrl': 'https://x/y.jpg'}), isNull);
    expect(readProductReelRef(const {'reelId': '   '}), isNull);
  });

  test('missing optional fields leave the tile something to draw', () {
    final reel = readProductReelRef(const {'reelId': 'r-1'});

    expect(reel, isNotNull);
    expect(reel!.posterUrl, isNull);
    expect(reel.platform, isNull);
    expect(reel.hook, isNull);
    expect(reel.isAiGenerated, isFalse);
    expect(reel.durationSeconds, 0);
  });

  test('the AI flag is only ever what the server sent', () {
    expect(readProductReelRef(const {'reelId': 'r'})!.isAiGenerated, isFalse);
    // A truthy-looking string is not `true`: the disclosure is never guessed.
    expect(
      readProductReelRef(const {'reelId': 'r', 'isAiGenerated': 'true'})!
          .isAiGenerated,
      isFalse,
    );
  });

  test('odd numbers and strings never break a product card', () {
    expect(
      readProductReelRef(const {'reelId': 'r', 'durationSeconds': -4})!
          .durationSeconds,
      0,
    );
    expect(
      readProductReelRef(const {'reelId': 'r', 'durationSeconds': 11.6})!
          .durationSeconds,
      12,
    );
    expect(
      readProductReelRef(const {'reelId': 'r', 'durationSeconds': '30'})!
          .durationSeconds,
      30,
    );
    // The platform arrives as an int on one endpoint and PascalCase on
    // another; an unknown value is null rather than a wrong player.
    expect(
      readProductReelRef(const {
        'reelId': 'r',
        'sourcePlatform': 'YouTubeShorts',
      })!.platform,
      SocialPlatform.youtube,
    );
    expect(
      readProductReelRef(const {'reelId': 'r', 'sourcePlatform': 'Myspace'})!
          .platform,
      isNull,
    );
  });

  test('an id sent unquoted still reads', () {
    expect(readProductReelRef(const {'reelId': 42})!.reelId, '42');
  });
}
