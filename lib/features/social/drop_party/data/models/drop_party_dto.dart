import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'drop_party_dto.freezed.dart';
part 'drop_party_dto.g.dart';

@freezed
abstract class DropPartyDto with _$DropPartyDto {
  const factory DropPartyDto({
    required String id,
    required String title,
    required String description,
    required String productId,
    required String productName,
    required String productImageUrl,
    required double originalAmount,
    @Default('NPR') String originalCurrency,
    required double dropAmount,
    @Default('NPR') String dropCurrency,
    required int maxParticipants,
    required int currentParticipants,
    required DateTime startsAt,
    required DateTime endsAt,
    required String inviteCode,
    required String status,
    required String hostId,
    required String hostName,
    required String hostAvatarUrl,
    @Default(false) bool isJoined,
  }) = _DropPartyDto;

  const DropPartyDto._();

  factory DropPartyDto.fromJson(Map<String, dynamic> json) =>
      _$DropPartyDtoFromJson(json);

  DropParty toDomain() => DropParty(
    id: id,
    title: title,
    description: description,
    productId: productId,
    productName: productName,
    productImageUrl: productImageUrl,
    originalPrice: Money(amount: originalAmount, currency: originalCurrency),
    dropPrice: Money(amount: dropAmount, currency: dropCurrency),
    maxParticipants: maxParticipants,
    currentParticipants: currentParticipants,
    startsAt: startsAt,
    endsAt: endsAt,
    inviteCode: inviteCode,
    status: _parseStatus(status),
    hostId: hostId,
    hostName: hostName,
    hostAvatarUrl: hostAvatarUrl,
    isJoined: isJoined,
  );

  static DropPartyStatus _parseStatus(String s) {
    switch (s) {
      case 'upcoming':
        return DropPartyStatus.upcoming;
      case 'live':
        return DropPartyStatus.live;
      case 'sold_out':
        return DropPartyStatus.soldOut;
      default:
        return DropPartyStatus.ended;
    }
  }
}

@freezed
abstract class DropPartyInviteDto with _$DropPartyInviteDto {
  const factory DropPartyInviteDto({
    required String id,
    required String partyId,
    required String invitedBy,
    required String invitedUserId,
    required String invitedUserName,
    required String status,
    required DateTime createdAt,
  }) = _DropPartyInviteDto;

  const DropPartyInviteDto._();

  factory DropPartyInviteDto.fromJson(Map<String, dynamic> json) =>
      _$DropPartyInviteDtoFromJson(json);
}
