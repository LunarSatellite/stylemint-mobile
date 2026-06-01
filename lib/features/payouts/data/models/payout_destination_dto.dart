import 'package:stylemint_mobile_frontend/features/payouts/domain/payout_destination_enums.dart';

/// `PayoutDestinationDto` from `/v1/payout-destinations`.
/// The account identifier is returned MASKED (last 4 for banks, `j****@x.com`
/// for emails) — never the raw value.
class PayoutDestinationDto {
  const PayoutDestinationDto({
    required this.id,
    required this.kind,
    required this.label,
    required this.accountIdentifierMasked,
    required this.branchOrIfsc,
    required this.isDefault,
    required this.verified,
  });

  final String id;
  final PayoutDestinationKind kind;
  final String label;
  final String accountIdentifierMasked;
  final String? branchOrIfsc;
  final bool isDefault;
  final bool verified;

  factory PayoutDestinationDto.fromJson(Map<String, dynamic> json) {
    return PayoutDestinationDto(
      id: (json['id'] as String?) ?? '',
      kind: PayoutDestinationKind.fromValue((json['kind'] as num?)?.toInt() ?? 1),
      label: (json['label'] as String?) ?? '',
      accountIdentifierMasked:
          (json['accountIdentifierMasked'] as String?) ?? '',
      branchOrIfsc: json['branchOrIfsc'] as String?,
      isDefault: (json['isDefault'] as bool?) ?? false,
      verified: (json['verified'] as bool?) ?? false,
    );
  }
}
