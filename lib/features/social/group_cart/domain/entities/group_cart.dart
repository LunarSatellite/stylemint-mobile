import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum GroupCartStatus { active, checkout, completed }

class GroupCart {
  const GroupCart({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.ownerName,
    required this.participants,
    required this.items,
    required this.subtotal,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String ownerId;
  final String ownerName;
  final List<GroupCartParticipant> participants;
  final List<GroupCartItem> items;
  final Money subtotal;
  final GroupCartStatus status;
  final DateTime createdAt;

  GroupCart copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? ownerId,
    String? ownerName,
    List<GroupCartParticipant>? participants,
    List<GroupCartItem>? items,
    Money? subtotal,
    GroupCartStatus? status,
    DateTime? createdAt,
  }) {
    return GroupCart(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      participants: participants ?? this.participants,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GroupCartParticipant {
  const GroupCartParticipant({
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.itemsAdded,
  });

  final String userId;
  final String userName;
  final String userAvatarUrl;
  final int itemsAdded;

  GroupCartParticipant copyWith({
    String? userId,
    String? userName,
    String? userAvatarUrl,
    int? itemsAdded,
  }) {
    return GroupCartParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      itemsAdded: itemsAdded ?? this.itemsAdded,
    );
  }
}

class GroupCartItem {
  const GroupCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.addedBy,
    required this.addedByName,
  });

  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final Money unitPrice;
  final String addedBy;
  final String addedByName;

  GroupCartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    int? quantity,
    Money? unitPrice,
    String? addedBy,
    String? addedByName,
  }) {
    return GroupCartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      addedBy: addedBy ?? this.addedBy,
      addedByName: addedByName ?? this.addedByName,
    );
  }
}
