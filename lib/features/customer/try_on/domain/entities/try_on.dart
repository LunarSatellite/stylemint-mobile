/// Virtual try-on (AR) — the customer side of the TryOn contract v1.
///
/// The phone overlays the vendor's transparent garment image on the live
/// selfie camera (or a still photo); the server owns premium access, the
/// overlay image, the size chart, the buyer's measurements and the size
/// recommendation. Every enum here is an INTEGER on the wire; unknown values
/// fall back rather than throw, so a newer server never breaks the screen.
library;

import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

export 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/size_chart.dart';

enum FitPreference {
  snug(1, 'Snug'),
  regular(2, 'Regular'),
  loose(3, 'Loose');

  const FitPreference(this.wire, this.label);

  final int wire;
  final String label;

  static FitPreference fromWire(int? value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () => FitPreference.regular,
  );
}

enum FitVerdict {
  tooSmall(1, 'Too small'),
  snug(2, 'Snug'),
  good(3, 'Good fit'),
  loose(4, 'Loose'),
  tooLarge(5, 'Too large'),
  unknown(0, 'Unknown');

  const FitVerdict(this.wire, this.label);

  final int wire;
  final String label;

  static FitVerdict fromWire(int? value) =>
      values.firstWhere((v) => v.wire == value, orElse: () => unknown);
}

enum TryOnMode {
  liveCamera(1),
  photo(2);

  const TryOnMode(this.wire);

  final int wire;
}

enum TryOnSubscriptionState {
  pendingPayment(1, 'Awaiting payment'),
  active(2, 'Active'),
  expired(3, 'Expired'),
  cancelled(4, 'Cancelled'),
  revoked(5, 'Revoked'),
  unknown(0, 'Unknown');

  const TryOnSubscriptionState(this.wire, this.label);

  final int wire;
  final String label;

  static TryOnSubscriptionState fromWire(int? value) =>
      values.firstWhere((v) => v.wire == value, orElse: () => unknown);
}

enum TryOnAccessSource {
  freeForEveryone(1, 'Free for everyone'),
  trial(2, 'Free trial'),
  subscription(3, 'Subscription'),
  adminGrant(4, 'Granted by StyleMint'),
  unknown(0, 'Unknown');

  const TryOnAccessSource(this.wire, this.label);

  final int wire;
  final String label;

  static TryOnAccessSource? fromWire(int? value) => value == null
      ? null
      : values.firstWhere((v) => v.wire == value, orElse: () => unknown);
}

/// An admin-defined premium plan, e.g. "Monthly — Rs 199 for 30 days".
class TryOnPlan {
  const TryOnPlan({
    required this.id,
    required this.name,
    required this.priceAmount,
    required this.currency,
    required this.durationDays,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final double priceAmount;
  final String currency;
  final int durationDays;

  Money get price => Money(amount: priceAmount, currency: currency);
}

/// `GET /v1/try-on/access` — what the signed-in buyer may do right now, and
/// everything the paywall needs in one round-trip.
class TryOnAccess {
  const TryOnAccess({
    required this.serviceEnabled,
    required this.hasAccess,
    required this.trialAvailable,
    required this.freeTrialDays,
    required this.disclaimer,
    required this.plans,
    this.source,
    this.expiresUtc,
  });

  final bool serviceEnabled;
  final bool hasAccess;
  final TryOnAccessSource? source;
  final DateTime? expiresUtc;
  final bool trialAvailable;
  final int freeTrialDays;
  final String disclaimer;
  final List<TryOnPlan> plans;

  /// Whether the entry point should be offered at all. A disabled service
  /// hides "Try it on" rather than opening a paywall nobody can pass.
  bool get canOffer => serviceEnabled;
}

class MyTryOnSubscription {
  const MyTryOnSubscription({
    required this.id,
    required this.source,
    required this.state,
    required this.priceAmount,
    required this.currency,
    required this.createdUtc,
    this.planId,
    this.planName,
    this.startsUtc,
    this.expiresUtc,
  });

  final String id;
  final String? planId;
  final String? planName;
  final TryOnAccessSource source;
  final TryOnSubscriptionState state;
  final DateTime? startsUtc;
  final DateTime? expiresUtc;
  final double priceAmount;
  final String currency;
  final DateTime? createdUtc;

  Money get price => Money(amount: priceAmount, currency: currency);
}

/// The payment the server started for a subscription. Only the hand-off URL
/// matters to the app: the provider's page completes it, then the app calls
/// confirm.
class TryOnPaymentStart {
  const TryOnPaymentStart({
    required this.subscription,
    this.redirectUrl,
    this.paymentIntentId,
  });

  final MyTryOnSubscription subscription;
  final String? redirectUrl;
  final String? paymentIntentId;
}

/// The payment rails a subscription can be paid with — checkout's integer
/// `PaymentMethod` (Cash on Delivery has nothing to deliver, so it is absent).
enum TryOnPaymentRail {
  card(1, 'Visa / Mastercard'),
  paypal(2, 'PayPal'),
  eSewa(3, 'eSewa');

  const TryOnPaymentRail(this.wire, this.label);

  final int wire;
  final String label;
}

/// `GET /v1/try-on/products/{id}` — the overlay and its chart.
class TryOnProduct {
  const TryOnProduct({
    required this.productId,
    required this.name,
    required this.overlayImageUrl,
    required this.overlayWidth,
    required this.overlayHeight,
    required this.garmentType,
    required this.disclaimer,
    this.sizeChart,
  });

  final String productId;
  final String name;
  final String overlayImageUrl;
  final int overlayWidth;
  final int overlayHeight;
  final GarmentType garmentType;
  final SizeChart? sizeChart;
  final String disclaimer;

  /// Height / width of the overlay image; 1 when the server sent no size.
  double get overlayAspect =>
      overlayWidth > 0 && overlayHeight > 0 ? overlayHeight / overlayWidth : 1;
}

/// The buyer's body, always in centimetres / kilograms on the wire.
class BodyMeasurements {
  const BodyMeasurements({
    required this.heightCm,
    this.weightKg,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.shoulderCm,
    this.inseamCm,
    this.footLengthCm,
    this.fitPreference = FitPreference.regular,
    this.updatedUtc,
  });

  final double heightCm;
  final double? weightKg;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? shoulderCm;
  final double? inseamCm;
  final double? footLengthCm;
  final FitPreference fitPreference;
  final DateTime? updatedUtc;
}

class SizeFit {
  const SizeFit({
    required this.sizeLabel,
    required this.verdict,
    this.notes = const <String>[],
  });

  final String sizeLabel;
  final FitVerdict verdict;
  final List<String> notes;
}

/// `GET /v1/try-on/products/{id}/fit` — the "reality fit".
class FitRecommendation {
  const FitRecommendation({
    required this.productId,
    required this.confidence,
    required this.perSize,
    required this.missingMeasurements,
    required this.basedOn,
    this.recommendedSize,
  });

  final String productId;
  final String? recommendedSize;
  final double confidence;
  final List<SizeFit> perSize;
  final List<String> missingMeasurements;
  final String basedOn;

  SizeFit? fitFor(String sizeLabel) {
    final needle = sizeLabel.trim().toLowerCase();
    for (final fit in perSize) {
      if (fit.sizeLabel.trim().toLowerCase() == needle) return fit;
    }
    return null;
  }
}
