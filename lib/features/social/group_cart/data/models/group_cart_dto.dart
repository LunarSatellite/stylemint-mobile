import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'group_cart_dto.freezed.dart';
part 'group_cart_dto.g.dart';

@freezed
abstract class GroupCartParticipantDto with _$GroupCartParticipantDto {
  const factory GroupCartParticipantDto({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    @Default(0) int itemsAdded,
  }) = _GroupCartParticipantDto;

  const GroupCartParticipantDto._();

  factory GroupCartParticipantDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCartParticipantDtoFromJson(json);

  GroupCartParticipant toDomain() => GroupCartParticipant(
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    itemsAdded: itemsAdded,
  );
}

@freezed
abstract class GroupCartItemDto with _$GroupCartItemDto {
  const factory GroupCartItemDto({
    required String id,
    required String productId,
    required String productName,
    required String imageUrl,
    @Default(1) int quantity,
    required double unitAmount,
    @Default('NPR') String unitCurrency,
    required String addedBy,
    required String addedByName,
  }) = _GroupCartItemDto;

  const GroupCartItemDto._();

  factory GroupCartItemDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCartItemDtoFromJson(json);

  GroupCartItem toDomain() => GroupCartItem(
    id: id,
    productId: productId,
    productName: productName,
    imageUrl: imageUrl,
    quantity: quantity,
    unitPrice: Money(amount: unitAmount, currency: unitCurrency),
    addedBy: addedBy,
    addedByName: addedByName,
  );
}

@freezed
abstract class GroupCartDto with _$GroupCartDto {
  const factory GroupCartDto({
    required String id,
    required String name,
    required String inviteCode,
    required String ownerId,
    required String ownerName,
    @Default(<GroupCartParticipantDto>[])
    List<GroupCartParticipantDto> participants,
    @Default(<GroupCartItemDto>[]) List<GroupCartItemDto> items,
    required double subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    required String status,
    required DateTime createdAt,
  }) = _GroupCartDto;

  const GroupCartDto._();

  factory GroupCartDto.fromJson(Map<String, dynamic> json) =>
      _$GroupCartDtoFromJson(json);

  /// Maps the canonical Social Graph CartShare response into the richer
  /// presentation model. Optional display fields are used when the backend
  /// later supplies the denormalized cart/member projection.
  factory GroupCartDto.fromCartShareJson(Map<String, dynamic> json) {
    final rawState = json['status'] ?? json['state'];
    final normalizedState = rawState is num
        ? (rawState == 2 ? 'completed' : 'active')
        : rawState.toString().toLowerCase().contains('closed')
        ? 'completed'
        : rawState.toString().toLowerCase();
    final participantJson =
        json['participants'] as List<dynamic>? ?? const <dynamic>[];
    final itemJson = json['items'] as List<dynamic>? ?? const <dynamic>[];
    final createdAtValue = json['createdAt'] ?? json['createdUtc'];

    return GroupCartDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Group Cart',
      inviteCode: json['inviteCode'] as String? ?? '',
      ownerId: (json['ownerId'] ?? json['ownerAccountId']) as String? ?? '',
      ownerName: json['ownerName'] as String? ?? 'Cart owner',
      participants: participantJson
          .map(
            (item) => GroupCartParticipantDto.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      items: itemJson
          .map(
            (item) => GroupCartItemDto.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0,
      subtotalCurrency: json['subtotalCurrency'] as String? ?? 'NPR',
      status: normalizedState,
      createdAt: DateTime.parse(createdAtValue as String),
    );
  }

  GroupCart toDomain() => GroupCart(
    id: id,
    name: name,
    inviteCode: inviteCode,
    ownerId: ownerId,
    ownerName: ownerName,
    participants: participants.map((p) => p.toDomain()).toList(growable: false),
    items: items.map((i) => i.toDomain()).toList(growable: false),
    subtotal: Money(amount: subtotalAmount, currency: subtotalCurrency),
    status: _parseStatus(status),
    createdAt: createdAt,
  );

  static GroupCartStatus _parseStatus(String s) {
    switch (s) {
      case 'checkout':
        return GroupCartStatus.checkout;
      case 'completed':
        return GroupCartStatus.completed;
      default:
        return GroupCartStatus.active;
    }
  }
}
