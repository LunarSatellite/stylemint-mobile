import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';

/// What a rider reads for each end of a leg: the place's name, or a plain
/// word when the server has none (a hand-off point between riders, or an
/// older parcel) — never the routing geohash, which reads as noise
/// ("tuutmwy → tuutt2s").
const pickupFallbackName = 'Pickup point';
const dropoffFallbackName = 'Drop-off point';

String pickupName(DeliveryPlace? place) => place?.label ?? pickupFallbackName;

String dropoffName(DeliveryPlace? place) => place?.label ?? dropoffFallbackName;
