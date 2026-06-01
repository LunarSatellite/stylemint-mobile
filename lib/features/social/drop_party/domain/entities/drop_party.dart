import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum DropPartyStatus { upcoming, live, ended, soldOut }

class DropParty {
  const DropParty({
    required this.id,
    required this.title,
    required this.description,
    required this.productId,
    required this.productName,
    required this.productImageUrl,
    required this.originalPrice,
    required this.dropPrice,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.startsAt,
    required this.endsAt,
    required this.inviteCode,
    required this.status,
    required this.hostId,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.isJoined,
  });

  final String id;
  final String title;
  final String description;
  final String productId;
  final String productName;
  final String productImageUrl;
  final Money originalPrice;
  final Money dropPrice;
  final int maxParticipants;
  final int currentParticipants;
  final DateTime startsAt;
  final DateTime endsAt;
  final String inviteCode;
  final DropPartyStatus status;
  final String hostId;
  final String hostName;
  final String hostAvatarUrl;
  final bool isJoined;

  DropParty copyWith({
    String? id,
    String? title,
    String? description,
    String? productId,
    String? productName,
    String? productImageUrl,
    Money? originalPrice,
    Money? dropPrice,
    int? maxParticipants,
    int? currentParticipants,
    DateTime? startsAt,
    DateTime? endsAt,
    String? inviteCode,
    DropPartyStatus? status,
    String? hostId,
    String? hostName,
    String? hostAvatarUrl,
    bool? isJoined,
  }) {
    return DropParty(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      originalPrice: originalPrice ?? this.originalPrice,
      dropPrice: dropPrice ?? this.dropPrice,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      inviteCode: inviteCode ?? this.inviteCode,
      status: status ?? this.status,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

enum DropPartyInviteStatus { pending, accepted, declined }

class DropPartyInvite {
  const DropPartyInvite({
    required this.id,
    required this.partyId,
    required this.invitedBy,
    required this.invitedUserId,
    required this.invitedUserName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String partyId;
  final String invitedBy;
  final String invitedUserId;
  final String invitedUserName;
  final DropPartyInviteStatus status;
  final DateTime createdAt;

  DropPartyInvite copyWith({
    String? id,
    String? partyId,
    String? invitedBy,
    String? invitedUserId,
    String? invitedUserName,
    DropPartyInviteStatus? status,
    DateTime? createdAt,
  }) {
    return DropPartyInvite(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedUserId: invitedUserId ?? this.invitedUserId,
      invitedUserName: invitedUserName ?? this.invitedUserName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
