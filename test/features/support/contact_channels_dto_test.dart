import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/support/data/models/contact_channels_dto.dart';

void main() {
  test(
    'maps the Support contact-channels contract without fallback details',
    () {
      final channels = ContactChannelsDto.fromJson(const {
        'liveChatAvailable': true,
        'liveChatHoursLocal': '9 AM - 9 PM NPT',
        'supportEmail': 'help@stylemint.app',
        'directCallPhoneE164': '+977-0000000',
      }).toDomain();

      expect(channels.liveChatAvailable, isTrue);
      expect(channels.liveChatHoursLocal, '9 AM - 9 PM NPT');
      expect(channels.supportEmail, 'help@stylemint.app');
      expect(channels.directCallPhoneE164, '+977-0000000');
    },
  );
}
