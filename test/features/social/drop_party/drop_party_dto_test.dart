import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/data/models/drop_party_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';

void main() {
  test('maps the live Drop Party response contract', () {
    final party = DropPartyDto.fromJson({
      'id': 'party-1',
      'creatorProfileId': 'creator-1',
      'vendorProfileId': 'vendor-1',
      'reelId': 'reel-1',
      'title': 'Friday launch',
      'description': 'Join the live launch.',
      'startsUtc': '2026-09-08T12:00:00Z',
      'duration': '01:30:00',
      'joinCode': 'A1B2C3',
      'state': 2,
      'attendeeCount': 45,
      'reelIsOrphaned': false,
      'wentLiveUtc': '2026-09-08T12:00:00Z',
      'endedUtc': null,
      'cancellationReason': null,
    }).toDomain();

    expect(party.id, 'party-1');
    expect(party.status, DropPartyStatus.live);
    expect(party.duration, const Duration(minutes: 90));
    expect(party.attendeeCount, 45);
    expect(party.joinCode, 'A1B2C3');
  });
}
