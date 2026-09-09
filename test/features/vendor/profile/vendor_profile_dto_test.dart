import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/data/models/vendor_profile_dto.dart';

void main() {
  test(
    'maps the self-only vendor profile fields used by the profile screen',
    () {
      final profile = VendorProfileDto.fromJson({
        'id': 'profile-1',
        'accountId': 'account-1',
        'businessName': 'Mint Goods',
        'businessType': 4,
        'commissionRangeMin': 0.12,
        'commissionRangeMax': 0.25,
        'status': 3,
        'logoUrl': 'https://cdn.example.test/logo.png',
        'description': 'Products for everyday life.',
        'websiteUrl': 'https://mint.example.test',
      }).toDomain();

      expect(profile.businessName, 'Mint Goods');
      expect(profile.commissionRangeMin, 0.12);
      expect(profile.commissionRangeMax, 0.25);
      expect(profile.status, 3);
      expect(profile.websiteUrl, 'https://mint.example.test');
    },
  );
}
