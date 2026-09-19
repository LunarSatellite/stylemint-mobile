import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

void main() {
  test('loads server choices and persists pickup selection', () async {
    final repository = _FakeCheckoutRepository();
    final notifier = CheckoutNotifier(repository);
    await _waitForLoad(notifier);

    final pickup = repository.delivery.choices.last;
    await notifier.selectDeliveryChoice(pickup);

    expect(repository.selected, same(pickup));
    final summary = notifier.state.maybeWhen(
      loadSuccess: (value, _) => value,
      orElse: () => throw StateError('Checkout did not load'),
    );
    expect(
      summary.selectedDeliveryChoice?.kind,
      DeliveryChoiceKind.pickupFromSeller,
    );

    // This seller has registered no counter, and switching to collection must
    // not invent one. The order goes out recording no location, exactly as it
    // did before counters could be chosen at all.
    expect(summary.pickupLocations, isEmpty);
    expect(summary.selectedPickupLocation, isNull);
    expect(repository.selectedPickupLocation, isNull);
  });

  test(
    'persists reusable delivery preferences and refreshes recommendation',
    () async {
      final repository = _FakeCheckoutRepository();
      final notifier = CheckoutNotifier(repository);
      await _waitForLoad(notifier);

      const preference = DeliveryPreference(
        preferFewerDeliveries: true,
        preferPickup: true,
        maximumExtraWaitDays: 5,
      );
      await notifier.updateDeliveryPreference(preference);

      expect(repository.savedPreference, preference);
      final summary = notifier.state.maybeWhen(
        loadSuccess: (value, _) => value,
        orElse: () => throw StateError('Checkout did not load'),
      );
      expect(summary.deliveryPreference.preferPickup, isTrue);
      expect(summary.deliveryPreference.maximumExtraWaitDays, 5);
    },
  );
  test('pickup placement does not require a shipping address', () async {
    final repository = _FakeCheckoutRepository();
    final notifier = CheckoutNotifier(repository);
    await _waitForLoad(notifier);

    await notifier.placeOrder(
      addressId: null,
      paymentMethod: PaymentMethodType.cod,
      idempotencyKey: 'test-place',
    );

    expect(repository.placedAddressId, isNull);
    expect(repository.placedPaymentMethod, PaymentMethodType.cod);
  });
}

Future<void> _waitForLoad(CheckoutNotifier notifier) async {
  for (var i = 0; i < 20; i++) {
    if (notifier.state.maybeWhen(
      loadSuccess: (_, __) => true,
      orElse: () => false,
    )) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  throw StateError('Checkout load timed out');
}

class _FakeCheckoutRepository implements CheckoutRepository {
  var delivery = const DeliveryChoices(
    emissionsNote: 'Measured honestly.',
    choices: [
      DeliveryChoice(
        kind: DeliveryChoiceKind.homeDelivery,
        title: 'Home delivery',
        detail: 'Arrives in one delivery.',
        deliveries: 1,
        readyInDays: 2,
        selected: true,
      ),
      DeliveryChoice(
        kind: DeliveryChoiceKind.pickupFromSeller,
        title: 'Pick up from Atelier',
        detail: 'Ready to collect in one day.',
        deliveries: 0,
        readyInDays: 1,
        sellerAccountId: 'seller-1',
        sellerName: 'Atelier',
        selected: false,
      ),
    ],
  );

  DeliveryChoice? selected;
  DeliveryPreference? savedPreference;
  String? placedAddressId;
  PaymentMethodType? placedPaymentMethod;

  @override
  Future<Either<NetworkExceptions, CheckoutSummary>>
  getCheckoutSummary() async => right(
    const CheckoutSummary(
      shippingAddress: ShippingAddress.empty(),
      paymentMethod: PaymentMethod.empty(),
      items: [],
      subtotal: Money(amount: 0, currency: 'NPR'),
      shipping: Money(amount: 0, currency: 'NPR'),
      tax: Money(amount: 0, currency: 'NPR'),
      discount: Money(amount: 0, currency: 'NPR'),
      total: Money(amount: 0, currency: 'NPR'),
    ),
  );

  @override
  Future<Either<NetworkExceptions, DeliveryChoices>>
  getDeliveryChoices() async => right(delivery);

  @override
  Future<Either<NetworkExceptions, List<ShippingAddress>>>
  getShippingAddresses() async => right([]);

  @override
  Future<Either<NetworkExceptions, List<PaymentMethod>>>
  getPaymentMethods() async => right([]);

  @override
  Future<Either<NetworkExceptions, Unit>> selectDeliveryChoice(
    DeliveryChoice choice,
  ) async {
    selected = choice;
    return right(unit);
  }

  /// Recorded, not acted on — this fake exists to prove the delivery-choice
  /// path still behaves exactly as it did, and it must stay null here.
  ({String sellerId, String locationId})? selectedPickupLocation;

  @override
  Future<Either<NetworkExceptions, Unit>> selectPickupLocation({
    required String sellerId,
    required String locationId,
  }) async {
    selectedPickupLocation = (sellerId: sellerId, locationId: locationId);
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, DeliveryPreference>>
  updateDeliveryPreference(DeliveryPreference preference) async {
    savedPreference = preference;
    delivery = DeliveryChoices(
      choices: delivery.choices,
      emissionsNote: delivery.emissionsNote,
      pickupNote: delivery.pickupNote,
      preferences: preference,
      consolidation: delivery.consolidation,
    );
    return right(preference);
  }

  @override
  Future<Either<NetworkExceptions, PlaceOrderResult>> placeOrder({
    required String? addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async {
    placedAddressId = addressId;
    placedPaymentMethod = paymentMethod;
    return right(
      const PlaceOrderResult(
        orderNumber: 'NK2026-00001',
        requiresPaymentAction: false,
      ),
    );
  }
}
