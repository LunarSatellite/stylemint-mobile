import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class FeedPost {
  const FeedPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.images,
    required this.taggedProducts,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isLiked,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final List<String> images;
  final List<FeedTaggedProduct> taggedProducts;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final DateTime createdAt;

  FeedPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    List<String>? images,
    List<FeedTaggedProduct>? taggedProducts,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return FeedPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      images: images ?? this.images,
      taggedProducts: taggedProducts ?? this.taggedProducts,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class FeedTaggedProduct {
  const FeedTaggedProduct({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final Money price;

  FeedTaggedProduct copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    Money? price,
  }) {
    return FeedTaggedProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }
}

class FeedComment {
  const FeedComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final DateTime createdAt;

  FeedComment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    DateTime? createdAt,
  }) {
    return FeedComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
