import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class GroupProduct {
  const GroupProduct({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.recommenderName,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final Money price;
  final String recommenderName;

  GroupProduct copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    Money? price,
    String? recommenderName,
  }) {
    return GroupProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      recommenderName: recommenderName ?? this.recommenderName,
    );
  }
}

class StyleGroup {
  const StyleGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImageUrl,
    required this.category,
    required this.memberCount,
    required this.isJoined,
    required this.isPrivate,
    required this.createdAt,
    required this.topProducts,
  });

  final String id;
  final String name;
  final String description;
  final String coverImageUrl;
  final String category;
  final int memberCount;
  final bool isJoined;
  final bool isPrivate;
  final DateTime createdAt;
  final List<GroupProduct> topProducts;

  StyleGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImageUrl,
    String? category,
    int? memberCount,
    bool? isJoined,
    bool? isPrivate,
    DateTime? createdAt,
    List<GroupProduct>? topProducts,
  }) {
    return StyleGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      memberCount: memberCount ?? this.memberCount,
      isJoined: isJoined ?? this.isJoined,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      topProducts: topProducts ?? this.topProducts,
    );
  }
}

class GroupPost {
  const GroupPost({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.content,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String content;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  GroupPost copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? content,
    List<String>? images,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return GroupPost(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      content: content ?? this.content,
      images: images ?? this.images,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
