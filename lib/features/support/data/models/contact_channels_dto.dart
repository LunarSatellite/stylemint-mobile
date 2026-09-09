import 'package:stylemint_mobile_frontend/features/support/domain/entities/contact_channels.dart';

class ContactChannelsDto {
  const ContactChannelsDto({
    required this.liveChatAvailable,
    required this.liveChatHoursLocal,
    required this.supportEmail,
    required this.directCallPhoneE164,
  });

  factory ContactChannelsDto.fromJson(Map<String, dynamic> json) =>
      ContactChannelsDto(
        liveChatAvailable: json['liveChatAvailable'] as bool? ?? false,
        liveChatHoursLocal: json['liveChatHoursLocal'] as String? ?? '',
        supportEmail: json['supportEmail'] as String? ?? '',
        directCallPhoneE164: json['directCallPhoneE164'] as String? ?? '',
      );

  final bool liveChatAvailable;
  final String liveChatHoursLocal;
  final String supportEmail;
  final String directCallPhoneE164;

  ContactChannels toDomain() => ContactChannels(
    liveChatAvailable: liveChatAvailable,
    liveChatHoursLocal: liveChatHoursLocal,
    supportEmail: supportEmail,
    directCallPhoneE164: directCallPhoneE164,
  );
}
