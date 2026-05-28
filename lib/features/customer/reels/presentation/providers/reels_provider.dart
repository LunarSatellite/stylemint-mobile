import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'reels_provider.g.dart';

/// Provides the reels feed - fetches and manages list of reels
/// TODO: Replace mock data with actual domain use case calls
@riverpod
Future<List<Reel>> reelsFeed(ReelsFeedRef ref) async {
  // TODO: Call GetReelsFeedUseCase here
  // For now, returning mock data to demonstrate UI
  await Future.delayed(const Duration(milliseconds: 500));

  return [
    Reel(
      id: '1',
      sourceUrl: 'https://www.instagram.com/reel/ABC123',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
      creatorId: 'creator_1',
      creatorName: 'Shree Teen',
      creatorAvatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=40',
      caption:
          'New Year calls for rich, delicious cakes 🎉🍫',
      musicTitle: 'Alice In Chains - Nutshell',
      musicArtist: 'Alice In Chains',
      taggedProducts: [
        TaggedProductEntity(
          id: 'prod_1',
          name: 'Chocolate Oreo Raspberry Cake',
          imageUrl:
              'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=100',
          price: Money(amount: 5000, currency: 'NPR'),
          quantity: 1,
        ),
        TaggedProductEntity(
          id: 'prod_2',
          name: 'Blueberry Cheese Cake',
          imageUrl:
              'https://images.unsplash.com/photo-1533134242443-742c28f36de5?w=100',
          price: Money(amount: 5000, currency: 'NPR'),
          quantity: 1,
        ),
      ],
      likeCount: 1250,
      commentCount: 89,
      shareCount: 234,
      isLikedByUser: false,
      isWishlistedByUser: false,
      isCreatorFollowed: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Reel(
      id: '2',
      sourceUrl: 'https://www.tiktok.com/@example/video/12345',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1517457373614-b7152f800529?w=400',
      creatorId: 'creator_2',
      creatorName: 'Fashion Guru',
      creatorAvatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=40',
      caption:
          'The all new meta quest 3 pro from meta beats the apple vision pro at everything',
      musicTitle: 'Levitating - Dua Lipa',
      musicArtist: 'Dua Lipa',
      taggedProducts: [
        TaggedProductEntity(
          id: 'prod_3',
          name: 'MetaQuest 3 Pro 2026 VR Headset',
          imageUrl:
              'https://images.unsplash.com/photo-1577720643272-265f434a4d11?w=100',
          price: Money(amount: 135000, currency: 'NPR'),
          quantity: 1,
        ),
      ],
      likeCount: 5420,
      commentCount: 342,
      shareCount: 1203,
      isLikedByUser: true,
      isWishlistedByUser: true,
      isCreatorFollowed: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Reel(
      id: '3',
      sourceUrl: 'https://www.youtube.com/@example/shorts/ABC456',
      thumbnailUrl:
          'https://images.unsplash.com/photo-1552062407-291c33eea82a?w=400',
      creatorId: 'creator_3',
      creatorName: 'Tech Reviews',
      creatorAvatarUrl:
          'https://images.unsplash.com/photo-1501746074465-4cebaf45b800?w=40',
      caption: 'Latest smartphone unboxing and review',
      musicTitle: 'Blinding Lights - The Weeknd',
      musicArtist: 'The Weeknd',
      taggedProducts: [
        TaggedProductEntity(
          id: 'prod_4',
          name: 'Latest Smartphone Pro Max',
          imageUrl:
              'https://images.unsplash.com/photo-1511707267537-b85faf00021e?w=100',
          price: Money(amount: 89999, currency: 'NPR'),
          quantity: 1,
        ),
      ],
      likeCount: 3890,
      commentCount: 267,
      shareCount: 890,
      isLikedByUser: false,
      isWishlistedByUser: false,
      isCreatorFollowed: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
  ];
}

/// Provider for individual reel detail
@riverpod
Future<Reel?> reelDetail(ReelDetailRef ref, String reelId) async {
  final reels = await ref.watch(reelsFeedProvider.future);
  try {
    return reels.firstWhere((reel) => reel.id == reelId);
  } catch (e) {
    return null;
  }
}

/// Provider for managing user interactions with reels
@riverpod
class ReelInteractions extends _$ReelInteractions {
  @override
  Future<Map<String, dynamic>> build() async {
    return {};
  }

  Future<void> likeReel(String reelId) async {
    // TODO: Call LikeReelUseCase
    state = AsyncData({
      ...?state.value,
      'liked_$reelId': true,
    });
  }

  Future<void> unlikeReel(String reelId) async {
    // TODO: Call UnlikeReelUseCase
    state = AsyncData({
      ...?state.value,
      'liked_$reelId': false,
    });
  }

  Future<void> addToWishlist(String reelId) async {
    // TODO: Call AddToWishlistUseCase
    state = AsyncData({
      ...?state.value,
      'wishlisted_$reelId': true,
    });
  }

  Future<void> followCreator(String creatorId) async {
    // TODO: Call FollowCreatorUseCase
    state = AsyncData({
      ...?state.value,
      'following_$creatorId': true,
    });
  }
}
