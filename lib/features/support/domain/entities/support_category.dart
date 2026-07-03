// deliveryAndCouriers(8) is intentionally excluded — backend requires
// CustomerCourierContext which is not yet documented in Swagger.
enum SupportTicketCategory {
  general(1, 'General Inquiry'),
  payment(2, 'Payment Issue'),
  orderIssue(3, 'Order Issue'),
  returnRefund(4, 'Returns & Refunds'),
  productQuality(5, 'Product Quality Issue'),
  accountSecurity(6, 'Account & Security'),
  shipping(7, 'Shipping Address Issue');

  const SupportTicketCategory(this.value, this.label);
  final int value;
  final String label;
}
