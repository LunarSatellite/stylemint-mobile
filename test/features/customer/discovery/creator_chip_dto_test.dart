import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/creator_chip_dto.dart';

void main() {
  test('uses the explicit accountId from the creator-suggestion contract', () {
    final dto = CreatorChipDto.fromJson(const {
      'accountId': 'account-1',
      'creatorProfileId': 'legacy-profile-1',
      'handle': 'minty',
    });

    expect(dto.accountId, 'account-1');
  });

  test('keeps consuming the legacy account-id field during API rollout', () {
    final dto = CreatorChipDto.fromJson(const {
      'creatorProfileId': 'account-legacy',
      'handle': 'minty',
    });

    expect(dto.accountId, 'account-legacy');
  });
}
