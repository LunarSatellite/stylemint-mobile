import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/domain/entities/payment_method.dart';

part 'payment_method_dto.freezed.dart';
part 'payment_method_dto.g.dart';

@freezed
abstract class PaymentMethodDto with _$PaymentMethodDto {
  const factory PaymentMethodDto({
    required String id,
    @Default('card') String type,
    @Default('') String label,
    String? lastFour,
    String? expiryDate,
    @Default(false) bool isDefault,
  }) = _PaymentMethodDto;

  const PaymentMethodDto._();

  factory PaymentMethodDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodDtoFromJson(json);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'label': label,
    'lastFour': lastFour,
    'expiryDate': expiryDate,
    'isDefault': isDefault,
  };

  PaymentMethod toDomain() {
    final paymentType = switch (type) {
      'card' => PaymentType.card,
      'eSewa' => PaymentType.eSewa,
      'cod' => PaymentType.cod,
      _ => PaymentType.card,
    };
    return PaymentMethod(
      id: id,
      type: paymentType,
      label: label,
      lastFour: lastFour,
      expiryDate: expiryDate,
      isDefault: isDefault,
    );
  }
}
