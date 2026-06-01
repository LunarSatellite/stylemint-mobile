import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class RecommendationTaggedProduct {
  const RecommendationTaggedProduct({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final Money price;

  RecommendationTaggedProduct copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    Money? price,
  }) {
    return RecommendationTaggedProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }
}

class RecommendationRequest {
  const RecommendationRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.question,
    this.context,
    required this.taggedCategories,
    required this.taggedProducts,
    required this.replyCount,
    required this.createdAt,
    this.expiresAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String question;
  final String? context;
  final List<String> taggedCategories;
  final List<RecommendationTaggedProduct> taggedProducts;
  final int replyCount;
  final DateTime createdAt;
  final DateTime? expiresAt;

  RecommendationRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? question,
    String? context,
    List<String>? taggedCategories,
    List<RecommendationTaggedProduct>? taggedProducts,
    int? replyCount,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return RecommendationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      question: question ?? this.question,
      context: context ?? this.context,
      taggedCategories: taggedCategories ?? this.taggedCategories,
      taggedProducts: taggedProducts ?? this.taggedProducts,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class RecommendationReply {
  const RecommendationReply({
    required this.id,
    required this.requestId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    this.suggestedProduct,
    this.suggestedProductUrl,
    required this.likeCount,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final String? suggestedProduct;
  final String? suggestedProductUrl;
  final int likeCount;
  final DateTime createdAt;

  RecommendationReply copyWith({
    String? id,
    String? requestId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    String? suggestedProduct,
    String? suggestedProductUrl,
    int? likeCount,
    DateTime? createdAt,
  }) {
    return RecommendationReply(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      suggestedProduct: suggestedProduct ?? this.suggestedProduct,
      suggestedProductUrl: suggestedProductUrl ?? this.suggestedProductUrl,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
