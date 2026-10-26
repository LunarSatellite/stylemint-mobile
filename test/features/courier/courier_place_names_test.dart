import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_place_names.dart';

void main() {
  test('a named place reads as its name', () {
    const place = DeliveryPlace(
      latitude: 27.715,
      longitude: 85.312,
      label: 'Thamel Marg, Kathmandu',
    );
    expect(pickupName(place), 'Thamel Marg, Kathmandu');
    expect(dropoffName(place), 'Thamel Marg, Kathmandu');
  });

  test('no place, or one without a name, reads as plain words', () {
    const unnamed = DeliveryPlace(latitude: 27.715, longitude: 85.312);
    expect(pickupName(null), 'Pickup point');
    expect(dropoffName(null), 'Drop-off point');
    expect(pickupName(unnamed), 'Pickup point');
    expect(dropoffName(unnamed), 'Drop-off point');
  });
}
