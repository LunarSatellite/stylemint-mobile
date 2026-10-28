/// Reads the server's `OrderState` and `PaymentMethod` codes together, for
/// the one question the buyer's order screens must answer honestly: is this
/// order still waiting for its online payment?
///
/// The server creates an online-payment order at Place Order (state 1,
/// Placed) and only moves it to Paid (2) once the payment clears; sellers
/// never see it before then, and a failed or abandoned payment cancels it
/// (5). Cash on Delivery orders also start at Placed, but nothing is owed up
/// front, so they are simply placed.
abstract final class OrderPaymentState {
  /// `OrderState.Placed`.
  static const placed = 1;

  /// `PaymentMethod.CashOnDelivery`. Every other known method (card, PayPal,
  /// eSewa, and any provider added later, such as connectIPS) is paid online
  /// before the order is placed.
  static const cashOnDelivery = 4;

  /// True when [paymentMethod] is paid online rather than at the door.
  static bool isOnline(int paymentMethod) =>
      paymentMethod > 0 && paymentMethod != cashOnDelivery;

  /// True for an online-payment order the server still holds at Placed.
  static bool awaitsPayment({required int state, required int paymentMethod}) =>
      state == placed && isOnline(paymentMethod);
}
