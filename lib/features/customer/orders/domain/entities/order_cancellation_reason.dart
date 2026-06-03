/// Customer cancel-reason taxonomy. Wire value matches the backend
/// `OrderCancellationReason` enum. `other` requires a note (1..500 chars).
enum OrderCancellationReason {
  orderedByMistake(1, 'Ordered by mistake'),
  foundBetterPrice(2, 'Found better price'),
  changedMyMind(3, 'Changed my mind'),
  deliveryTooLong(4, 'Delivery too long'),
  needDifferentSizeOrColor(5, 'Need different size / color'),
  other(6, 'Other reason');

  const OrderCancellationReason(this.value, this.label);

  final int value;
  final String label;

  bool get requiresNote => this == OrderCancellationReason.other;
}
